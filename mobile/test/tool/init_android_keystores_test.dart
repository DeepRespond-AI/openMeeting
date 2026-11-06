import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/init_android_keystores.dart';

Directory workspace() {
  final temporary = Directory.systemTemp.createTempSync('openmeeting-keystores-test-');
  addTearDown(() {
    expect(temporary.parent.absolute.uri, Directory.systemTemp.absolute.uri);
    expect(
      temporary.uri.pathSegments.where((part) => part.isNotEmpty).last,
      startsWith('openmeeting-keystores-test-'),
    );
    temporary.deleteSync(recursive: true);
  });
  return Directory('${temporary.path}/mobile with spaces # local')..createSync();
}

Map<String, String> snapshot(Directory directory) => {
  for (final file in directory.listSync(recursive: true).whereType<File>())
    file.path: base64Encode(file.readAsBytesSync()),
};

void expectUnchanged(Directory directory, Map<String, String> before) {
  final after = snapshot(directory);
  expect(after.keys.toSet(), before.keys.toSet());
  for (final entry in before.entries) {
    // Compare without exposing private file bytes in test failure output.
    expect(after[entry.key] == entry.value, isTrue, reason: 'Existing file changed: ${entry.key}');
  }
}

void main() {
  test('generates independent usable keys and preserves existing configurations', () {
    final mobile = workspace();
    final keytool = resolveKeytool();
    final logs = <String>[];
    final result = initializeAndroidKeystores(
      mobileDirectory: mobile,
      keytoolPath: keytool,
      log: logs.add,
    );
    expect(result.generated, ['dev', 'test', 'prod']);
    final passwords = <String>{};
    for (final environment in result.generated) {
      final directory = Directory('${mobile.path}/android/keystores/$environment');
      final properties = File('${directory.path}/key.properties');
      final values = <String, String>{};
      for (final line in properties.readAsLinesSync()) {
        final separator = line.indexOf('=');
        values[line.substring(0, separator)] = line.substring(separator + 1);
      }
      final password = values['storePassword']!;
      expect(password.length >= 40, isTrue);
      expect(values['keyPassword'] == password, isTrue);
      expect(logs.join('\n').contains(password), isFalse);
      expect(values['keyAlias'], 'meeting-$environment');
      expect(values['storeFile'], '../keystores/$environment/meeting-$environment.jks');
      if (!Platform.isWindows) expect(properties.statSync().mode & 0x1ff, 0x180);
      passwords.add(password);
    }
    expect(passwords.length, 3);

    final java = keytool.contains('/') || keytool.contains('\\')
        ? File.fromUri(
            File(keytool).absolute.parent.uri.resolve(Platform.isWindows ? 'java.exe' : 'java'),
          ).path
        : (Platform.isWindows ? 'java.exe' : 'java');
    final fixture = File('test/tool/fixtures/VerifyKeystore.java').absolute;
    final verified = Process.runSync(java, [fixture.path, mobile.path, ...result.generated]);
    expect(verified.exitCode, 0, reason: '${verified.stderr}');
    expect(verified.stdout.toString().trim(), 'verified=3');

    final before = snapshot(mobile);
    final repeated = initializeAndroidKeystores(
      mobileDirectory: mobile,
      keytoolPath: 'not-needed-for-existing-configs',
      log: logs.add,
    );
    expect(repeated.generated, isEmpty);
    expect(repeated.skipped, ['dev', 'test', 'prod']);
    expectUnchanged(mobile, before);
    expect(
      Directory('${mobile.path}/android/keystores').listSync().any(
        (entry) =>
            entry.uri.pathSegments.where((part) => part.isNotEmpty).last.startsWith('.init-'),
      ),
      isFalse,
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('partial existing credentials block all generation', () {
    final mobile = workspace();
    final directory = Directory('${mobile.path}/android/keystores/prod')
      ..createSync(recursive: true);
    File('${directory.path}/key.properties').writeAsStringSync('existing-do-not-overwrite\n');
    final before = snapshot(mobile);
    expect(() => initializeAndroidKeystores(mobileDirectory: mobile), throwsStateError);
    expectUnchanged(mobile, before);
    expect(Directory('${mobile.path}/android/keystores/dev').existsSync(), isFalse);
  });

  test('missing keytool fails before creating output directories', () {
    final mobile = workspace();
    expect(
      () => initializeAndroidKeystores(
        mobileDirectory: mobile,
        keytoolPath: '${mobile.path}/missing-jdk/bin/keytool',
      ),
      throwsStateError,
    );
    expect(mobile.listSync(), isEmpty);
  });

  test('keytool failure cleans staging and publishes no credentials', () {
    final mobile = workspace();
    expect(
      () => initializeAndroidKeystores(
        mobileDirectory: mobile,
        environments: ['prod'],
        distinguishedName: 'not-a-distinguished-name',
        log: (_) {},
      ),
      throwsStateError,
    );
    expect(Directory('${mobile.path}/android/keystores').listSync(), isEmpty);
  });
}
