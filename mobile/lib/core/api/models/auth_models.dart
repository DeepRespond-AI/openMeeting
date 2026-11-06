import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// `User` (API.md §1.0). `phone` may be null for legacy users.
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    String? phone,
    required String name,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'last_login_at') DateTime? lastLoginAt,

    /// False for accounts created before passwords existed (SMS-code login only).
    @JsonKey(name: 'has_password') @Default(false) bool hasPassword,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// `GET /auth/config` — server-provided auth parameters.
@freezed
abstract class AuthConfig with _$AuthConfig {
  const factory AuthConfig({
    @JsonKey(name: 'registration_open') required bool registrationOpen,
    @JsonKey(name: 'sms_ready') required bool smsReady,
    @JsonKey(name: 'code_length') required int codeLength,
    @JsonKey(name: 'resend_interval_sec') required int resendIntervalSec,

    /// Password length limits; null on older servers (`AppConfig.auth` defaults apply).
    @JsonKey(name: 'password_min_length') int? passwordMinLength,
    @JsonKey(name: 'password_max_length') int? passwordMaxLength,
    @JsonKey(name: 'server_version') required String serverVersion,
  }) = _AuthConfig;

  factory AuthConfig.fromJson(Map<String, dynamic> json) => _$AuthConfigFromJson(json);
}

/// `purpose` of `POST /auth/sms/send`.
enum AuthPurpose {
  register('register'),
  login('login'),
  resetPassword('reset_password');

  const AuthPurpose(this.wire);

  /// Value sent to the server.
  final String wire;
}

/// Response of `POST /auth/sms/send`. [devCode] only on dev servers.
@freezed
abstract class SendCodeResult with _$SendCodeResult {
  const factory SendCodeResult({
    required bool sent,
    @JsonKey(name: 'resend_after_sec') required int resendAfterSec,
    @JsonKey(name: 'expires_in_sec') required int expiresInSec,
    @JsonKey(name: 'dev_code') String? devCode,
  }) = _SendCodeResult;

  factory SendCodeResult.fromJson(Map<String, dynamic> json) => _$SendCodeResultFromJson(json);
}

/// Response of register/login.
@freezed
abstract class AuthResult with _$AuthResult {
  const factory AuthResult({
    required String token,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
    required User user,
  }) = _AuthResult;

  factory AuthResult.fromJson(Map<String, dynamic> json) => _$AuthResultFromJson(json);
}

/// `ClientInfo` sent with login/register and (flattened) with the heartbeat.
@freezed
abstract class ClientInfo with _$ClientInfo {
  const factory ClientInfo({
    @JsonKey(name: 'client_id') required String clientId,
    required String hostname,

    /// `android` | `ios`.
    required String os,
    @JsonKey(name: 'app_version') required String appVersion,
  }) = _ClientInfo;

  factory ClientInfo.fromJson(Map<String, dynamic> json) => _$ClientInfoFromJson(json);
}
