import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_models.freezed.dart';
part 'client_models.g.dart';

/// `GET /client/capabilities` (API.md §1.1).
@freezed
abstract class Capabilities with _$Capabilities {
  const factory Capabilities({
    @JsonKey(name: 'server_version') required String serverVersion,
    CapabilityUser? user,
    required SttStatus stt,
    required LlmStatus llm,
  }) = _Capabilities;

  factory Capabilities.fromJson(Map<String, dynamic> json) => _$CapabilitiesFromJson(json);
}

@freezed
abstract class CapabilityUser with _$CapabilityUser {
  const factory CapabilityUser({required String id, String? name, String? phone}) = _CapabilityUser;

  factory CapabilityUser.fromJson(Map<String, dynamic> json) => _$CapabilityUserFromJson(json);
}

/// Speech-to-text engine state. `engine`/`model` are null when nothing is configured.
@freezed
abstract class SttStatus with _$SttStatus {
  const factory SttStatus({String? engine, String? model, required bool ready, String? error}) =
      _SttStatus;

  factory SttStatus.fromJson(Map<String, dynamic> json) => _$SttStatusFromJson(json);
}

/// LLM provider state. `name`/`model` are null when nothing is configured.
@freezed
abstract class LlmStatus with _$LlmStatus {
  const factory LlmStatus({String? name, String? model, required bool ready, String? error}) =
      _LlmStatus;

  factory LlmStatus.fromJson(Map<String, dynamic> json) => _$LlmStatusFromJson(json);
}

/// Response of `POST /client/heartbeat`.
@freezed
abstract class HeartbeatResult with _$HeartbeatResult {
  const factory HeartbeatResult({
    @JsonKey(name: 'server_time') String? serverTime,
    @JsonKey(name: 'server_version') String? serverVersion,
  }) = _HeartbeatResult;

  factory HeartbeatResult.fromJson(Map<String, dynamic> json) => _$HeartbeatResultFromJson(json);
}
