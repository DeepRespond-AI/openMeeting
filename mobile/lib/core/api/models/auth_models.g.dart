// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  phone: json['phone'] as String?,
  name: json['name'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  lastLoginAt: json['last_login_at'] == null
      ? null
      : DateTime.parse(json['last_login_at'] as String),
  hasPassword: json['has_password'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
  'name': instance.name,
  'created_at': instance.createdAt?.toIso8601String(),
  'last_login_at': instance.lastLoginAt?.toIso8601String(),
  'has_password': instance.hasPassword,
};

_AuthConfig _$AuthConfigFromJson(Map<String, dynamic> json) => _AuthConfig(
  registrationOpen: json['registration_open'] as bool,
  smsReady: json['sms_ready'] as bool,
  codeLength: (json['code_length'] as num).toInt(),
  resendIntervalSec: (json['resend_interval_sec'] as num).toInt(),
  passwordMinLength: (json['password_min_length'] as num?)?.toInt(),
  passwordMaxLength: (json['password_max_length'] as num?)?.toInt(),
  serverVersion: json['server_version'] as String,
);

Map<String, dynamic> _$AuthConfigToJson(_AuthConfig instance) =>
    <String, dynamic>{
      'registration_open': instance.registrationOpen,
      'sms_ready': instance.smsReady,
      'code_length': instance.codeLength,
      'resend_interval_sec': instance.resendIntervalSec,
      'password_min_length': instance.passwordMinLength,
      'password_max_length': instance.passwordMaxLength,
      'server_version': instance.serverVersion,
    };

_SendCodeResult _$SendCodeResultFromJson(Map<String, dynamic> json) =>
    _SendCodeResult(
      sent: json['sent'] as bool,
      resendAfterSec: (json['resend_after_sec'] as num).toInt(),
      expiresInSec: (json['expires_in_sec'] as num).toInt(),
      devCode: json['dev_code'] as String?,
    );

Map<String, dynamic> _$SendCodeResultToJson(_SendCodeResult instance) =>
    <String, dynamic>{
      'sent': instance.sent,
      'resend_after_sec': instance.resendAfterSec,
      'expires_in_sec': instance.expiresInSec,
      'dev_code': instance.devCode,
    };

_AuthResult _$AuthResultFromJson(Map<String, dynamic> json) => _AuthResult(
  token: json['token'] as String,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  user: User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthResultToJson(_AuthResult instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'user': instance.user.toJson(),
    };

_ClientInfo _$ClientInfoFromJson(Map<String, dynamic> json) => _ClientInfo(
  clientId: json['client_id'] as String,
  hostname: json['hostname'] as String,
  os: json['os'] as String,
  appVersion: json['app_version'] as String,
);

Map<String, dynamic> _$ClientInfoToJson(_ClientInfo instance) =>
    <String, dynamic>{
      'client_id': instance.clientId,
      'hostname': instance.hostname,
      'os': instance.os,
      'app_version': instance.appVersion,
    };
