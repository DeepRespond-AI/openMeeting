// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_imports.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Follows uploaded import jobs until the server has transcribed them, independent of any
/// page (desktop `import.rs`): the meeting is marked in [MeetingSync] meanwhile and the
/// outcome is posted to [BackgroundNotices]. State = ids of the jobs being followed.

@ProviderFor(BackgroundImports)
final backgroundImportsProvider = BackgroundImportsProvider._();

/// Follows uploaded import jobs until the server has transcribed them, independent of any
/// page (desktop `import.rs`): the meeting is marked in [MeetingSync] meanwhile and the
/// outcome is posted to [BackgroundNotices]. State = ids of the jobs being followed.
final class BackgroundImportsProvider
    extends $NotifierProvider<BackgroundImports, Set<String>> {
  /// Follows uploaded import jobs until the server has transcribed them, independent of any
  /// page (desktop `import.rs`): the meeting is marked in [MeetingSync] meanwhile and the
  /// outcome is posted to [BackgroundNotices]. State = ids of the jobs being followed.
  BackgroundImportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundImportsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundImportsHash();

  @$internal
  @override
  BackgroundImports create() => BackgroundImports();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$backgroundImportsHash() => r'dbad8f819a5d01073a855569251fa5cb46c17663';

/// Follows uploaded import jobs until the server has transcribed them, independent of any
/// page (desktop `import.rs`): the meeting is marked in [MeetingSync] meanwhile and the
/// outcome is posted to [BackgroundNotices]. State = ids of the jobs being followed.

abstract class _$BackgroundImports extends $Notifier<Set<String>> {
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
