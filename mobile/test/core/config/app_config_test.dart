import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/app_enums.dart';

import '../../helpers/test_config.dart';

/// Flattens JSON into dotted key paths (lists count as leaves).
Set<String> _keyPaths(Object? json, [String prefix = '']) {
  if (json is! Map<String, dynamic>) return {prefix};
  return {
    for (final e in json.entries)
      ..._keyPaths(e.value, prefix.isEmpty ? e.key : '$prefix.${e.key}'),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final env in ['dev', 'test', 'prod']) {
    test('parses app_config.$env.json', () {
      final config = loadConfigFile(env);
      expect(config.env, env);
      expect(config.isDev, env == 'dev');
      expect(config.network.connectTimeout, const Duration(seconds: 10));
      expect(config.network.retry.maxRetries, 3);
      expect(config.network.retry.backoffMs, [500, 1000, 2000]);
      expect(config.heartbeat.interval, const Duration(seconds: 15));
      expect(config.heartbeat.backgroundInterval, const Duration(seconds: 60));
      expect(config.pagination.transcriptPageSize, 100);
      expect(config.auth.phonePrefixes, containsAll(<String>['+86', '86', '0086']));
      expect(config.vad.maxSegmentSec, 25.0);
      expect(config.recording.defaultSource, RecordingSource.microphone);
      expect(config.transcription.defaultLanguage, 'auto');
      expect(config.ui.defaultLocaleMode, LocaleMode.system);
    });

    test('loads $env config from the Flutter asset bundle', () async {
      final config = await loadAppConfig(env: env);
      expect(config.env, env);
      expect(
        config.defaultServerUrl,
        buildServerUrl.isEmpty ? loadConfigFile(env).defaultServerUrl : buildServerUrl,
      );
    });
  }

  test('dev, test and prod configs have exactly the same keys', () {
    Set<String> keys(String env) => _keyPaths(
      jsonDecode(File(appConfigAssetPath(env)).readAsStringSync()) as Map<String, dynamic>,
    );
    expect(keys('dev'), keys('test'));
    expect(keys('dev'), keys('prod'));
  });

  test('APP_ENV selects the bundled config at build time', () async {
    expect((await loadAppConfig()).env, appEnv);
  });

  test('environment specific values', () {
    expect(loadConfigFile('dev').features.showDevCode, isTrue);
    expect(loadConfigFile('test').features.showDevCode, isFalse);
    expect(loadConfigFile('prod').features.showDevCode, isFalse);
    // Shipped builds may preset the company server, but only over HTTPS.
    final prodUrl = loadConfigFile('prod').defaultServerUrl;
    expect(prodUrl.isEmpty || prodUrl.startsWith('https://'), isTrue, reason: prodUrl);
  });

  test('RetryConfig.delayFor clamps to the last backoff value', () {
    final retry = loadConfigFile('dev').network.retry;
    expect(retry.delayFor(0), const Duration(milliseconds: 500));
    expect(retry.delayFor(2), const Duration(milliseconds: 2000));
    expect(retry.delayFor(10), const Duration(milliseconds: 2000));
  });

  test('missing key fails parsing', () {
    final json =
        jsonDecode(File(appConfigAssetPath('dev')).readAsStringSync()) as Map<String, dynamic>;
    json.remove('heartbeat');
    expect(() => parseAppConfig(jsonEncode(json)), throwsA(anything));
  });
}
