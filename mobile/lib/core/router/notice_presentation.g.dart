// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice_presentation.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(noticePresentation)
final noticePresentationProvider = NoticePresentationProvider._();

final class NoticePresentationProvider
    extends
        $FunctionalProvider<
          NoticePresentation,
          NoticePresentation,
          NoticePresentation
        >
    with $Provider<NoticePresentation> {
  NoticePresentationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noticePresentationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noticePresentationHash();

  @$internal
  @override
  $ProviderElement<NoticePresentation> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NoticePresentation create(Ref ref) {
    return noticePresentation(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoticePresentation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoticePresentation>(value),
    );
  }
}

String _$noticePresentationHash() =>
    r'f2f8128b04a78021d4a15f5b838f49e51ccc2f95';
