// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_activity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Prevent forced installation/navigation from interrupting a joined meeting.

@ProviderFor(LiveActivity)
final liveActivityProvider = LiveActivityProvider._();

/// Prevent forced installation/navigation from interrupting a joined meeting.
final class LiveActivityProvider extends $NotifierProvider<LiveActivity, bool> {
  /// Prevent forced installation/navigation from interrupting a joined meeting.
  LiveActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveActivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveActivityHash();

  @$internal
  @override
  LiveActivity create() => LiveActivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$liveActivityHash() => r'007512252f914a94def6fc4c202a3746ef79f44a';

/// Prevent forced installation/navigation from interrupting a joined meeting.

abstract class _$LiveActivity extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
