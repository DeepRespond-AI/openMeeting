// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meetings_changed.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// App-wide "the set of meetings changed" signal (a revision counter).
///
/// Features that create or delete meetings outside the list screen (recording,
/// import) call [MeetingsChanged.bump]; providers that cache meeting lists
/// `ref.watch` it and rebuild. Lives in core so features never import each other.

@ProviderFor(MeetingsChanged)
final meetingsChangedProvider = MeetingsChangedProvider._();

/// App-wide "the set of meetings changed" signal (a revision counter).
///
/// Features that create or delete meetings outside the list screen (recording,
/// import) call [MeetingsChanged.bump]; providers that cache meeting lists
/// `ref.watch` it and rebuild. Lives in core so features never import each other.
final class MeetingsChangedProvider
    extends $NotifierProvider<MeetingsChanged, int> {
  /// App-wide "the set of meetings changed" signal (a revision counter).
  ///
  /// Features that create or delete meetings outside the list screen (recording,
  /// import) call [MeetingsChanged.bump]; providers that cache meeting lists
  /// `ref.watch` it and rebuild. Lives in core so features never import each other.
  MeetingsChangedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meetingsChangedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meetingsChangedHash();

  @$internal
  @override
  MeetingsChanged create() => MeetingsChanged();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$meetingsChangedHash() => r'952e38904b09f73f7b89048ce61cab53005bb9a2';

/// App-wide "the set of meetings changed" signal (a revision counter).
///
/// Features that create or delete meetings outside the list screen (recording,
/// import) call [MeetingsChanged.bump]; providers that cache meeting lists
/// `ref.watch` it and rebuild. Lives in core so features never import each other.

abstract class _$MeetingsChanged extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
