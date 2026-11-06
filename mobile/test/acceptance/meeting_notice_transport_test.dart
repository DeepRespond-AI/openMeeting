import 'dart:convert';
import 'dart:io';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im/io.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/im_gateway.dart';
import 'package:meeting/core/im/meeting_record_notices.dart';

import '../helpers/test_config.dart';
import 'support/real_backend.dart' show RealNetwork;

void main() {
  if (Platform.environment['MOBILE_AUTO_RECORDS_NOTICES'] != '1') return;
  TestWidgetsFlutterBinding.ensureInitialized();
  test('real business outbox to real SDK record notifications', () async {
    final out = Directory('../.artifacts/mobile-auto-records');
    final budget = jsonDecode(File('${out.path}/e2e-budget.json').readAsStringSync()) as Map;
    if (DateTime.now().difference(DateTime.parse(budget['firstAttempt'] as String)).inMinutes >=
        30) {
      throw StateError('E2E budget exhausted');
    }
    HttpOverrides.global = RealNetwork();
    final bridge = Dio();
    final session = (await bridge.get<Map<String, dynamic>>('http://127.0.0.1:39331/session'))
        .data!;
    final config = loadConfigWithServer('http://127.0.0.1:39330');
    final c = await createTestContainer(
      config: config,
      secure: {
        'session.token': session['token'] as String,
        'session.user': jsonEncode(session['user']),
        'session.serverUrl': config.defaultServerUrl,
      },
      overrides: [
        imPlatformProvider.overrideWithValue(
          IoPlatform(
            dataDir: Directory('.dart_tool/auto-records-notices-im').absolute.path,
            platformName: 'windows',
            database: const DefaultDatabaseOpener(background: false),
          ),
        ),
      ],
    );
    await c.read(sessionControllerProvider.future);
    final notices = <MeetingRecordNotice>[], raw = <Map<String, Object?>>[];
    final sub = c.listen(meetingRecordNoticesProvider, (_, next) {
      if (next.asData?.value case final notice?) notices.add(notice);
    });
    final row = <String, Object?>{
      'action': '真实IM会后通知',
      'expected': '结束及处理失败通知经真实平台到达生产过滤器',
      'passed': false,
    };
    String? id;
    try {
      final client = await c.read(imClientProvider.future);
      final incoming = client.on<MessageReceived>().listen((event) {
        raw.add({
          'type': event.message.type,
          'sender': event.message.sender,
          'kind': event.message.body?['kind'],
          'event': event.message.body?['event'],
          'recalled': event.message.recalled != null,
        });
      });
      try {
        final api = c.read(apiClientProvider);
        final created = (await api.post<Map<String, dynamic>>(
          '/api/v1/rooms',
          data: {'title': '真实通知验收'},
        )).data!;
        id = created['id'] as String;
        await api.post<void>(
          '/api/v1/rooms/$id/recording/chunks',
          data: {
            'chunkId': 'notice-${DateTime.now().millisecondsSinceEpoch}',
            'participantId': created['hostId'],
            'epoch': (created['recording'] as Map)['epoch'],
            'startTime': 0,
            'pcm': base64Encode(List.filled(16000, 0)),
          },
        );
        final ended = (await api.post<Map<String, dynamic>>(
          '/api/v1/rooms/$id/end',
          data: {},
        )).data!;
        final meeting = ended['meetingId'];
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (DateTime.now().isBefore(deadline) &&
            !notices.any((n) => n.meetingId == meeting && n.event == 'processing_failed')) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        final events = notices.where((n) => n.meetingId == meeting).map((n) => n.event).toList();
        row['actual'] = {'events': events, 'receivedFrameTypes': raw, 'syntheticInput': true};
        expect(events, contains('meeting_ended'));
        expect(events, contains('processing_failed'));
        row['passed'] = true;
      } finally {
        await incoming.cancel();
      }
    } on Object catch (error) {
      row['error'] = error.toString();
      rethrow;
    } finally {
      File('${out.path}/notice-results.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert([row]));
      // ignore: avoid_print
      print(jsonEncode(row));
      if (id != null) {
        try {
          await c.read(apiClientProvider).post<void>('/api/v1/rooms/$id/end', data: {});
        } catch (_) {}
      }
      sub.close();
      await c.read(imGatewayProvider).logout();
      bridge.close();
      HttpOverrides.global = null;
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
