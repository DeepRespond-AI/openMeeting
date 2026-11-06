// Generate per-deployment mobile assets from a shared, URL-free template.
// Usage: dart run tool/init_app_config.dart --server-url https://meeting.example.com
import 'dart:convert';
import 'dart:io';

const configEnvironments = ['dev', 'test', 'prod'];

typedef ConfigInitializationResult = ({List<String> generated, List<String> skipped});

String _serverUrl(String? value, Iterable<String> environments) {
  final uri = value == null ? null : Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    throw const FormatException('首次初始化需要 --server-url，填写不含凭据、查询参数和片段的 HTTP(S) 网关地址。');
  }
  if (uri.scheme != 'https' && environments.any((environment) => environment != 'dev')) {
    throw const FormatException('test/prod 必须使用 HTTPS 网关；HTTP 仅支持 --env dev。');
  }
  return uri.toString().replaceFirst(RegExp(r'/+$'), '');
}

ConfigInitializationResult initializeAppConfig({
  required Directory mobileDirectory,
  required File templateFile,
  List<String> environments = configEnvironments,
  String? serverUrl,
  void Function(String)? log,
}) {
  final void Function(String) report = log ?? (message) => stdout.writeln(message);
  if (environments.isEmpty || environments.any((env) => !configEnvironments.contains(env))) {
    throw const FormatException('--env 只支持 dev、test、prod 或 all。');
  }
  final directory = Directory.fromUri(mobileDirectory.absolute.uri.resolve('assets/config/'));
  final pending = <String>[];
  final skipped = <String>[];
  for (final env in environments.toSet()) {
    final file = File.fromUri(directory.uri.resolve('app_config.$env.json'));
    final type = FileSystemEntity.typeSync(file.path, followLinks: false);
    if (type == FileSystemEntityType.file) {
      skipped.add(env);
    } else if (type != FileSystemEntityType.notFound) {
      throw StateError('${file.path} 不是普通配置文件，拒绝覆盖。');
    } else {
      pending.add(env);
    }
  }
  if (pending.isEmpty) {
    report('已有本地配置，保留原文件：${skipped.join(', ')}。');
    return (generated: [], skipped: skipped);
  }
  final server = _serverUrl(serverUrl, pending);
  final template = templateFile.readAsStringSync();
  final writes = <({File file, String content})>[];
  for (final env in pending) {
    // Decode separately so environment-specific changes cannot affect other files.
    final config = jsonDecode(template) as Map<String, dynamic>;
    config['env'] = env;
    config['defaultServerUrl'] = server;
    final features = config['features'] as Map<String, dynamic>;
    features['showDevCode'] = env == 'dev';
    if (env != 'prod') (config['update'] as Map<String, dynamic>)['checkIntervalMin'] = 5;
    writes.add((
      file: File.fromUri(directory.uri.resolve('app_config.$env.json')),
      content: '${const JsonEncoder.withIndent('  ').convert(config)}\n',
    ));
  }
  directory.createSync(recursive: true);
  final created = <File>[];
  try {
    for (final entry in writes) {
      entry.file.createSync(exclusive: true);
      created.add(entry.file);
      entry.file.writeAsStringSync(entry.content, flush: true);
    }
  } catch (_) {
    for (final file in created.reversed) {
      file.deleteSync();
    }
    rethrow;
  }
  report('已初始化移动端配置：${pending.join(', ')}。');
  if (skipped.isNotEmpty) report('已有配置，未修改：${skipped.join(', ')}。');
  report('输出：assets/config/app_config.<环境>.json，整个 assets/config/ 不提交 Git。');
  report('后续修改网关或其他参数，请编辑相应本地 JSON；修改后重新构建客户端。');
  return (generated: pending, skipped: skipped);
}

void main(List<String> arguments) {
  try {
    var environments = configEnvironments;
    String? serverUrl;
    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (argument == '--help' || argument == '-h') {
        stdout.writeln(
          '用法：dart run tool/init_app_config.dart [--env dev|test|prod|all] --server-url <网关地址>',
        );
        stdout.writeln('默认生成三个环境。test/prod 要求 HTTPS；已有本地文件会保留，不会覆盖。');
        return;
      }
      if (!['--env', '--server-url'].contains(argument) ||
          index + 1 >= arguments.length ||
          arguments[index + 1].startsWith('--')) {
        throw FormatException('无效参数：$argument。使用 --help 查看用法。');
      }
      final value = arguments[++index];
      if (argument == '--env') {
        environments = value == 'all' ? configEnvironments : [value];
      } else {
        serverUrl = value;
      }
    }
    final toolDirectory = File.fromUri(Platform.script).parent;
    initializeAppConfig(
      mobileDirectory: toolDirectory.parent,
      templateFile: File.fromUri(toolDirectory.uri.resolve('templates/app_config.json')),
      environments: environments,
      serverUrl: serverUrl,
    );
  } on Object catch (error) {
    stderr.writeln('移动端配置初始化失败：$error');
    exitCode = 1;
  }
}
