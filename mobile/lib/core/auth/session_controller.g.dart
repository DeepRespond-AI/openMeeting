// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The global session (DEVELOPMENT.md §2).
///
/// - `build` restores the stored session for the built-in server URL (a session issued by
///   another server, e.g. one entered in an older build, is discarded).
/// - Auth actions throw [ApiException] and leave the state untouched on failure; callers
///   (login page controllers) show the error.
/// - [expire] is called by the dio 401 interceptor; the router redirects to /login and
///   `App` shows the "session expired" SnackBar.

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

/// The global session (DEVELOPMENT.md §2).
///
/// - `build` restores the stored session for the built-in server URL (a session issued by
///   another server, e.g. one entered in an older build, is discarded).
/// - Auth actions throw [ApiException] and leave the state untouched on failure; callers
///   (login page controllers) show the error.
/// - [expire] is called by the dio 401 interceptor; the router redirects to /login and
///   `App` shows the "session expired" SnackBar.
final class SessionControllerProvider
    extends $AsyncNotifierProvider<SessionController, AuthState> {
  /// The global session (DEVELOPMENT.md §2).
  ///
  /// - `build` restores the stored session for the built-in server URL (a session issued by
  ///   another server, e.g. one entered in an older build, is discarded).
  /// - Auth actions throw [ApiException] and leave the state untouched on failure; callers
  ///   (login page controllers) show the error.
  /// - [expire] is called by the dio 401 interceptor; the router redirects to /login and
  ///   `App` shows the "session expired" SnackBar.
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();
}

String _$sessionControllerHash() => r'c0ee0b859e6f3b3e786002213b13ccc565973a77';

/// The global session (DEVELOPMENT.md §2).
///
/// - `build` restores the stored session for the built-in server URL (a session issued by
///   another server, e.g. one entered in an older build, is discarded).
/// - Auth actions throw [ApiException] and leave the state untouched on failure; callers
///   (login page controllers) show the error.
/// - [expire] is called by the dio 401 interceptor; the router redirects to /login and
///   `App` shows the "session expired" SnackBar.

abstract class _$SessionController extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// True while a user is signed in (narrow provider for widgets/heartbeat).

@ProviderFor(isSignedIn)
final isSignedInProvider = IsSignedInProvider._();

/// True while a user is signed in (narrow provider for widgets/heartbeat).

final class IsSignedInProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// True while a user is signed in (narrow provider for widgets/heartbeat).
  IsSignedInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isSignedInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isSignedInHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isSignedIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isSignedInHash() => r'5edf0ae36f69b189871e4ec4203b331f54f96bf2';

/// The signed-in user or null.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// The signed-in user or null.

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// The signed-in user or null.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'0d9b1007db86a5b361c99623757295e4098511ea';

/// `GET /auth/config` of the configured server (server-provided auth parameters:
/// code length, resend interval, registration/SMS state). Auto-disposed; `ref.invalidate` to re-check.

@ProviderFor(authConfig)
final authConfigProvider = AuthConfigProvider._();

/// `GET /auth/config` of the configured server (server-provided auth parameters:
/// code length, resend interval, registration/SMS state). Auto-disposed; `ref.invalidate` to re-check.

final class AuthConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthConfig>,
          AuthConfig,
          FutureOr<AuthConfig>
        >
    with $FutureModifier<AuthConfig>, $FutureProvider<AuthConfig> {
  /// `GET /auth/config` of the configured server (server-provided auth parameters:
  /// code length, resend interval, registration/SMS state). Auto-disposed; `ref.invalidate` to re-check.
  AuthConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authConfigHash();

  @$internal
  @override
  $FutureProviderElement<AuthConfig> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AuthConfig> create(Ref ref) {
    return authConfig(ref);
  }
}

String _$authConfigHash() => r'93baba876f617f6d51be150d58948939ddf59e00';
