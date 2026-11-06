import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_models.freezed.dart';
part 'job_models.g.dart';

/// Wire values are the enum names. Unknown values map to [unknown].
enum JobKind { import, retranscribe, summary, unknown }

enum JobStatus {
  queued,
  running,
  completed,
  failed,
  cancelled,
  unknown;

  bool get isTerminal => this == completed || this == failed || this == cancelled;
}

/// Background job (API.md §1.5) — import / retranscription.
@freezed
abstract class Job with _$Job {
  const factory Job({
    required String id,
    @JsonKey(unknownEnumValue: JobKind.unknown) required JobKind kind,
    @JsonKey(unknownEnumValue: JobStatus.unknown) required JobStatus status,

    /// 0..100.
    @Default(0) int progress,
    String? message,
    @JsonKey(name: 'meeting_id') String? meetingId,
    String? error,
    int? segments,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
