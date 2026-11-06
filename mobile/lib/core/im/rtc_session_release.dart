import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';

/// SDK lookups do not accept cancellation. Bound only the wait, and ignore late
/// replies; never turn a cancelled lookup into a new join or resume.
Future<T> rtcWait<T>(Future<T> pending, DRCancelToken cancel, Duration timeout) async {
  final result = Completer<T>();
  final timer = Timer(timeout, () {
    if (!result.isCompleted) result.completeError(const RtcReleaseTimeout());
  });
  final off = cancel.onCancel(() {
    if (!result.isCompleted) {
      result.completeError(DRException(code: LocalErrorCode.aborted, source: ErrorSource.local));
    }
  });
  unawaited(
    pending.then(
      (value) {
        if (!result.isCompleted) result.complete(value);
      },
      onError: (Object error, StackTrace stack) {
        if (!result.isCompleted) result.completeError(error, stack);
      },
    ),
  );
  try {
    return await result.future;
  } finally {
    timer.cancel();
    off();
  }
}

class RtcReleaseTimeout implements Exception {
  const RtcReleaseTimeout();
}

Future<ChannelSession?> waitForRtcRelease(
  ChannelsModule channels, {
  required DRCancelToken cancel,
  required Duration timeout,
  required Duration pollInterval,
  required void Function() onReleasing,
}) async {
  final pending = DRCancelToken();
  final off = cancel.onCancel(pending.cancel);
  var timedOut = false;
  final deadline = Timer(timeout, () {
    timedOut = true;
    pending.cancel();
  });
  try {
    while (true) {
      final session = await rtcWait(channels.getCurrentSession(), pending, timeout);
      if (pending.isCancelled) {
        throw DRException(code: LocalErrorCode.aborted, source: ErrorSource.local);
      }
      if (session?.status != 'leaving') return session;
      onReleasing();
      // A cancellable poll delay. The independent deadline bounds the entire
      // release, including slow/hung lookups, rather than resetting per query.
      await rtcWait(Completer<void>().future, pending, pollInterval).catchError((Object error) {
        if (error is! RtcReleaseTimeout) throw error;
      });
    }
  } on Object {
    if (timedOut && !cancel.isCancelled) throw const RtcReleaseTimeout();
    rethrow;
  } finally {
    deadline.cancel();
    off();
  }
}
