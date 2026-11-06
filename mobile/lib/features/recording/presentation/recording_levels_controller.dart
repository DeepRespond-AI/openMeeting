import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config_provider.dart';

part 'recording_levels_controller.g.dart';

/// Recent input levels (0..1, oldest first) for the live waveform; length is
/// `AppConfig.recording.waveformBars`. Fed by `RecordingController`.
@Riverpod(keepAlive: true)
class RecordingLevelsController extends _$RecordingLevelsController {
  @override
  List<double> build() =>
      List<double>.filled(ref.watch(appConfigProvider.select((c) => c.recording.waveformBars)), 0);

  void push(double level) {
    if (state.isEmpty) return;
    state = [...state.skip(1), level.clamp(0.0, 1.0)];
  }

  void clear() => state = List<double>.filled(state.length, 0);
}
