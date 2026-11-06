import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/settings_controller.dart';
import 'package:meeting/features/onboarding/data/permission_handler_microphone_permission.dart';
import 'package:meeting/features/onboarding/presentation/onboarding_controller.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_config.dart';

class _FakeMic implements MicrophonePermissionRepository {
  MicPermission current = MicPermission.denied;
  MicPermission onRequest = MicPermission.granted;
  int requests = 0;

  @override
  Future<MicPermission> status() async => current;

  @override
  Future<MicPermission> request() async {
    requests++;
    return current = onRequest;
  }

  @override
  Future<bool> openSystemSettings() async => true;
}

Future<(ProviderContainer, _FakeMic)> _setup() async {
  final mic = _FakeMic();
  final c = await createTestContainer(
    config: loadConfigFile('dev'),
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      microphonePermissionRepositoryProvider.overrideWithValue(mic),
    ],
  );
  await c.read(sessionControllerProvider.future);
  return (c, mic);
}

OnboardingController _ctrl(ProviderContainer c) => c.read(onboardingControllerProvider.notifier);
OnboardingStep _step(ProviderContainer c) => c.read(onboardingControllerProvider).step;

void main() {
  test('canLeaveOnboardingStep: only the account step has a requirement', () {
    for (final step in OnboardingStep.values) {
      expect(
        canLeaveOnboardingStep(step, signedIn: false),
        step != OnboardingStep.account,
        reason: step.name,
      );
      expect(canLeaveOnboardingStep(step, signedIn: true), isTrue);
    }
  });

  test('full flow: welcome → account → microphone → completed (no server step)', () async {
    final (c, _) = await _setup();
    expect(_step(c), OnboardingStep.welcome);
    expect(c.read(onboardingControllerProvider).position, 1);
    expect(OnboardingState.stepCount, 3);

    expect(await _ctrl(c).next(), isTrue);
    expect(_step(c), OnboardingStep.account);

    // Blocked until signed in.
    expect(await _ctrl(c).next(), isFalse);
    expect(c.read(onboardingCanAdvanceProvider), isFalse);
    await c.read(sessionControllerProvider.notifier).login('13800138000', '123456');
    expect(c.read(onboardingCanAdvanceProvider), isTrue);
    expect(await _ctrl(c).next(), isTrue);
    expect(_step(c), OnboardingStep.microphone);
    expect(c.read(onboardingControllerProvider).isLast, isTrue);

    // Microphone may be skipped: next() on the last step finishes onboarding.
    expect(c.read(effectiveSettingsProvider).onboardingCompleted, isFalse);
    expect(await _ctrl(c).next(), isTrue);
    expect(c.read(effectiveSettingsProvider).onboardingCompleted, isTrue);
  });

  test('back goes to the previous step and stops at the first', () async {
    final (c, _) = await _setup();
    await _ctrl(c).next();
    expect(_step(c), OnboardingStep.account);
    _ctrl(c).back();
    expect(_step(c), OnboardingStep.welcome);
    _ctrl(c).back();
    expect(_step(c), OnboardingStep.welcome);
  });

  test('microphone permission controller reads and requests', () async {
    final (c, mic) = await _setup();
    c.listen(microphonePermissionControllerProvider, (_, _) {});
    expect(await c.read(microphonePermissionControllerProvider.future), MicPermission.denied);
    final result = await c.read(microphonePermissionControllerProvider.notifier).request();
    expect(result, MicPermission.granted);
    expect(mic.requests, 1);
    expect(c.read(microphonePermissionControllerProvider).value, MicPermission.granted);
  });
}
