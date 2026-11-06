// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [GoRouter]. Created once; re-evaluates [guardRedirect] whenever the session
/// status or the onboarding flag changes (via `refreshListenable`), so navigation state
/// survives those changes.
///
/// Feature agents: replace the placeholder pages in `features/*/presentation/`, keep the
/// class names (or update the imports here). Add sub-routes as children of the matching route.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// The app's [GoRouter]. Created once; re-evaluates [guardRedirect] whenever the session
/// status or the onboarding flag changes (via `refreshListenable`), so navigation state
/// survives those changes.
///
/// Feature agents: replace the placeholder pages in `features/*/presentation/`, keep the
/// class names (or update the imports here). Add sub-routes as children of the matching route.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The app's [GoRouter]. Created once; re-evaluates [guardRedirect] whenever the session
  /// status or the onboarding flag changes (via `refreshListenable`), so navigation state
  /// survives those changes.
  ///
  /// Feature agents: replace the placeholder pages in `features/*/presentation/`, keep the
  /// class names (or update the imports here). Add sub-routes as children of the matching route.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'cc6272fe5d9f01239f8abeea191f91940eba2927';
