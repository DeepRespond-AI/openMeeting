// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting_record_notices.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(meetingRecordNotices)
final meetingRecordNoticesProvider = MeetingRecordNoticesProvider._();

final class MeetingRecordNoticesProvider
    extends
        $FunctionalProvider<
          AsyncValue<MeetingRecordNotice>,
          MeetingRecordNotice,
          Stream<MeetingRecordNotice>
        >
    with
        $FutureModifier<MeetingRecordNotice>,
        $StreamProvider<MeetingRecordNotice> {
  MeetingRecordNoticesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meetingRecordNoticesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meetingRecordNoticesHash();

  @$internal
  @override
  $StreamProviderElement<MeetingRecordNotice> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<MeetingRecordNotice> create(Ref ref) {
    return meetingRecordNotices(ref);
  }
}

String _$meetingRecordNoticesHash() =>
    r'c03987ff601b679c0643cefd296fa11a8148dcc3';
