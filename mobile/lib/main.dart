import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/app_config_provider.dart';
import 'core/config/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Synchronous dependencies are loaded once here and injected, so consumers never await them.
  final config = await loadAppConfig();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      // Riverpod 3 retries failing providers by default; our repositories surface errors
      // and retry explicitly (`core/api/retry.dart`, AppConfig.network.retry) instead.
      retry: (_, _) => null,
      child: const App(),
    ),
  );
}
