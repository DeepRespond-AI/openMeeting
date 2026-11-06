/// Subscribe before replaying. With `yield current(); yield* updates`, a send ack
/// emitted while the UI handles the first snapshot can disappear permanently.
Stream<T> snapshotStream<T>(T Function() current, Stream<T> updates) => Stream.multi((sink) {
  final subscription = updates.listen(
    sink.addSync,
    onError: sink.addErrorSync,
    onDone: sink.closeSync,
  );
  sink.onCancel = subscription.cancel;
  sink.addSync(current());
});
