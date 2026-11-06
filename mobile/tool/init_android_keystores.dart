// Generate local Android signing credentials without changing existing keys.
// Usage from mobile/: dart run tool/init_android_keystores.dart [--env prod]
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const signingEnvironments = ['dev', 'test', 'prod'];
const _passwordVariable = 'OPENMEETING_KEYSTORE_INIT_PASSWORD';

typedef InitializationResult = ({List<String> generated, List<String> skipped});

/// Locate keytool without requiring a separately installed tool or package.
String resolveKeytool({String? explicitPath}) {
  final executable = Platform.isWindows ? 'keytool.exe' : 'keytool';
  final candidates = <String>[];
  if (explicitPath != null) {
    candidates.add(explicitPath);
  } else {
    for (final variable in ['JAVA_HOME', 'STUDIO_JDK']) {
      final home = Platform.environment[variable];
      if (home != null && home.isNotEmpty) {
        candidates.add(File.fromUri(Directory(home).absolute.uri.resolve('bin/$executable')).path);
      }
    }
    candidates.add(executable);
    if (Platform.isWindows) {
      final programFiles = Platform.environment['ProgramFiles'];
      if (programFiles != null) {
        candidates.add('$programFiles/Android/Android Studio/jbr/bin/$executable');
      }
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null) {
        candidates.add('$localAppData/Programs/Android Studio/jbr/bin/$executable');
      }
    } else if (Platform.isMacOS) {
      candidates.add('/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool');
    } else {
      candidates.addAll([
        '/opt/android-studio/jbr/bin/keytool',
        '/usr/local/android-studio/jbr/bin/keytool',
      ]);
    }
  }
  for (final candidate in candidates) {
    try {
      if (Process.runSync(
            candidate,
            ['-help'],
            stdoutEncoding: null,
            stderrEncoding: null,
          ).exitCode ==
          0) {
        return candidate;
      }
    } on ProcessException {
      // Try the next JDK installation without printing process arguments.
    }
  }
  throw StateError('找不到可用的 keytool。请设置 JAVA_HOME，或用 --keytool 指定 JDK 的 keytool 路径。');
}

void _permissions(String file, String mode) {
  if (!Platform.isWindows && Process.runSync('chmod', [mode, file]).exitCode != 0) {
    throw StateError('无法设置本地签名文件的访问权限。');
  }
}

void _keytool(String executable, List<String> arguments, String password) {
  try {
    final result = Process.runSync(
      executable,
      arguments,
      environment: {_passwordVariable: password},
      // keytool output is captured and never echoed with signing credentials.
      // Windows JDKs may emit localized output in a legacy console encoding.
      // These streams are not displayed or parsed, so keep them as bytes.
      stdoutEncoding: null,
      stderrEncoding: null,
    );
    if (result.exitCode == 0) return;
  } on ProcessException {
    throw StateError('无法运行 keytool，请检查 JDK 路径和执行权限。');
  }
  throw StateError('keytool 操作失败，请检查证书主体格式、JDK 和文件权限；现有签名文件未被覆盖。');
}

InitializationResult initializeAndroidKeystores({
  required Directory mobileDirectory,
  List<String> environments = signingEnvironments,
  String? keytoolPath,
  String? distinguishedName,
  void Function(String)? log,
}) {
  final void Function(String) report = log ?? (message) => stdout.writeln(message);
  if (environments.isEmpty || environments.any((env) => !signingEnvironments.contains(env))) {
    throw const FormatException('--env 只支持 dev、test、prod 或 all。');
  }
  final selected = environments.toSet().toList();
  final root = Directory.fromUri(mobileDirectory.absolute.uri.resolve('android/keystores/'));
  final pending = <String>[];
  final skipped = <String>[];
  for (final env in selected) {
    final directory = Directory.fromUri(root.uri.resolve('$env/'));
    final key = File.fromUri(directory.uri.resolve('meeting-$env.jks'));
    final properties = File.fromUri(directory.uri.resolve('key.properties'));
    final keyExists =
        FileSystemEntity.typeSync(key.path, followLinks: false) != FileSystemEntityType.notFound;
    final propertiesExist =
        FileSystemEntity.typeSync(properties.path, followLinks: false) !=
        FileSystemEntityType.notFound;
    if (keyExists && propertiesExist && key.existsSync() && properties.existsSync()) {
      skipped.add(env);
    } else if (keyExists || propertiesExist) {
      throw StateError('$env 已有部分签名文件，拒绝覆盖或混用。请恢复完整备份，或将旧文件移到其他安全位置。');
    } else {
      pending.add(env);
    }
  }
  if (pending.isEmpty) {
    report('已有完整签名配置，保留原文件：${skipped.join(', ')}。');
    return (generated: [], skipped: skipped);
  }
  if (distinguishedName != null && distinguishedName.trim().isEmpty) {
    throw const FormatException('--dname 不能为空。');
  }
  final keytool = resolveKeytool(explicitPath: keytoolPath);
  root.createSync(recursive: true);
  final staging = root.createTempSync('.init-');
  final random = Random.secure();
  final writes = <({File file, List<int> content})>[];
  final created = <File>[];
  try {
    _permissions(staging.path, '700');
    // Generate and validate all environments before publishing their files.
    for (final env in pending) {
      final password = base64Url
          .encode(List.generate(32, (_) => random.nextInt(256)))
          .replaceAll('=', '');
      final temporaryKey = File.fromUri(staging.uri.resolve('meeting-$env.jks'));
      final alias = 'meeting-$env';
      _keytool(keytool, [
        '-genkeypair',
        '-noprompt',
        '-storetype',
        'PKCS12',
        '-keystore',
        temporaryKey.path,
        '-alias',
        alias,
        '-keyalg',
        'RSA',
        '-keysize',
        '4096',
        '-sigalg',
        'SHA256withRSA',
        '-validity',
        '10000',
        '-dname',
        distinguishedName ?? 'CN=DR Meeting ${env.toUpperCase()}, OU=Android',
        '-storepass:env',
        _passwordVariable,
        '-keypass:env',
        _passwordVariable,
      ], password);
      _keytool(keytool, [
        '-list',
        '-storetype',
        'PKCS12',
        '-keystore',
        temporaryKey.path,
        '-alias',
        alias,
        '-storepass:env',
        _passwordVariable,
      ], password);
      final directory = Directory.fromUri(root.uri.resolve('$env/'));
      writes.addAll([
        (
          file: File.fromUri(directory.uri.resolve('meeting-$env.jks')),
          content: temporaryKey.readAsBytesSync(),
        ),
        (
          file: File.fromUri(directory.uri.resolve('key.properties')),
          content: utf8.encode(
            'storePassword=$password\nkeyPassword=$password\nkeyAlias=$alias\n'
            'storeFile=../keystores/$env/meeting-$env.jks\n',
          ),
        ),
      ]);
    }
    for (final entry in writes) {
      entry.file.parent.createSync(recursive: true);
      _permissions(entry.file.parent.path, '700');
      entry.file.createSync(exclusive: true);
      created.add(entry.file);
      _permissions(entry.file.path, '600');
      entry.file.writeAsBytesSync(entry.content, flush: true);
    }
  } catch (_) {
    for (final file in created.reversed) {
      file.deleteSync();
    }
    rethrow;
  } finally {
    if (staging.parent.absolute.uri != root.absolute.uri ||
        !staging.uri.pathSegments.where((part) => part.isNotEmpty).last.startsWith('.init-')) {
      throw StateError('签名临时目录边界校验失败。');
    }
    staging.deleteSync(recursive: true);
  }
  report('已初始化：${pending.join(', ')}。每个环境使用独立 RSA 4096 密钥和随机密码。');
  if (skipped.isNotEmpty) report('已有完整配置，未修改：${skipped.join(', ')}。');
  report('输出：android/keystores/<环境>/meeting-<环境>.jks 和 key.properties，均不提交 Git。');
  report('请安全备份签名文件及密码；终端不会输出密码或私钥。');
  return (generated: pending, skipped: skipped);
}

void main(List<String> arguments) {
  try {
    var environments = signingEnvironments;
    String? keytoolPath;
    String? distinguishedName;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') {
        stdout.writeln('用法：dart run tool/init_android_keystores.dart [--env dev|test|prod|all]');
        stdout.writeln('可选：--keytool <JDK keytool 路径>、--dname <证书主体，例如 CN=My App, O=My Company>');
        stdout.writeln('默认初始化全部环境；已有完整配置会保留，部分配置会拒绝覆盖。');
        return;
      }
      if (!['--env', '--keytool', '--dname'].contains(argument) ||
          index + 1 >= arguments.length ||
          arguments[index + 1].startsWith('--')) {
        throw FormatException('无效参数：$argument。使用 --help 查看用法。');
      }
      final value = arguments[++index];
      switch (argument) {
        case '--env':
          environments = value == 'all' ? signingEnvironments : [value];
        case '--keytool':
          keytoolPath = value;
        case '--dname':
          distinguishedName = value;
      }
    }
    initializeAndroidKeystores(
      mobileDirectory: File.fromUri(Platform.script).parent.parent,
      environments: environments,
      keytoolPath: keytoolPath,
      distinguishedName: distinguishedName,
    );
  } on Object catch (error) {
    stderr.writeln('Android 签名初始化失败：$error');
    exitCode = 1;
  }
}
