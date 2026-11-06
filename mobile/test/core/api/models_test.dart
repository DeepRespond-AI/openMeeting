import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/models/models.dart';

void main() {
  test('User / AuthResult / SendCodeResult', () {
    final result = AuthResult.fromJson({
      'token': 'ms_abc',
      'expires_at': '2026-11-06T03:59:35Z',
      'user': {
        'id': 'u1',
        'phone': '13800138000',
        'name': '张三',
        'created_at': '2026-10-07T03:59:35Z',
        'last_login_at': null,
      },
    });
    expect(result.user.name, '张三');
    expect(result.expiresAt, DateTime.utc(2026, 11, 6, 3, 59, 35));
    expect(result.user.lastLoginAt, isNull);

    expect(
      SendCodeResult.fromJson({'sent': true, 'resend_after_sec': 60, 'expires_in_sec': 300})
          .devCode,
      isNull,
    );
    expect(
      SendCodeResult.fromJson({
        'sent': true,
        'resend_after_sec': 60,
        'expires_in_sec': 300,
        'dev_code': '123456',
      }).devCode,
      '123456',
    );
  });

  test('ClientInfo serializes with API field names', () {
    const info = ClientInfo(
      clientId: 'c1',
      hostname: 'Pixel 9',
      os: 'android',
      appVersion: '1.0.0+1',
    );
    expect(info.toJson(), {
      'client_id': 'c1',
      'hostname': 'Pixel 9',
      'os': 'android',
      'app_version': '1.0.0+1',
    });
  });

  test('AuthConfig', () {
    final c = AuthConfig.fromJson({
      'registration_open': true,
      'sms_ready': false,
      'code_length': 6,
      'resend_interval_sec': 60,
      'server_version': '1.0.0',
    });
    expect(c.codeLength, 6);
    expect(c.smsReady, isFalse);
  });

  test('Capabilities with unconfigured engines', () {
    final caps = Capabilities.fromJson({
      'server_version': '1.0.0',
      'user': {'id': 'u1', 'name': '张三', 'phone': '13800138000'},
      'stt': {'engine': null, 'model': null, 'ready': false, 'error': null},
      'llm': {'name': '百炼', 'model': 'qwen-plus', 'ready': true, 'error': null},
    });
    expect(caps.stt.ready, isFalse);
    expect(caps.llm.model, 'qwen-plus');
  });

  test('meetings and transcripts', () {
    final meta = MeetingMetadata.fromJson({
      'id': 'meeting-1',
      'title': '会议',
      'created_at': '2026-10-07T03:59:35Z',
      'updated_at': '2026-10-07T03:59:35Z',
      'folder_path': null,
      'has_audio': true,
      'audio_duration': 12.5,
    });
    expect(meta.hasAudio, isTrue);
    expect(meta.audioDuration, 12.5);

    final page = PaginatedTranscripts.fromJson({
      'transcripts': [
        {
          'id': 't1',
          'text': '你好',
          'timestamp': '2026-10-07T03:59:35Z',
          'audio_start_time': 0,
          'audio_end_time': 1.5,
        },
        {'id': 't2', 'text': '世界', 'timestamp': '2026-10-07T03:59:36Z'},
      ],
      'total_count': 2,
      'has_more': false,
    });
    expect(page.transcripts.first.audioStartTime, 0);
    expect(page.transcripts.last.duration, isNull);

    final search = TranscriptSearchResult.fromJson({
      'id': 'meeting-1',
      'title': '会议',
      'matchContext': '...你好...',
      'timestamp': '2026-10-07T03:59:35Z',
    });
    expect(search.matchContext, '...你好...');

    expect(SegmentResult.fromJson({'id': null, 'text': '', 'confidence': null, 'seq': 3}).seq, 3);
  });

  test('Job with unknown status falls back', () {
    final job = Job.fromJson({
      'id': 'job-1',
      'kind': 'import',
      'status': 'paused',
      'progress': 40,
      'message': null,
      'meeting_id': 'meeting-1',
      'error': null,
      'segments': null,
      'created_at': '2026-10-07T03:59:35Z',
      'updated_at': '2026-10-07T03:59:35Z',
    });
    expect(job.kind, JobKind.import);
    expect(job.status, JobStatus.unknown);
    expect(JobStatus.completed.isTerminal, isTrue);
  });

  test('SummaryResponse keeps raw start and arbitrary data', () {
    final s = SummaryResponse.fromJson({
      'status': 'processing',
      'meetingName': '会议',
      'meeting_id': 'meeting-1',
      'start': '2026-10-07T03:59:35.123456789Z',
      'end': null,
      'data': {'markdown': '# 标题'},
      'error': null,
    });
    expect(s.status.isInProgress, isTrue);
    expect(s.start, '2026-10-07T03:59:35.123456789Z');
    expect((s.data! as Map<String, dynamic>)['markdown'], '# 标题');
    expect(SummaryResponse.fromJson({'status': 'weird'}).status, SummaryStatus.unknown);
    expect(ProcessStarted.fromJson({'message': 'ok', 'process_id': 'p1'}).processId, 'p1');
  });

  test('MeetingSummary reads list timestamps and tolerates older servers', () {
    final withDates = MeetingSummary.fromJson({
      'id': 'meeting-1',
      'title': 'Standup',
      'created_at': '2026-10-07T05:00:00Z',
      'updated_at': '2026-10-07T05:30:00Z',
    });
    expect(withDates.createdAt, DateTime.utc(2026, 10, 7, 5));
    final legacy = MeetingSummary.fromJson({'id': 'meeting-2', 'title': 'Old'});
    expect(legacy.createdAt, isNull);
  });
}
