import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/app.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/settings_controller.dart';
import 'package:meeting/core/config/settings_store.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_config.dart';

void main() {
  testWidgets('first launch shows onboarding, then login', (tester) async {
    SharedPreferences.setMockInitialValues({'settings.localeMode': 'zh'});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(loadConfigWithoutServer()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        retry: (_, _) => null,
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    final zh = lookupAppLocalizations(const Locale('zh'));
    expect(find.text(zh.onboardingGetStarted), findsOneWidget);

    // Onboarding step 2 (sign in; the server is built in) — onboarding is not completed yet.
    await tester.tap(find.text(zh.onboardingGetStarted));
    await tester.pumpAndSettle();
    expect(find.text(zh.onboardingAccountTitle), findsOneWidget);
    expect(prefs.getBool('settings.onboardingCompleted'), isNull);

    // Once onboarding is completed without a session, the router shows the login page.
    final container = ProviderScope.containerOf(tester.element(find.byType(App)));
    await container.read(settingsControllerProvider.notifier).completeOnboarding();
    await tester.pumpAndSettle();
    expect(find.text(zh.authServerRequired), findsOneWidget);
    expect(prefs.getBool('settings.onboardingCompleted'), isTrue);
  });
}
