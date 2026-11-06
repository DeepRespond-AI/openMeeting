import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_config.dart';

part 'app_config_provider.g.dart';

/// Environment chosen at build time: `flutter run --dart-define=APP_ENV=dev`.
const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
const String buildServerUrl = String.fromEnvironment('OPENMEETING_SERVER_URL');

/// Distribution channel chosen at build time: `--dart-define=APP_CHANNEL=huawei`.
/// `direct` (default) = the app downloads and installs APK updates itself; any other value is
/// an Android store channel whose store page is opened instead (server update policy).
const String appChannel = String.fromEnvironment('APP_CHANNEL', defaultValue: 'direct');

/// Asset path of the config for [env].
String appConfigAssetPath(String env) => 'assets/config/app_config.$env.json';

/// Loads and parses the [AppConfig] asset. Called once in `main()` before `runApp`.
Future<AppConfig> loadAppConfig({String env = appEnv, AssetBundle? bundle}) async {
  final raw = await (bundle ?? rootBundle).loadString(appConfigAssetPath(env));
  final config = parseAppConfig(raw);
  return buildServerUrl.isEmpty ? config : config.copyWith(defaultServerUrl: buildServerUrl);
}

/// Parses config JSON text (exposed for tests).
AppConfig parseAppConfig(String raw) => AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);

/// The app configuration — synchronous for consumers.
///
/// It is loaded in `main()` and injected with
/// `appConfigProvider.overrideWithValue(config)`; tests override it the same way
/// (see `test/helpers/test_config.dart`).
@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError(
  'appConfigProvider must be overridden with the config loaded in main()',
);
