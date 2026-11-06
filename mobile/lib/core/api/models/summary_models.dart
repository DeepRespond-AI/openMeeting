import 'package:freezed_annotation/freezed_annotation.dart';

part 'summary_models.freezed.dart';
part 'summary_models.g.dart';

/// Summary status. `pending` and `processing` both mean "in progress".
enum SummaryStatus {
  idle,
  pending,
  processing,
  completed,
  failed,
  cancelled,
  error,
  unknown;

  bool get isInProgress => this == pending || this == processing;
  bool get isTerminal => this == completed || this == failed || this == cancelled || this == error;
}

/// `GET /meetings/{id}/summary` — mirrors the desktop `api_get_summary` JSON.
///
/// [start]/[end] are kept as raw RFC 3339 strings ([start] identifies the run and is
/// compared verbatim to drop stale poll responses). [data] is the arbitrary summary JSON.
@freezed
abstract class SummaryResponse with _$SummaryResponse {
  const factory SummaryResponse({
    @JsonKey(unknownEnumValue: SummaryStatus.unknown) required SummaryStatus status,
    String? meetingName,
    @JsonKey(name: 'meeting_id') String? meetingId,
    String? start,
    String? end,
    Object? data,
    String? error,
  }) = _SummaryResponse;

  factory SummaryResponse.fromJson(Map<String, dynamic> json) => _$SummaryResponseFromJson(json);
}

/// `202` response of `POST /meetings/{id}/summary`.
@freezed
abstract class ProcessStarted with _$ProcessStarted {
  const factory ProcessStarted({
    required String message,
    @JsonKey(name: 'process_id') required String processId,
  }) = _ProcessStarted;

  factory ProcessStarted.fromJson(Map<String, dynamic> json) => _$ProcessStartedFromJson(json);
}

/// `GET/PUT /meetings/{id}/summary-language`.
@freezed
abstract class SummaryLanguage with _$SummaryLanguage {
  const factory SummaryLanguage({
    String? language,
    @JsonKey(name: 'detected_language') String? detectedLanguage,
  }) = _SummaryLanguage;

  factory SummaryLanguage.fromJson(Map<String, dynamic> json) => _$SummaryLanguageFromJson(json);
}
