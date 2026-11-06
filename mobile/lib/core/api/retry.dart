import 'dart:async';

import '../config/app_config.dart';
import 'api_exception.dart';

/// Sleeps for a duration; injectable so tests run instantly.
typedef Sleeper = Future<void> Function(Duration delay);

Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);

/// Runs [action], retrying failures that [retryIf] accepts (default:
/// `ApiException.from(e).isRetryable`) according to [policy]
/// (`AppConfig.network.retry` / `.audioUploadRetry`).
///
/// Total attempts = `1 + policy.maxRetries`; the delay before retry `i` is
/// `policy.delayFor(i)`. The last error is rethrown as-is.
///
/// ```dart
/// final cfg = ref.read(appConfigProvider).network;
/// final result = await retry(() => repo.uploadSegment(seg), policy: cfg.retry);
/// ```
Future<T> retry<T>(
  Future<T> Function() action, {
  required RetryConfig policy,
  bool Function(Object error)? retryIf,
  void Function(Object error, int retryIndex, Duration delay)? onRetry,
  Sleeper sleep = _defaultSleep,
}) async {
  final shouldRetry = retryIf ?? (Object e) => ApiException.from(e).isRetryable;
  var retryIndex = 0;
  while (true) {
    try {
      return await action();
    } catch (e) {
      if (retryIndex >= policy.maxRetries || !shouldRetry(e)) rethrow;
      final delay = policy.delayFor(retryIndex);
      onRetry?.call(e, retryIndex, delay);
      await sleep(delay);
      retryIndex++;
    }
  }
}
