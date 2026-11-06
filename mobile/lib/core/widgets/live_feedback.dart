import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../api/api_exception_l10n.dart';
import '../im/rtc_connection_failure.dart';
import '../theme/context_extensions.dart';

String describeLiveError(BuildContext context, Object error) {
  if (error is ApiException) return error.describe(context.l10n);
  if (error == rtcJoinTimedOut) return context.l10n.liveMediaJoinTimedOut;
  if (error == rtcReleaseTimedOut) return context.l10n.liveMediaReleaseTimedOut;
  final kind = ApiErrorKind.values.where((k) => k.name == error.toString()).firstOrNull;
  return kind == null ? error.toString() : ApiException(kind: kind).describe(context.l10n);
}

class LiveError extends StatelessWidget {
  const LiveError(this.error, {this.onRetry, super.key});
  final Object error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Card(
      child: Padding(
        padding: context.spacing.card,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: context.colors.destructive),
            context.spacing.gapSm,
            Expanded(child: Text(describeLiveError(context, error))),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text(context.l10n.liveRetry)),
          ],
        ),
      ),
    ),
  );
}
