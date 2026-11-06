import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/im/snapshot_stream.dart';

void main() {
  test('send acknowledgement arriving during initial UI snapshot is never lost', () async {
    final updates = StreamController<int>.broadcast(sync: true);
    final received = <int>[];
    final sub = snapshotStream(() => 0, updates.stream).listen((value) {
      received.add(value);
      if (value == 0) updates.add(1);
    });
    await Future<void>.delayed(Duration.zero);
    expect(received, [0, 1]);
    await sub.cancel();
    await updates.close();
  });
  test('replayed snapshot is read at subscription time, not provider creation', () async {
    final updates = StreamController<int>.broadcast(sync: true);
    var current = 0;
    final stream = snapshotStream(() => current, updates.stream);
    current = 2;
    final received = <int>[];
    final sub = stream.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    updates.add(3);
    await Future<void>.delayed(Duration.zero);
    expect(received, [2, 3]);
    await sub.cancel();
    await updates.close();
  });
  test('disposing the UI subscription detaches updates', () async {
    final updates = StreamController<int>.broadcast();
    final sub = snapshotStream(() => 0, updates.stream).listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(updates.hasListener, isTrue);
    await sub.cancel();
    expect(updates.hasListener, isFalse);
    await updates.close();
  });
}
