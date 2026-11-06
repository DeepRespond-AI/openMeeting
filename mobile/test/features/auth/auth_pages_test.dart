import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/auth/presentation/login_page.dart';
import 'package:meeting/features/auth/presentation/phone_auth_controller.dart';
import 'package:meeting/features/onboarding/data/permission_handler_microphone_permission.dart';
import 'package:meeting/features/onboarding/presentation/onboarding_controller.dart';
import 'package:meeting/features/onboarding/presentation/onboarding_page.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_config.dart';

class _Mic implements MicrophonePermissionRepository {
  @override
  Future<MicPermission> status() async => MicPermission.denied;
  @override
  Future<MicPermission> request() async => MicPermission.granted;
  @override
  Future<bool> openSystemSettings() async => true;
}

Future<ProviderContainer> _container(WidgetTester tester) async {
  late ProviderContainer c;
  await tester.runAsync(() async {
    c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        microphonePermissionRepositoryProvider.overrideWithValue(_Mic()),
      ],
    );
    await c.read(sessionControllerProvider.future);
  });
  return c;
}

Widget _app(ProviderContainer c, Widget home, Locale locale) => UncontrolledProviderScope(
  container: c,
  child: MaterialApp(
    theme: AppTheme.light(),
    locale: locale,
    supportedLocales: appSupportedLocales,
    localizationsDelegates: localizationsDelegates,
    home: home,
  ),
);

void main() {
  for (final locale in appSupportedLocales) {
    testWidgets('login page: send code + sign in (${locale.languageCode})', (tester) async {
      final c = await _container(tester);
      await tester.pumpWidget(_app(c, const LoginPage(), locale));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(locale);

      // The built-in server address is never shown.
      expect(find.textContaining('server.test'), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, l10n.authPhoneLabel), '13800138000');
      // Password login is the default; switch to SMS-code login.
      expect(find.widgetWithText(TextField, l10n.authPasswordLabel), findsOneWidget);
      await tester.tap(find.text(l10n.authMethodCode));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, l10n.authPasswordLabel), findsNothing);
      await tester.tap(find.text(l10n.authSendCode));
      await tester.pump();
      expect(find.text(l10n.authDevCodeHint('123456')), findsOneWidget);
      expect(find.text(l10n.authResendIn(60)), findsOneWidget);

      await tester.tap(find.text(l10n.authDevCodeHint('123456')));
      await tester.tap(find.widgetWithText(FilledButton, l10n.authLoginButton));
      await tester.pumpAndSettle();
      expect(c.read(isSignedInProvider), isTrue);

      // Let the resend countdown timer finish before the test ends.
      c.invalidate(phoneAuthControllerProvider);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('login page: password sign-in and forgot password (${locale.languageCode})', (
      tester,
    ) async {
      final c = await _container(tester);
      await tester.pumpWidget(_app(c, const LoginPage(), locale));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(locale);

      // Forgot password shows the reset flow (code + new password + confirmation) and back.
      await tester.tap(find.text(l10n.authForgotPassword));
      await tester.pumpAndSettle();
      expect(find.text(l10n.authResetTitle), findsOneWidget);
      expect(find.widgetWithText(TextField, l10n.authNewPasswordLabel), findsOneWidget);
      expect(find.widgetWithText(TextField, l10n.authConfirmPasswordLabel), findsOneWidget);
      await tester.ensureVisible(find.text(l10n.authBackToLogin));
      await tester.tap(find.text(l10n.authBackToLogin));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, l10n.authPhoneLabel), '13800138000');
      await tester.enterText(find.widgetWithText(TextField, l10n.authPasswordLabel), 'Pass1234');
      await tester.tap(find.widgetWithText(FilledButton, l10n.authLoginButton));
      await tester.pumpAndSettle();
      expect(c.read(isSignedInProvider), isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('onboarding renders every step (${locale.languageCode})', (tester) async {
      final c = await _container(tester);
      await tester.pumpWidget(_app(c, const OnboardingPage(), locale));
      await tester.pumpAndSettle();
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(find.text(l10n.onboardingWelcomeTitle), findsOneWidget);
      expect(find.text(l10n.onboardingStepProgress(1, 3)), findsOneWidget);

      await tester.tap(find.text(l10n.onboardingGetStarted));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingAccountTitle), findsOneWidget);

      await c.read(sessionControllerProvider.notifier).login('13800138000', '123456');
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingSignedInAs(testUser.name)), findsOneWidget);
      await tester.tap(find.text(l10n.commonNext));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingMicTitle), findsOneWidget);
      expect(find.text(l10n.onboardingMicAllow), findsOneWidget);
      expect(c.read(onboardingControllerProvider).step, OnboardingStep.microphone);
    });
  }
}
