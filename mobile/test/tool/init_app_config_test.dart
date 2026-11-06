import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_config_provider.dart';

import '../../tool/init_app_config.dart';

Directory workspace() {
  final directory = Directory.systemTemp.createTempSync('openmeeting-app-config-test-');
  addTearDown(() {
    expect(directory.parent.absolute.uri, Directory.systemTemp.absolute.uri);
    expect(
      directory.uri.pathSegments.where((part) => part.isNotEmpty).last,
      startsWith('openmeeting-app-config-test-'),
    );
    directory.deleteSync(recursive: true);
  });
  return directory;
}

class LocalConfigAssets extends CachingAssetBundle {
  LocalConfigAssets(this.directory);

  final Directory directory;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File.fromUri(directory.uri.resolve(key)).readAsBytesSync());
}

Set<String> keyPaths(Object? value, [String prefix = '']) => value is Map<String, dynamic>
    ? {for (final entry in value.entries) ...keyPaths(entry.value, '$prefix.${entry.key}')}
    : {prefix};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final template = File('tool/templates/app_config.json').absolute;

  test('fresh generated assets load through the real config model and asset loader', () async {
    final directory = workspace();
    final result = initializeAppConfig(
      mobileDirectory: directory,
      templateFile: template,
      serverUrl: 'https://meeting.example.com/',
      log: (_) {},
    );
    expect(result.generated, ['dev', 'test', 'prod']);
    final schemas = <Set<String>>[];
    final bundle = LocalConfigAssets(directory);
    for (final environment in result.generated) {
      final config = await loadAppConfig(env: environment, bundle: bundle);
      expect(config.env, environment);
      expect(config.defaultServerUrl, 'https://meeting.example.com');
      expect(config.features.showDevCode, environment == 'dev');
      expect(config.update.checkIntervalMin, environment == 'prod' ? 240 : 5);
      expect(config.network.connectTimeout, const Duration(seconds: 10));
      expect(config.live.titleMax, 50);
      final file = File.fromUri(directory.uri.resolve(appConfigAssetPath(environment)));
      schemas.add(keyPaths(jsonDecode(file.readAsStringSync())));
    }
    expect(schemas[0], schemas[1]);
    expect(schemas[0], schemas[2]);
    final defaults = jsonDecode(template.readAsStringSync()) as Map<String, dynamic>;
    expect(defaults['defaultServerUrl'], '');
  });

  test('fills missing environments while preserving customized existing configuration', () {
    final directory = workspace();
    final original = jsonDecode(template.readAsStringSync()) as Map<String, dynamic>;
    original['defaultServerUrl'] = 'https://custom.example.com';
    (original['heartbeat'] as Map<String, dynamic>)['intervalSec'] = 30;
    final prod = File.fromUri(directory.uri.resolve(appConfigAssetPath('prod')));
    prod.parent.createSync(recursive: true);
    final originalText = jsonEncode(original);
    prod.writeAsStringSync(originalText);
    final result = initializeAppConfig(
      mobileDirectory: directory,
      templateFile: template,
      serverUrl: 'https://different.example.com',
      log: (_) {},
    );
    expect(result.generated, ['dev', 'test']);
    expect(result.skipped, ['prod']);
    expect(prod.readAsStringSync(), originalText);
    final before = {
      for (final environment in configEnvironments)
        environment: File.fromUri(directory.uri.resolve(appConfigAssetPath(environment)))
            .readAsStringSync(),
    };
    final repeated = initializeAppConfig(
      mobileDirectory: directory,
      templateFile: File('${directory.path}/not-needed-template.json'),
      log: (_) {},
    );
    expect(repeated.generated, isEmpty);
    expect(repeated.skipped, ['dev', 'test', 'prod']);
    for (final entry in before.entries) {
      expect(
        File.fromUri(directory.uri.resolve(appConfigAssetPath(entry.key))).readAsStringSync(),
        entry.value,
      );
    }
  });

  test('dev-only initialization accepts an HTTP emulator gateway', () async {
    final directory = workspace();
    final result = initializeAppConfig(
      mobileDirectory: directory,
      templateFile: template,
      environments: ['dev'],
      serverUrl: 'http://10.0.2.2:39110/',
      log: (_) {},
    );
    expect(result.generated, ['dev']);
    final config = await loadAppConfig(env: 'dev', bundle: LocalConfigAssets(directory));
    expect(config.defaultServerUrl, 'http://10.0.2.2:39110');
    expect(File.fromUri(directory.uri.resolve(appConfigAssetPath('prod'))).existsSync(), isFalse);
  });

  test('invalid URLs and environment names fail before writing assets', () {
    final directory = workspace();
    for (final url in <String?>[
      null,
      'not-a-url',
      'http://meeting.example.com',
      'https://user:secret@meeting.example.com',
      'https://meeting.example.com?token=secret',
      'https://meeting.example.com#fragment',
    ]) {
      expect(
        () =>
            initializeAppConfig(mobileDirectory: directory, templateFile: template, serverUrl: url),
        throwsFormatException,
      );
      expect(directory.listSync(), isEmpty);
    }
    expect(
      () => initializeAppConfig(
        mobileDirectory: directory,
        templateFile: template,
        environments: ['unknown'],
      ),
      throwsFormatException,
    );
    expect(directory.listSync(), isEmpty);
  });

  test('malformed templates publish no configuration files', () {
    final directory = workspace();
    final broken = File('${directory.path}/broken.json')..writeAsStringSync('{invalid-json');
    expect(
      () => initializeAppConfig(
        mobileDirectory: directory,
        templateFile: broken,
        serverUrl: 'https://meeting.example.com',
      ),
      throwsFormatException,
    );
    expect(Directory('${directory.path}/assets').existsSync(), isFalse);
  });

  test('existing directories at configuration paths are never replaced', () {
    final directory = workspace();
    final protected = Directory.fromUri(directory.uri.resolve(appConfigAssetPath('prod')))
      ..createSync(recursive: true);
    expect(
      () => initializeAppConfig(
        mobileDirectory: directory,
        templateFile: template,
        serverUrl: 'https://meeting.example.com',
      ),
      throwsStateError,
    );
    expect(protected.existsSync(), isTrue);
    expect(File.fromUri(directory.uri.resolve(appConfigAssetPath('dev'))).existsSync(), isFalse);
  });
}
