import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception_l10n.dart';
import '../theme/context_extensions.dart';

/// Renders an [AsyncValue]: spinner while loading (unless data is already present),
/// a localized error with a retry button, or [data].
///
/// ```dart
/// AsyncValueView(
///   value: ref.watch(meetingsListControllerProvider),
///   onRetry: () => ref.read(meetingsListControllerProvider.notifier).refresh(),
///   data: (meetings) => ListView(...),
/// )
/// ```
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncValue(:final T value, hasValue: true) => data(value),
      AsyncError(:final error) => ErrorView(error: error, onRetry: onRetry),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Centered error message (+ retry button) for any error.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: context.spacing.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: context.sizes.iconXl,
              color: context.colors.mutedForeground,
            ),
            context.spacing.gapSm,
            Text(
              describeError(error, l10n),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.mutedForeground),
            ),
            if (onRetry != null) ...[
              context.spacing.gapMd,
              OutlinedButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
            ],
          ],
        ),
      ),
    );
  }
}
