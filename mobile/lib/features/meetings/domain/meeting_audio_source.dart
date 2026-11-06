import 'package:freezed_annotation/freezed_annotation.dart';

part 'meeting_audio_source.freezed.dart';

/// Where the meeting recording can be streamed from.
@freezed
sealed class MeetingAudioSource with _$MeetingAudioSource {
  /// Server redirected (302) to object storage: fetch [url] directly, never with Authorization.
  const factory MeetingAudioSource.redirect(Uri url) = MeetingAudioRedirect;

  /// Stream the API endpoint itself with [headers] (Bearer token; Range is added by the player).
  const factory MeetingAudioSource.direct(Uri url, Map<String, String> headers) =
      MeetingAudioDirect;

  /// The meeting has no recording.
  const factory MeetingAudioSource.none() = MeetingAudioNone;
}
