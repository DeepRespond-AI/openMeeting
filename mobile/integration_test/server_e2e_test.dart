// End-to-end test against a real dev server, run on an emulator/device:
//
//   flutter test integration_test/server_e2e_test.dart -d <device> \
//     --dart-define=APP_ENV=dev --dart-define=E2E_ADMIN_PASSWORD=<admin password>
//
// The server must run in dev mode (SMS codes are returned as `dev_code`) at the dev config's
// `defaultServerUrl` (http://10.0.2.2:8000 from the Android emulator), with an active STT model
// and LLM provider. Real native code is exercised (AAC encoder, secure storage, path_provider);
// only the microphone is replaced by a source that plays a recorded Chinese speech clip.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meeting/core/api/models/models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/app_enums.dart';
import 'package:meeting/core/config/settings_store.dart';
import 'package:meeting/features/import/data/jobs_repository_impl.dart';
import 'package:meeting/features/import/domain/jobs_repository.dart';
import 'package:meeting/features/meetings/data/meetings_repository_impl.dart';
import 'package:meeting/features/recording/data/audio_sources.dart';
import 'package:meeting/features/recording/data/recording_background_impl.dart';
import 'package:meeting/features/recording/data/recording_storage.dart';
import 'package:meeting/features/recording/domain/recording_state.dart';
import 'package:meeting/features/recording/presentation/recording_controller.dart';
import 'package:meeting/features/summary/domain/summary_state.dart';
import 'package:meeting/features/summary/presentation/summary_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/features/recording/fakes.dart';
import 'speech_fixture.dart';

const _adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');

/// "budget" in Simplified or Traditional characters.
final _budget = RegExp('预算|預算');

/// Polls [read] until [done] accepts its value, failing after [timeout].
Future<T> waitFor<T>(T Function() read, bool Function(T) done, {required Duration timeout}) async {
  final deadline = DateTime.now().add(timeout);
  while (true) {
    final value = read();
    if (done(value)) return value;
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting; last value: $value');
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppConfig config;
  late ProviderContainer c;
  final mic = FakeAudioSource();

  setUpAll(() async {
    expect(_adminPassword, isNotEmpty, reason: 'pass --dart-define=E2E_ADMIN_PASSWORD');
    config = await loadAppConfig();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
        audioSourceProvider(RecordingSource.microphone).overrideWithValue(mic),
        recordingBackgroundProvider.overrideWithValue(FakeBackground()),
      ],
    );
  });

  tearDownAll(() => c.dispose());

  late User user;
  late String recordedMeetingId;

  testWidgets('register with phone + SMS code (dev mode)', (_) async {
    final session = c.read(sessionControllerProvider.notifier);
    await c.read(sessionControllerProvider.future);
    // The dev config points at the host's dev server.
    final authConfig = await session.fetchAuthConfig();
    expect(authConfig.registrationOpen, isTrue);

    final phone = '139${(10000000 + Random().nextInt(89999999)).toString()}';
    final sent = await session.sendCode(phone, AuthPurpose.register);
    expect(sent.devCode, isNotNull, reason: 'server must run with OPENMEETING_ENV=dev');
    user = await session.register(phone, sent.devCode!, 'E2E 测试', 'E2eTest2026');
    expect(c.read(sessionControllerProvider).value, isA<AuthSignedIn>());
  });

  testWidgets('record: VAD segments are transcribed live, AAC is encoded natively and uploaded', (
    _,
  ) async {
    final controller = c.read(recordingControllerProvider.notifier);
    await controller.start();
    final active = c.read(recordingControllerProvider);
    expect(active, isA<RecordingActive>());

    // Feed the clip in 100 ms chunks (roughly real time keeps the native encoder honest).
    final pcm = base64Decode(speechPcm16Base64);
    final chunk = config.audio.sampleRate * 2 ~/ 10;
    for (var i = 0; i < pcm.length; i += chunk) {
      mic.emitFrame(Uint8List.sublistView(pcm, i, min(i + chunk, pcm.length)));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final withText = await waitFor(
      () => c.read(recordingControllerProvider),
      (s) => (s.session?.transcripts.where((t) => t.text.trim().isNotEmpty).length ?? 0) > 0,
      timeout: const Duration(seconds: 60),
    );
    final live = withText.session!.transcripts.map((t) => t.text).join();
    debugPrint('live transcript: $live');
    // Auto language detection with Whisper may answer in Traditional characters.
    expect(live, matches(_budget));

    await controller.stop();
    final done = await waitFor(
      () => c.read(recordingControllerProvider),
      (s) => s is RecordingDone || s is RecordingError,
      timeout: const Duration(seconds: 90),
    );
    expect(done, isA<RecordingDone>(), reason: '$done');
    recordedMeetingId = (done as RecordingDone).meetingId;

    final meta = await c.read(meetingsRepositoryProvider).getMetadata(recordedMeetingId);
    expect(meta.hasAudio, isTrue);
    expect(meta.audioDuration, greaterThan(10));
  });

  testWidgets('AI summary: generate and poll until ready', (_) async {
    final provider = summaryControllerProvider(recordedMeetingId);
    // Auto-dispose provider: keep it alive like the summary tab does while it's on screen.
    final sub = c.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await c.read(provider.future);
    await c.read(provider.notifier).generate();
    final state = await waitFor(
      () => c.read(provider).value,
      (s) => s is SummaryReady || s is SummaryFailed,
      timeout: const Duration(seconds: 90),
    );
    expect(state, isA<SummaryReady>(), reason: '$state');
    // The server picks the template and strips the leading title (it may rename the meeting from it).
    final summary = (state! as SummaryReady).summary;
    expect(summary.content.trim(), isNotEmpty);
  });

  testWidgets('import the locally kept m4a and transcribe it on the server', (_) async {
    final dir = await c.read(recordingStorageProvider).recordingsDir();
    final file = File('${dir.path}/$recordedMeetingId.${config.recording.audioFileExtension}');
    expect(file.existsSync(), isTrue, reason: 'keepLocalAudio keeps the recording');

    final jobs = c.read(jobsRepositoryProvider);
    var job = await jobs.startImport(
      ImportUpload(filePath: file.path, fileName: 'e2e.m4a', title: 'E2E 导入'),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 120));
    while (!job.status.isTerminal && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(config.polling.jobInterval);
      job = await jobs.getJob(job.id);
    }
    expect(job.status, JobStatus.completed, reason: '${job.error} ${job.message}');
    final page = await c
        .read(meetingsRepositoryProvider)
        .getTranscripts(job.meetingId!, offset: 0, limit: 50);
    expect(page.transcripts.map((t) => t.text).join(), matches(_budget));
  });

  testWidgets('forced logout by the admin → session expires on the next request', (_) async {
    final admin = Dio(BaseOptions(baseUrl: config.defaultServerUrl));
    final login = await admin.post<Map<String, dynamic>>(
      '/admin/api/login',
      data: {'password': _adminPassword},
    );
    final adminAuth = Options(headers: {'Authorization': 'Bearer ${login.data!['token']}'});
    await admin.delete<void>('/admin/api/users/${user.id}/sessions', options: adminAuth);

    await expectLater(c.read(meetingsRepositoryProvider).listMeetings(), throwsA(anything));
    await waitFor(
      () => c.read(sessionControllerProvider).value,
      (s) => s is AuthExpired,
      timeout: const Duration(seconds: 10),
    );
  });
}
