import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/config/settings_controller.dart';
import 'package:meeting/core/heartbeat/heartbeat_controller.dart';
import 'package:meeting/core/heartbeat/recording_status.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/core/widgets/app_switch_list_tile.dart';
import 'package:meeting/features/settings/domain/phone_mask.dart';
import 'package:meeting/features/settings/presentation/account_controller.dart';
import 'package:meeting/features/settings/presentation/settings_page.dart';
import 'package:meeting/features/settings/presentation/settings_providers.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_config.dart';

/// Heartbeat stand-in: no timers / network in widget tests.
class _IdleHeartbeat extends HeartbeatController {
  @override
  HeartbeatState build() => const HeartbeatState();
}

/// No update checks (timers / network) in widget tests.
class _IdleUpdates extends UpdateController {
  @override
  UpdateState build() => const UpdateState();
}

Future<(ProviderContainer, FakeAuthRepository)> _setup() async {
  final repo = FakeAuthRepository();
  final c = await createTestContainer(
    config: loadConfigWithServer('http://server.test'),
    prefs: const {'settings.onboardingCompleted': true},
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      settingsAppVersionProvider.overrideWithValue(const AsyncData('1.0.0+1')),
      heartbeatControllerProvider.overrideWith(_IdleHeartbeat.new),
      updateControllerProvider.overrideWith(_IdleUpdates.new),
    ],
  );
  await c.read(sessionControllerProvider.future);
  await c.read(sessionControllerProvider.notifier).login('13800138000', '123456');
  return (c, repo);
}

void main() {
  test('maskPhone keeps prefix/suffix', () {
    expect(maskPhone('13800138000', visiblePrefix: 3, visibleSuffix: 4), '138****8000');
    expect(maskPhone('1234', visiblePrefix: 3, visibleSuffix: 4), '1234');
  });

  test('maskedPhoneProvider uses AppConfig.auth mask lengths', () async {
    final (c, _) = await _setup();
    expect(c.read(maskedPhoneProvider), '138****8000');
  });

  test('rename goes through the session; logout refused while recording', () async {
    final (c, repo) = await _setup();
    c.listen(accountControllerProvider, (_, _) {});
    final user = await c.read(accountControllerProvider.notifier).rename(' 王五 ');
    expect(user?.name, '王五');
    expect(c.read(currentUserProvider)?.name, '王五');

    c.read(recordingStatusControllerProvider.notifier).set(recording: true);
    expect(c.read(settingsLockedProvider), isTrue);
    expect(await c.read(accountControllerProvider.notifier).logout(), isFalse);
    expect(c.read(isSignedInProvider), isTrue);

    c.read(recordingStatusControllerProvider.notifier).setIdle();
    expect(await c.read(accountControllerProvider.notifier).logout(), isTrue);
    expect(c.read(isSignedInProvider), isFalse);
    expect(repo.calls, contains('logout'));
  });

  testWidgets('password dialog: set the first password, then change it', (tester) async {
    late ProviderContainer c;
    late FakeAuthRepository repo;
    await tester.runAsync(() async => (c, repo) = await _setup());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          supportedLocales: appSupportedLocales,
          localizationsDelegates: localizationsDelegates,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));

    // Legacy account: no password yet → "set", no old-password field.
    expect(find.text(l10n.settingsPasswordNotSet), findsOneWidget);
    await tester.tap(find.text(l10n.settingsSetPassword));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, l10n.settingsOldPassword), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, l10n.authNewPasswordLabel), 'short');
    await tester.enterText(find.widgetWithText(TextField, l10n.authConfirmPasswordLabel), 'short');
    await tester.tap(find.text(l10n.commonSave));
    await tester.pumpAndSettle();
    expect(find.text(l10n.authPasswordLength(8, 64)), findsOneWidget);
    expect(repo.calls, isNot(contains('changePassword')));

    await tester.enterText(find.widgetWithText(TextField, l10n.authNewPasswordLabel), 'Pass1234');
    await tester.enterText(
      find.widgetWithText(TextField, l10n.authConfirmPasswordLabel),
      'Pass1234',
    );
    await tester.tap(find.text(l10n.commonSave));
    await tester.pumpAndSettle();
    expect(repo.calls, contains('changePassword'));
    expect(repo.lastOldPassword, isNull);
    expect(find.text(l10n.settingsPasswordIsSet), findsOneWidget);

    // Now "change": the old password is required.
    await tester.tap(find.text(l10n.settingsChangePassword));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, l10n.authNewPasswordLabel), 'Pass5678');
    await tester.enterText(
      find.widgetWithText(TextField, l10n.authConfirmPasswordLabel),
      'Pass5678',
    );
    await tester.tap(find.text(l10n.commonSave));
    await tester.pumpAndSettle();
    expect(find.text(l10n.settingsOldPasswordRequired), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, l10n.settingsOldPassword), 'Pass1234');
    await tester.tap(find.text(l10n.commonSave));
    await tester.pumpAndSettle();
    expect(repo.lastOldPassword, 'Pass1234');
    expect(repo.lastPassword, 'Pass5678');
  });

  testWidgets('settings page binds preferences to SettingsController', (tester) async {
    late ProviderContainer c;
    await tester.runAsync(() async => (c, _) = await _setup());
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          supportedLocales: appSupportedLocales,
          localizationsDelegates: localizationsDelegates,
          home: const SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));

    // Account section.
    expect(find.text(testUser.name), findsOneWidget);
    expect(find.text('138****8000'), findsOneWidget);
    // The built-in server address is never shown.
    expect(find.textContaining('server.test'), findsNothing);

    // Language: English.
    await tester.tap(find.text(l10n.languageEn).first);
    await tester.pumpAndSettle();
    expect(c.read(effectiveSettingsProvider).localeMode, LocaleMode.en);

    // Auto summary toggle (dev default true → false).
    final autoSummary = find.widgetWithText(AppSwitchListTile, l10n.settingsAutoSummary);
    await tester.ensureVisible(autoSummary);
    await tester.pumpAndSettle();
    await tester.tap(autoSummary);
    await tester.pumpAndSettle();
    expect(c.read(effectiveSettingsProvider).autoSummary, isFalse);

    // Default recording source → system.
    final system = find.widgetWithText(RadioListTile<RecordingSource>, l10n.settingsSourceSystem);
    await tester.ensureVisible(system);
    await tester.pumpAndSettle();
    await tester.tap(system);
    await tester.pumpAndSettle();
    expect(c.read(effectiveSettingsProvider).defaultRecordingSource, RecordingSource.system);
  });
}
