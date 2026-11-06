import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/config/app_enums.dart';
import '../domain/audio_source.dart';
import 'mic_audio_source.dart';
import 'system_audio_source.dart';

part 'audio_sources.g.dart';

/// The capture source for [kind]. The recording controller invalidates it after every
/// recording (which stops it), so each recording gets a fresh instance.
@Riverpod(keepAlive: true)
AudioSource audioSource(Ref ref, RecordingSource kind) {
  final config = ref.watch(appConfigProvider);
  final source = switch (kind) {
    RecordingSource.microphone => MicAudioSource(
      levelFloorDb: config.audio.levelFloorDb,
      levelInterval: config.audio.levelUpdateInterval,
    ),
    // Notification / broadcast texts follow the device locale inside the plugin.
    RecordingSource.system => SystemAudioSource(config: config),
  };
  ref.onDispose(source.stop);
  return source;
}

/// Whether [kind] can be offered on this device (feature flag + OS support/permission).
@riverpod
Future<AudioSourceAvailability> audioSourceAvailability(Ref ref, RecordingSource kind) async {
  final config = ref.watch(appConfigProvider);
  if (kind == RecordingSource.system && !config.features.systemAudioCapture) {
    return AudioSourceAvailability.unsupported;
  }
  return ref.watch(audioSourceProvider(kind)).availability();
}
