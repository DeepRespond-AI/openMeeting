// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Hydrate SDK-owned profiles and stay subscribed to both local and remote
/// updates. Subscribe before reading the initial snapshot to avoid lost updates.

@ProviderFor(imUserProfile)
final imUserProfileProvider = ImUserProfileFamily._();

/// Hydrate SDK-owned profiles and stay subscribed to both local and remote
/// updates. Subscribe before reading the initial snapshot to avoid lost updates.

final class ImUserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
  /// Hydrate SDK-owned profiles and stay subscribed to both local and remote
  /// updates. Subscribe before reading the initial snapshot to avoid lost updates.
  ImUserProfileProvider._({
    required ImUserProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'imUserProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$imUserProfileHash();

  @override
  String toString() {
    return r'imUserProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    final argument = this.argument as String;
    return imUserProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ImUserProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$imUserProfileHash() => r'39e987a5e7c676efaefe3f23e7a9fc0937ea07ed';

/// Hydrate SDK-owned profiles and stay subscribed to both local and remote
/// updates. Subscribe before reading the initial snapshot to avoid lost updates.

final class ImUserProfileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<UserProfile?>, String> {
  ImUserProfileFamily._()
    : super(
        retry: null,
        name: r'imUserProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Hydrate SDK-owned profiles and stay subscribed to both local and remote
  /// updates. Subscribe before reading the initial snapshot to avoid lost updates.

  ImUserProfileProvider call(String username) =>
      ImUserProfileProvider._(argument: username, from: this);

  @override
  String toString() => r'imUserProfileProvider';
}
