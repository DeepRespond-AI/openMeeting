// Exercise the installed SDK's real MessageList and SQLite window. Only the
// network catch-up response and identity boundary are fixtures.
// ignore_for_file: implementation_imports
import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im/src/core.dart';
import 'package:deeprespond_im/src/log.dart';
import 'package:deeprespond_im/src/modules/messages/context.dart';
import 'package:deeprespond_im/src/modules/messages/conversations.dart';
import 'package:deeprespond_im/src/modules/messages/fetch.dart';
import 'package:deeprespond_im/src/modules/messages/list.dart';
import 'package:deeprespond_im/src/modules/messages/txops.dart';
import 'package:deeprespond_im/src/store/db.dart';
import 'package:deeprespond_im/src/store/object_db.dart';
import 'package:deeprespond_im/src/store/sqlite.dart';
import 'package:deeprespond_im/src/transport/http.dart';
import 'package:mocktail/mocktail.dart';

class _Core extends Mock implements Core {}

class _Options extends Mock implements ResolvedOptions {}

class _Platform extends Mock implements DRPlatform {}

class _Conversations extends Mock implements Conversations {}

// Keep the real SDK fetcher, including range/gap catch-up. Substitute only the
// HTTP response and database/event transaction boundary.
class _Context extends Fake implements MsgContext {
  _Context(this.fixture);
  final InitialChatFixture fixture;
  @override
  Core get core => fixture._core;
  @override
  String me() => 'mobile';
  @override
  Future<T> request<T>(ApiRequest req, {bool idempotent = true}) async {
    if (req.path.endsWith('/pins')) return <String, Object?>{'items': []} as T;
    fixture.catchUpCalls++;
    await fixture.catchUpGate?.future;
    if (fixture.failCatchUp) throw DRException(code: 'network_error', source: ErrorSource.local);
    final query = req.query ?? {};
    final after = query['after_seq'] as int?;
    final before = query['before_seq'] as int?;
    final limit = query['limit']! as int;
    final all = [for (var i = 1; i <= fixture.count; i++) incoming(i)];
    final matching = all
        .where(
          (m) =>
              (after == null || (m['seq']! as int) > after) &&
              (before == null || (m['seq']! as int) < before),
        )
        .toList();
    final items = after == null
        ? matching.skip(matching.length > limit ? matching.length - limit : 0).toList()
        : matching.take(limit).toList();
    return <String, Object?>{
      'items': items,
      'next_before_seq': items.isEmpty ? (before ?? 1) : items.first['seq'],
      'next_after_seq': items.isEmpty ? (after ?? 0) : items.last['seq'],
      'has_more': matching.length > items.length,
    } as T;
  }

  @override
  Future<ChangeSet> write(MsgWriteFn fn, {bool strict = false, bool publish = true}) async {
    final changes = ChangeSet();
    await fixture.db.transaction((tx) async {
      final writer = ConvWriter(tx, changes, 0, (_) => null);
      await fn(writer, tx, changes);
      await writer.flush();
    });
    if (publish) fixture.changed([]);
    return changes;
  }
}

class _Store extends Fake implements LocalStore {
  _Store(this.db);
  final ObjectDatabase db;
  @override
  bool get isOpen => true;
  @override
  Future<T> read<T>(Future<T> Function(Tx) action) => db.transaction(action);
}

Map<String, Object?> incoming(int seq) => {
  'conversation_id': 'first-message-chat',
  'conversation_type': 'group',
  'seq': seq,
  'message_id': 'm$seq',
  'client_msg_id': 'desktop-$seq',
  'sender': 'desktop',
  'sender_type': 'user',
  'type': 'text',
  'body': {'text': '桌面消息-$seq'},
  'created_at': '2026-10-29T08:00:00Z',
};

class InitialChatFixture {
  InitialChatFixture._(this.db);
  final ObjectDatabase db;
  final _core = _Core(), _platform = _Platform(), _options = _Options();
  final _conversations = _Conversations();
  late final _fetcher = MessageFetcher(_Context(this));
  final _events = StreamController<({String name, Object? payload})>.broadcast(sync: true);
  final lists = <MessageList>[];
  final viewingReports = <({String op, bool? viewing})>[];
  int readCalls = 0;
  Completer<void>? catchUpGate;
  int count = 2;
  int catchUpCalls = 0;
  bool failCatchUp = false;

  static Future<InitialChatFixture> create({
    bool seedLatest = true,
    bool seedRange = true,
    int count = 2,
  }) async {
    final f = InitialChatFixture._(
      await ObjectDatabase.open(const DefaultDatabaseOpener(background: false), null),
    );
    f.count = count;
    when(() => f._core.events).thenAnswer((_) => f._events.stream);
    when(() => f._core.store).thenReturn(_Store(f.db));
    when(() => f._core.platform).thenReturn(f._platform);
    when(() => f._core.opts).thenReturn(f._options);
    when(() => f._core.me).thenReturn('mobile');
    when(() => f._options.autoMarkRead).thenReturn(false);
    when(() => f._platform.foregroundChanges).thenAnswer((_) => const Stream.empty());
    when(() => f._platform.isForeground).thenReturn(true);
    when(() => f._core.moduleLog(any()))
        .thenAnswer((_) => Logger(const LogOptions(level: LogLevel.error), () => 0).child('test'));
    when(f._conversations.retentionDays).thenReturn(0);
    when(() => f._conversations.markRead(any())).thenAnswer((_) {
      f.readCalls++;
    });
    await f.db.transaction((tx) async {
      final changes = ChangeSet();
      final writer = ConvWriter(tx, changes, 0, (_) => null);
      await applyState(writer, tx, changes, {
        'conversation_id': 'first-message-chat',
        'conversation_type': 'group',
        'group_id': 'first-message-chat',
        'membership': 'member',
        'start_seq': 1,
        'max_seq': count,
        'read_seq': 0,
        'version': 1,
      }, 1);
      if (seedLatest && count > 0) {
        await putMessages(
          writer,
          tx,
          changes,
          'first-message-chat',
          [incoming(count)],
          range: seedRange ? (count, count) : null,
          me: 'mobile',
        );
      }
      await writer.flush();
    });
    return f;
  }

  Future<void> write(List<Map<String, Object?>> messages) async {
    if (messages.isEmpty) return;
    await db.transaction((tx) async {
      final changes = ChangeSet();
      final writer = ConvWriter(tx, changes, 0, (_) => null);
      await putMessages(
        writer,
        tx,
        changes,
        'first-message-chat',
        messages,
        range: (messages.first['seq']! as int, messages.last['seq']! as int),
        me: 'mobile',
      );
      await writer.flush();
    });
    changed([for (final message in messages) message['seq']! as int]);
  }

  void changed(List<int> seqs) {
    _events.add((
      name: 'messages.changed',
      payload: {'conversation_key': 'first-message-chat', 'upserted': seqs},
    ));
  }

  MessageList open() {
    final list = MessageListImpl(_core, _conversations, _fetcher, 'first-message-chat', null, (
      _,
      _,
      op, [
      viewing,
    ]) {
      viewingReports.add((op: op, viewing: viewing));
    });
    lists.add(list);
    return list;
  }

  Future<void> dispose() async {
    for (final list in lists) {
      list.dispose();
    }
    if (catchUpGate case final gate? when !gate.isCompleted) {
      gate.complete();
    }
    await Future<void>.delayed(Duration.zero);
    await _events.close();
    await db.close();
  }
}
