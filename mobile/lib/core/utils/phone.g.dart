// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(phoneRules)
final phoneRulesProvider = PhoneRulesProvider._();

final class PhoneRulesProvider
    extends $FunctionalProvider<PhoneRules, PhoneRules, PhoneRules>
    with $Provider<PhoneRules> {
  PhoneRulesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'phoneRulesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$phoneRulesHash();

  @$internal
  @override
  $ProviderElement<PhoneRules> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PhoneRules create(Ref ref) {
    return phoneRules(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PhoneRules value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PhoneRules>(value),
    );
  }
}

String _$phoneRulesHash() => r'cd0aa8f92c7cbbc2270352398001b80376722b94';
