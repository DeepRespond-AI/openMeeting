// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateOffer _$UpdateOfferFromJson(Map<String, dynamic> json) => _UpdateOffer(
  id: json['id'] as String,
  version: json['version'] as String,
  build: (json['build'] as num?)?.toInt() ?? 0,
  fullVersion: json['full_version'] as String,
  notes: json['notes'] as String? ?? '',
  pubDate: json['pub_date'] as String?,
  force: json['force'] as bool? ?? false,
  size: (json['size'] as num?)?.toInt(),
  sha256: json['sha256'] as String?,
  downloadUrl: json['download_url'] as String?,
  storeUrl: json['store_url'] as String?,
);

Map<String, dynamic> _$UpdateOfferToJson(_UpdateOffer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'version': instance.version,
      'build': instance.build,
      'full_version': instance.fullVersion,
      'notes': instance.notes,
      'pub_date': instance.pubDate,
      'force': instance.force,
      'size': instance.size,
      'sha256': instance.sha256,
      'download_url': instance.downloadUrl,
      'store_url': instance.storeUrl,
    };

_UpdateCheckResult _$UpdateCheckResultFromJson(Map<String, dynamic> json) =>
    _UpdateCheckResult(
      update: json['update'] == null
          ? null
          : UpdateOffer.fromJson(json['update'] as Map<String, dynamic>),
      minVersion: json['min_version'] as String?,
    );

Map<String, dynamic> _$UpdateCheckResultToJson(_UpdateCheckResult instance) =>
    <String, dynamic>{
      'update': instance.update?.toJson(),
      'min_version': instance.minVersion,
    };
