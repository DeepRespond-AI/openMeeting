import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_enums.dart';
import '../../../core/config/settings_controller.dart';

part 'recording_options_controller.freezed.dart';
part 'recording_options_controller.g.dart';

/// Choices made on the recording page before starting (defaults from the user settings).
@freezed
abstract class RecordingOptions with _$RecordingOptions {
  const factory RecordingOptions({
    required RecordingSource source,

    /// Language code; `auto` = server detects.
    required String language,
  }) = _RecordingOptions;
}

/// Per-recording source/language selection. Starts from the effective settings and follows
/// them until the user picks something on the recording page.
@Riverpod(keepAlive: true)
class RecordingOptionsController extends _$RecordingOptionsController {
  @override
  RecordingOptions build() {
    final settings = ref.watch(effectiveSettingsProvider);
    return RecordingOptions(
      source: settings.defaultRecordingSource,
      language: settings.transcriptionLanguage,
    );
  }

  void setSource(RecordingSource source) => state = state.copyWith(source: source);

  void setLanguage(String language) => state = state.copyWith(language: language);
}
