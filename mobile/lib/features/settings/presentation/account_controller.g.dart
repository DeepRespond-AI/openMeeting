// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Account actions of the settings page (rename, password, logout). State = the last action:
/// loading while it runs, error when it failed (the page shows it in a SnackBar).

@ProviderFor(AccountController)
final accountControllerProvider = AccountControllerProvider._();

/// Account actions of the settings page (rename, password, logout). State = the last action:
/// loading while it runs, error when it failed (the page shows it in a SnackBar).
final class AccountControllerProvider
    extends $AsyncNotifierProvider<AccountController, void> {
  /// Account actions of the settings page (rename, password, logout). State = the last action:
  /// loading while it runs, error when it failed (the page shows it in a SnackBar).
  AccountControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountControllerHash();

  @$internal
  @override
  AccountController create() => AccountController();
}

String _$accountControllerHash() => r'e5f0ed2d865fa11f384d16b01f3fdd36be9bd7ec';

/// Account actions of the settings page (rename, password, logout). State = the last action:
/// loading while it runs, error when it failed (the page shows it in a SnackBar).

abstract class _$AccountController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
