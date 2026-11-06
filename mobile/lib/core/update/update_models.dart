import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_models.freezed.dart';
part 'update_models.g.dart';

/// A newer release offered by `GET /updates/check` (server/API.md §1.8). Exactly one of
/// [downloadUrl] (Android `direct` build) and [storeUrl] (store channel, iOS) is set.
@freezed
abstract class UpdateOffer with _$UpdateOffer {
  const factory UpdateOffer({
    required String id,
    required String version,
    @Default(0) int build,
    @JsonKey(name: 'full_version') required String fullVersion,
    @Default('') String notes,
    @JsonKey(name: 'pub_date') String? pubDate,

    /// Must be installed before the app can be used.
    @Default(false) bool force,
    int? size,
    String? sha256,
    @JsonKey(name: 'download_url') String? downloadUrl,
    @JsonKey(name: 'store_url') String? storeUrl,
  }) = _UpdateOffer;

  factory UpdateOffer.fromJson(Map<String, dynamic> json) => _$UpdateOfferFromJson(json);
}

@freezed
abstract class UpdateCheckResult with _$UpdateCheckResult {
  const factory UpdateCheckResult({
    UpdateOffer? update,
    @JsonKey(name: 'min_version') String? minVersion,
  }) = _UpdateCheckResult;

  factory UpdateCheckResult.fromJson(Map<String, dynamic> json) =>
      _$UpdateCheckResultFromJson(json);
}
