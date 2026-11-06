// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(passwordRules)
final passwordRulesProvider = PasswordRulesProvider._();

final class PasswordRulesProvider
    extends $FunctionalProvider<PasswordRules, PasswordRules, PasswordRules>
    with $Provider<PasswordRules> {
  PasswordRulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordRulesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordRulesHash();

  @$internal
  @override
  $ProviderElement<PasswordRules> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PasswordRules create(Ref ref) {
    return passwordRules(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordRules value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordRules>(value),
    );
  }
}

String _$passwordRulesHash() => r'bdcb4295e9d8a8a11e3fdebb5b2915c74d2723d6';
