import '../l10n/l10n.dart';
import 'api_exception.dart';

/// User-facing text for an [ApiException]: the server `detail` when present (already
/// Chinese, never translated), else a localized message for the error kind.
///
/// ```dart
/// } on ApiException catch (e) {
///   showSnackBar(e.describe(context.l10n));
/// }
/// ```
extension ApiExceptionL10n on ApiException {
  String describe(AppLocalizations l10n) {
    final detail = message;
    if (detail != null && detail.isNotEmpty) return detail;
    return localizedFallback(l10n);
  }

  String localizedFallback(AppLocalizations l10n) => switch (kind) {
    ApiErrorKind.network => l10n.errorNetwork,
    ApiErrorKind.timeout => l10n.errorTimeout,
    ApiErrorKind.badRequest => l10n.errorBadRequest,
    ApiErrorKind.unauthorized => l10n.errorUnauthorized,
    ApiErrorKind.forbidden => l10n.errorForbidden,
    ApiErrorKind.notFound => l10n.errorNotFound,
    ApiErrorKind.conflict => l10n.errorConflict,
    ApiErrorKind.payloadTooLarge => l10n.errorPayloadTooLarge,
    ApiErrorKind.validation => l10n.errorInvalidInput,
    ApiErrorKind.rateLimited => l10n.errorRateLimited,
    ApiErrorKind.unavailable => l10n.errorUnavailable,
    ApiErrorKind.server => l10n.errorServer,
    ApiErrorKind.cancelled => l10n.errorCancelled,
    ApiErrorKind.notConfigured => l10n.errorNotConfigured,
    ApiErrorKind.unknown => l10n.errorUnknown,
  };
}

/// Describes any error (ApiException or not) for display.
String describeError(Object error, AppLocalizations l10n) =>
    ApiException.from(error).describe(l10n);
