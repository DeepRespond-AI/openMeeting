import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/meetings/data/just_audio_engine.dart';
import 'package:meeting/features/meetings/data/meetings_repository_impl.dart';
import 'package:meeting/features/meetings/domain/audio_playback.dart';
import 'package:meeting/features/meetings/domain/meetings_repository.dart';
import 'package:meeting/features/meetings/presentation/meeting_detail_controller.dart';
import 'package:meeting/features/meetings/presentation/meeting_player_controller.dart';
import 'package:meeting/features/meetings/presentation/widgets/transcript_list.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_config.dart';

class EmptyTranscripts extends TranscriptsController {
  @override
  Future<TranscriptsState> build(String meetingId) async => const TranscriptsState();
}

class NoAudioFetch extends Mock implements MeetingsRepository {}

class TestPlayback extends Fake implements AudioPlaybackEngine {
  Uri? loaded;
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<void> get completedStream => const Stream.empty();
  @override
  Future<void> dispose() async {}
  @override
  Future<void> setSpeed(double value) async {}
  @override
  Future<Duration?> load(Uri url, {Map<String, String>? headers}) async {
    loaded = url;
    return const Duration(seconds: 1);
  }
}

void main() {
  for (final status in [null, 'queued', 'running', 'failed', 'cancelled', 'completed']) {
    testWidgets('empty transcript under $status', (t) async {
      final c = await createTestContainer(
        overrides: [transcriptsControllerProvider.overrideWith2((_) => EmptyTranscripts())],
      );
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TranscriptList(meetingId: 'record', recordingStatus: status),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump();
      final l = lookupAppLocalizations(const Locale('zh'));
      expect(
        find.text(l.meetingsTranscriptEmptyHint),
        status == 'completed' ? findsOneWidget : findsNothing,
      );
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
  test(
    'opening player never fetches audio; explicit local download loads without cloud refetch',
    () async {
      final repo = NoAudioFetch(), engine = TestPlayback();
      final c = await createTestContainer(
        overrides: [
          meetingsRepositoryProvider.overrideWithValue(repo),
          audioPlaybackEngineFactoryProvider.overrideWithValue(() => engine),
        ],
      );
      final provider = meetingPlayerControllerProvider('record');
      final sub = c.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(provider).status, PlayerStatus.idle);
      verifyNever(() => repo.resolveAudio('record'));
      final file = Uri.file('record.wav');
      await c.read(provider.notifier).load(localFile: file);
      expect(engine.loaded, file);
      expect(c.read(provider).status, PlayerStatus.ready);
      verifyNever(() => repo.resolveAudio('record'));
    },
  );
}
