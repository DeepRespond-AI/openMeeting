import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/config/settings_controller.dart';
import '../data/permission_handler_microphone_permission.dart';
import '../domain/microphone_permission.dart';
import '../domain/onboarding_state.dart';

export '../domain/microphone_permission.dart';
export '../domain/onboarding_state.dart';

part 'onboarding_controller.g.dart';

/// Step navigation of the onboarding flow:
/// welcome (language) → account (phone sign-in) → microphone → done. The server is fixed by
/// the build config (`AppConfig.defaultServerUrl`), so there is no server step.
///
/// keepAlive: the step must survive the page being rebuilt by router refreshes (e.g. while
/// the session changes after signing in).
@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() => const OnboardingState();

  bool get _canAdvance =>
      canLeaveOnboardingStep(state.step, signedIn: ref.read(isSignedInProvider));

  /// Moves to the next step (or finishes on the last one). Returns false when the current
  /// step's requirement is not met yet.
  Future<bool> next() async {
    if (!_canAdvance || state.finishing) return false;
    if (state.isLast) {
      await finish();
      return true;
    }
    state = state.copyWith(step: OnboardingStep.values[state.step.index + 1]);
    return true;
  }

  void back() {
    if (state.isFirst || state.finishing) return;
    state = state.copyWith(step: OnboardingStep.values[state.step.index - 1]);
  }

  /// Marks onboarding as done; the router then moves to the meetings list.
  Future<void> finish() async {
    state = state.copyWith(finishing: true);
    try {
      await ref.read(settingsControllerProvider.notifier).completeOnboarding();
    } finally {
      if (ref.mounted) state = state.copyWith(finishing: false);
    }
  }
}

/// Current microphone permission; [request] shows the system prompt.
@riverpod
class MicrophonePermissionController extends _$MicrophonePermissionController {
  @override
  Future<MicPermission> build() => ref.watch(microphonePermissionRepositoryProvider).status();

  Future<MicPermission> request() async {
    final repo = ref.read(microphonePermissionRepositoryProvider);
    final result = await repo.request();
    if (ref.mounted) state = AsyncData(result);
    return result;
  }

  Future<void> openSystemSettings() =>
      ref.read(microphonePermissionRepositoryProvider).openSystemSettings();

  /// Re-reads the status (e.g. after returning from the system settings).
  void refresh() => ref.invalidateSelf();
}

/// Whether the current onboarding step's requirement is met (reactive version of
/// [OnboardingController.next]'s check, for enabling the "next" button).
@riverpod
bool onboardingCanAdvance(Ref ref) => canLeaveOnboardingStep(
  ref.watch(onboardingControllerProvider.select((s) => s.step)),
  signedIn: ref.watch(isSignedInProvider),
);
