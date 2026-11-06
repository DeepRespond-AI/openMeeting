import 'dart:async';

/// Runs async tasks one after another, in submission order.
class SerialExecutor {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// Completes when every task submitted so far has finished.
  Future<void> get idle => _tail;
}
