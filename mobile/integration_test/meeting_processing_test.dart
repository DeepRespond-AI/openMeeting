// Native Android detail UI and real HTTP to the shared desktop acceptance fixture.
// Business/RTC/model output is deterministic; this is not real media acceptance.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/meetings/presentation/meeting_detail_page.dart';

import '../test/helpers/test_config.dart';

class ProcessingSession extends SessionController {
  @override
  Future<AuthState> build() async =>
      const AuthState.signedIn(User(id: 'mobile-member', name: '移动成员'));
}

class ProcessingAdapter implements HttpClientAdapter {
  ProcessingAdapter(this.bridge);
  final Dio bridge;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await bridge.post<Map<String, dynamic>>(
      '/rpc',
      data: {'path': options.uri.path, 'method': options.method, 'query': options.queryParameters},
    );
    final data = response.data!;
    return ResponseBody.fromString(
      jsonEncode(data['body']),
      data['status'] as int,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android and desktop meeting processing state', (t) async {
    final bridge = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39348'));
    bridge.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..findProxy = (_) => 'DIRECT',
    );
    final config = await loadAppConfig();
    final api = Dio()..httpClientAdapter = ProcessingAdapter(bridge);
    final c = await createTestContainer(
      config: config,
      overrides: [
        sessionControllerProvider.overrideWith(ProcessingSession.new),
        apiClientProvider.overrideWithValue(api),
      ],
    );
    await c.read(sessionControllerProvider.future);
    await bridge.get<void>('/ready');
    final l = lookupAppLocalizations(const Locale('zh'));
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MeetingDetailPage(meetingId: 'meeting-shared-record'),
        ),
      ),
    );
    Future<void> wait(Finder finder) async {
      final end = DateTime.now().add(const Duration(seconds: 18));
      while (finder.evaluate().isEmpty) {
        if (DateTime.now().isAfter(end)) throw StateError('Android state timed out: $finder');
        await t.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final error = t.takeException();
        if (error != null) throw StateError('$error');
      }
    }

    for (final capture in [false, true]) {
      for (final state in ['queued', 'running', 'completed', 'failed']) {
        final row = <String, Object?>{
          'platform': 'android-emulator',
          'phase': capture ? 'screenshots' : 'assertions',
          'operation': '共享会议-$state',
          'expected': '移动与桌面同一任务状态，打开记录不下载音频',
          'pass': false,
          'screenshot': null,
        };
        try {
          await bridge.post<void>('/advance', data: {'status': state, 'capture': capture});
          await wait(find.text(l.meetingsTabTranscript));
          await t.tap(find.text(l.meetingsTabTranscript));
          await t.pump();
          final expected = state == 'completed'
              ? find.textContaining('第 1 条转写')
              : find.text(
                  state == 'failed'
                      ? l.meetingsTranscriptProcessingFailed
                      : l.meetingsTranscriptProcessing,
                );
          await wait(expected);
          expect(find.text(l.meetingsTranscriptEmptyHint), findsNothing);
          final error = t.takeException();
          if (error != null) throw StateError('$error');
          row['actual'] = '$state: native Android transcript state visible; desktop matched';
          row['pass'] = true;
          if (capture) {
            await t.pump(const Duration(milliseconds: 400));
            row['screenshot'] = 'screenshots/android-$state.png';
            await bridge.post<void>('/shot', data: {'name': 'android-$state'});
          }
        } catch (e) {
          row['actual'] = '$e';
          rethrow;
        } finally {
          await bridge.post<void>('/row', data: row);
        }
      }
    }
    await bridge.post<void>('/done');
    await t.pumpWidget(const SizedBox.shrink());
    api.close();
    bridge.close();
  });
}
