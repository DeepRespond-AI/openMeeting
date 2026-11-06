// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_work.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Meetings whose background work is still running: the sync after a recording was stopped
/// (remaining segments, audio upload) or the server transcription of an imported file
/// (desktop `recording_sync_pending`). The meeting page shows a "transcribing in the
/// background" state, reloads when the id leaves the set and holds the automatic summary.

@ProviderFor(MeetingSync)
final meetingSyncProvider = MeetingSyncProvider._();

/// Meetings whose background work is still running: the sync after a recording was stopped
/// (remaining segments, audio upload) or the server transcription of an imported file
/// (desktop `recording_sync_pending`). The meeting page shows a "transcribing in the
/// background" state, reloads when the id leaves the set and holds the automatic summary.
final class MeetingSyncProvider
    extends $NotifierProvider<MeetingSync, Set<String>> {
  /// Meetings whose background work is still running: the sync after a recording was stopped
  /// (remaining segments, audio upload) or the server transcription of an imported file
  /// (desktop `recording_sync_pending`). The meeting page shows a "transcribing in the
  /// background" state, reloads when the id leaves the set and holds the automatic summary.
  MeetingSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meetingSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meetingSyncHash();

  @$internal
  @override
  MeetingSync create() => MeetingSync();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$meetingSyncHash() => r'b4b3a33d5fc643b7ab4461e4220034ddd4dc06a2';

/// Meetings whose background work is still running: the sync after a recording was stopped
/// (remaining segments, audio upload) or the server transcription of an imported file
/// (desktop `recording_sync_pending`). The meeting page shows a "transcribing in the
/// background" state, reloads when the id leaves the set and holds the automatic summary.

abstract class _$MeetingSync extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The latest [BackgroundNotice] (`null` until the first one). Each notice carries a fresh
/// [BackgroundNotice.id] so two equal outcomes in a row are both shown.

@ProviderFor(BackgroundNotices)
final backgroundNoticesProvider = BackgroundNoticesProvider._();

/// The latest [BackgroundNotice] (`null` until the first one). Each notice carries a fresh
/// [BackgroundNotice.id] so two equal outcomes in a row are both shown.
final class BackgroundNoticesProvider
    extends $NotifierProvider<BackgroundNotices, BackgroundNotice?> {
  /// The latest [BackgroundNotice] (`null` until the first one). Each notice carries a fresh
  /// [BackgroundNotice.id] so two equal outcomes in a row are both shown.
  BackgroundNoticesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundNoticesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundNoticesHash();

  @$internal
  @override
  BackgroundNotices create() => BackgroundNotices();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundNotice? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundNotice?>(value),
    );
  }
}

String _$backgroundNoticesHash() => r'85d5968961934bbdf2d7079f0dbcc89b67355574';

/// The latest [BackgroundNotice] (`null` until the first one). Each notice carries a fresh
/// [BackgroundNotice.id] so two equal outcomes in a row are both shown.

abstract class _$BackgroundNotices extends $Notifier<BackgroundNotice?> {
  BackgroundNotice? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BackgroundNotice?, BackgroundNotice?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BackgroundNotice?, BackgroundNotice?>,
              BackgroundNotice?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
