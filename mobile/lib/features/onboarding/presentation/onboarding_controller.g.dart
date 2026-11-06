// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Step navigation of the onboarding flow:
/// welcome (language) → account (phone sign-in) → microphone → done. The server is fixed by
/// the build config (`AppConfig.defaultServerUrl`), so there is no server step.
///
/// keepAlive: the step must survive the page being rebuilt by router refreshes (e.g. while
/// the session changes after signing in).

@ProviderFor(OnboardingController)
final onboardingControllerProvider = OnboardingControllerProvider._();

/// Step navigation of the onboarding flow:
/// welcome (language) → account (phone sign-in) → microphone → done. The server is fixed by
/// the build config (`AppConfig.defaultServerUrl`), so there is no server step.
///
/// keepAlive: the step must survive the page being rebuilt by router refreshes (e.g. while
/// the session changes after signing in).
final class OnboardingControllerProvider
    extends $NotifierProvider<OnboardingController, OnboardingState> {
  /// Step navigation of the onboarding flow:
  /// welcome (language) → account (phone sign-in) → microphone → done. The server is fixed by
  /// the build config (`AppConfig.defaultServerUrl`), so there is no server step.
  ///
  /// keepAlive: the step must survive the page being rebuilt by router refreshes (e.g. while
  /// the session changes after signing in).
  OnboardingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingControllerHash();

  @$internal
  @override
  OnboardingController create() => OnboardingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingState>(value),
    );
  }
}

String _$onboardingControllerHash() =>
    r'7a3c712a0f09a661e6ad7a91bf62e375b142db9a';

/// Step navigation of the onboarding flow:
/// welcome (language) → account (phone sign-in) → microphone → done. The server is fixed by
/// the build config (`AppConfig.defaultServerUrl`), so there is no server step.
///
/// keepAlive: the step must survive the page being rebuilt by router refreshes (e.g. while
/// the session changes after signing in).

abstract class _$OnboardingController extends $Notifier<OnboardingState> {
  OnboardingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<OnboardingState, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingState, OnboardingState>,
              OnboardingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Current microphone permission; [request] shows the system prompt.

@ProviderFor(MicrophonePermissionController)
final microphonePermissionControllerProvider =
    MicrophonePermissionControllerProvider._();

/// Current microphone permission; [request] shows the system prompt.
final class MicrophonePermissionControllerProvider
    extends
        $AsyncNotifierProvider<MicrophonePermissionController, MicPermission> {
  /// Current microphone permission; [request] shows the system prompt.
  MicrophonePermissionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'microphonePermissionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$microphonePermissionControllerHash();

  @$internal
  @override
  MicrophonePermissionController create() => MicrophonePermissionController();
}

String _$microphonePermissionControllerHash() =>
    r'22b1d67daf917c5eabadf9c88879716c89e5e3d3';

/// Current microphone permission; [request] shows the system prompt.

abstract class _$MicrophonePermissionController
    extends $AsyncNotifier<MicPermission> {
  FutureOr<MicPermission> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MicPermission>, MicPermission>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MicPermission>, MicPermission>,
              AsyncValue<MicPermission>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the current onboarding step's requirement is met (reactive version of
/// [OnboardingController.next]'s check, for enabling the "next" button).

@ProviderFor(onboardingCanAdvance)
final onboardingCanAdvanceProvider = OnboardingCanAdvanceProvider._();

/// Whether the current onboarding step's requirement is met (reactive version of
/// [OnboardingController.next]'s check, for enabling the "next" button).

final class OnboardingCanAdvanceProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the current onboarding step's requirement is met (reactive version of
  /// [OnboardingController.next]'s check, for enabling the "next" button).
  OnboardingCanAdvanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingCanAdvanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingCanAdvanceHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return onboardingCanAdvance(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$onboardingCanAdvanceHash() =>
    r'fb7971a4c8232e0ad481e26eebae3bf20ddcd852';
