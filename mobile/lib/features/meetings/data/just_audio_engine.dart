import 'package:just_audio/just_audio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/audio_playback.dart';

part 'just_audio_engine.g.dart';

/// [AudioPlaybackEngine] backed by `just_audio` (streams with HTTP headers and Range).
///
/// Headers are sent natively (ExoPlayer request properties / AVURLAsset header fields)
/// instead of through just_audio's cleartext localhost proxy.
class JustAudioPlaybackEngine implements AudioPlaybackEngine {
  final AudioPlayer _player = AudioPlayer(useProxyForRequestHeaders: false);

  @override
  Future<Duration?> load(Uri url, {Map<String, String>? headers}) =>
      _player.setAudioSource(AudioSource.uri(url, headers: headers));

  @override
  Future<void> play() async {
    // just_audio's play() completes when playback stops; do not await it.
    _player.play().ignore();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<bool> get playingStream => _player.playingStream;

  @override
  Stream<void> get completedStream =>
      _player.processingStateStream.where((s) => s == ProcessingState.completed).map((_) {});

  @override
  Future<void> dispose() => _player.dispose();
}

/// Creates a new player per meeting page. Override in tests with a fake factory.
@riverpod
AudioPlaybackEngine Function() audioPlaybackEngineFactory(Ref ref) => JustAudioPlaybackEngine.new;
