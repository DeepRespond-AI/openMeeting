// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// SMS-code length to use: server value (`GET /auth/config`), else the app config default.

@ProviderFor(authCodeLength)
final authCodeLengthProvider = AuthCodeLengthProvider._();

/// SMS-code length to use: server value (`GET /auth/config`), else the app config default.

final class AuthCodeLengthProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// SMS-code length to use: server value (`GET /auth/config`), else the app config default.
  AuthCodeLengthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authCodeLengthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authCodeLengthHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return authCodeLength(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$authCodeLengthHash() => r'8727a8e9faca1f9575f111075e8b47a760fcabe8';

/// Validation rules for the phone auth form (phone pattern, code length, name length, password).

@ProviderFor(phoneAuthValidator)
final phoneAuthValidatorProvider = PhoneAuthValidatorProvider._();

/// Validation rules for the phone auth form (phone pattern, code length, name length, password).

final class PhoneAuthValidatorProvider
    extends
        $FunctionalProvider<
          PhoneAuthValidator,
          PhoneAuthValidator,
          PhoneAuthValidator
        >
    with $Provider<PhoneAuthValidator> {
  /// Validation rules for the phone auth form (phone pattern, code length, name length, password).
  PhoneAuthValidatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneAuthValidatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneAuthValidatorHash();

  @$internal
  @override
  $ProviderElement<PhoneAuthValidator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PhoneAuthValidator create(Ref ref) {
    return phoneAuthValidator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneAuthValidator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneAuthValidator>(value),
    );
  }
}

String _$phoneAuthValidatorHash() =>
    r'201a91ac0906638ef119ed4c62915b393740a7bc';

/// Drives [PhoneAuthForm]: login (password or SMS code) / register tabs, forgot-password
/// flow, SMS code with resend countdown, submit.
///
/// Signing in goes through [SessionController]; on success the session state changes and
/// the router (or the onboarding flow) moves on by itself.

@ProviderFor(PhoneAuthController)
final phoneAuthControllerProvider = PhoneAuthControllerProvider._();

/// Drives [PhoneAuthForm]: login (password or SMS code) / register tabs, forgot-password
/// flow, SMS code with resend countdown, submit.
///
/// Signing in goes through [SessionController]; on success the session state changes and
/// the router (or the onboarding flow) moves on by itself.
final class PhoneAuthControllerProvider
    extends $NotifierProvider<PhoneAuthController, PhoneAuthState> {
  /// Drives [PhoneAuthForm]: login (password or SMS code) / register tabs, forgot-password
  /// flow, SMS code with resend countdown, submit.
  ///
  /// Signing in goes through [SessionController]; on success the session state changes and
  /// the router (or the onboarding flow) moves on by itself.
  PhoneAuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneAuthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneAuthControllerHash();

  @$internal
  @override
  PhoneAuthController create() => PhoneAuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneAuthState>(value),
    );
  }
}

String _$phoneAuthControllerHash() =>
    r'730dd5a47583c7f90384acf99063b56a53ade095';

/// Drives [PhoneAuthForm]: login (password or SMS code) / register tabs, forgot-password
/// flow, SMS code with resend countdown, submit.
///
/// Signing in goes through [SessionController]; on success the session state changes and
/// the router (or the onboarding flow) moves on by itself.

abstract class _$PhoneAuthController extends $Notifier<PhoneAuthState> {
  PhoneAuthState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PhoneAuthState, PhoneAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PhoneAuthState, PhoneAuthState>,
              PhoneAuthState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
