import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads `assets/config/app_config.<env>.json` from disk (tests run from the package root).
AppConfig loadConfigFile(String env) =>
    parseAppConfig(File(appConfigAssetPath(env)).readAsStringSync());

/// Production config without a preset server URL — the "fresh install, nothing
/// configured" baseline, independent of the URL shipped in app_config.prod.json.
AppConfig loadConfigWithoutServer() => loadConfigFile('prod').copyWith(defaultServerUrl: '');

/// Dev config whose built-in server is [url] (the server URL is fixed per build).
AppConfig loadConfigWithServer(String url) => loadConfigFile('dev').copyWith(defaultServerUrl: url);

/// Builds a [ProviderContainer] with the same synchronous overrides as `main()`:
/// config (dev by default), mocked shared_preferences and mocked secure storage.
/// Disposed automatically at the end of the test.
Future<ProviderContainer> createTestContainer({
  AppConfig? config,
  Map<String, Object> prefs = const {},
  Map<String, String> secure = const {},
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  FlutterSecureStorage.setMockInitialValues(Map.of(secure));
  final instance = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config ?? loadConfigFile('dev')),
      sharedPreferencesProvider.overrideWithValue(instance),
      ...overrides,
    ],
    retry: (_, _) => null,
  );
  addTearDown(container.dispose);
  return container;
}

/// Dio adapter answering every request with [statusCode] and a JSON [body].
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.statusCode, [this.body = const <String, Object?>{}]);

  final int statusCode;
  final Object body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body is String ? body as String : jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
