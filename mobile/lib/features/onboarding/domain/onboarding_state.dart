import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

/// Onboarding steps, in order.
enum OnboardingStep { welcome, account, microphone }

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(OnboardingStep.welcome) OnboardingStep step,

    /// `completeOnboarding()` in flight.
    @Default(false) bool finishing,
  }) = _OnboardingState;

  const OnboardingState._();

  bool get isFirst => step.index == 0;

  bool get isLast => step.index == OnboardingStep.values.length - 1;

  /// 1-based position for the progress indicator.
  int get position => step.index + 1;

  static int get stepCount => OnboardingStep.values.length;
}

/// Pure rule: may the user move forward from [step]?
/// - account: the user must be signed in;
/// - welcome / microphone: always (the microphone permission can be skipped).
bool canLeaveOnboardingStep(OnboardingStep step, {required bool signedIn}) => switch (step) {
  OnboardingStep.welcome => true,
  OnboardingStep.account => signedIn,
  OnboardingStep.microphone => true,
};
