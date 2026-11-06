import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config_provider.dart';
import '../data/meetings_changed.dart';
import 'im_gateway.dart';

part 'meeting_record_notices.g.dart';

typedef MeetingRecordNotice = ({String meetingId, String event, String? title});

/// Matches the desktop's trusted notification contract. IM owns delivery and
/// offline history; the app stores no duplicate notification database.
MeetingRecordNotice? parseMeetingRecordNotice(MessageView message) {
  final body = message.body;
  if (message.type != 'custom' ||
      message.sender != 'notice' ||
      message.recalled != null ||
      message.erased ||
      body?['kind'] != 'openmeeting.meeting' ||
      body?['version'] != 1) {
    return null;
  }
  final id = body?['meetingId'], event = body?['event'];
  if (id is! String ||
      !RegExp(r'^[\w-]{1,80}$').hasMatch(id) ||
      !['meeting_ended', 'processing_completed', 'processing_failed'].contains(event)) {
    return null;
  }
  final title = body?['title'];
  return (meetingId: id, event: event as String, title: title is String ? title : null);
}

class MeetingNoticeFilter {
  MeetingNoticeFilter(this.limit) : assert(limit > 0);
  final int limit;
  final _seen = <String>{};
  MeetingRecordNotice? accept(MessageView message) {
    final notice = parseMeetingRecordNotice(message);
    if (notice == null) return null;
    final key = '${message.conversationId}:${message.seq}';
    if (!_seen.add(key)) return null;
    if (_seen.length > limit) _seen.remove(_seen.first);
    return notice;
  }
}

@riverpod
Stream<MeetingRecordNotice> meetingRecordNotices(Ref ref) async* {
  final config = ref.watch(appConfigProvider).live;
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) return;
  yield* Stream<MeetingRecordNotice>.multi((sink) {
    final filter = MeetingNoticeFilter(config.noticeDedupLimit);
    final histories = <String, MessageList>{};
    final subscriptions = <StreamSubscription<Object?>>[];
    var disposed = false;
    void deliver(MessageView message) {
      if (disposed || !ref.mounted) return;
      final notice = filter.accept(message);
      if (notice == null) return;
      ref.read(meetingsChangedProvider.notifier).bump();
      sink.add(notice);
    }

    // Live first; SDK history may hydrate while opening its conversation list.
    subscriptions.add(
      client.on<MessageReceived>().listen(
        (event) => deliver(event.message),
        onError: sink.addError,
      ),
    );
    final conversations = client.conversations.list();
    void update() {
      if (disposed) return;
      for (final conversation in conversations.snapshot.items) {
        final id = conversation.conversationId;
        if (conversation.peer != 'notice' || id == null || histories.containsKey(id)) continue;
        final messages = client.messages.open(conversation.conversationKey);
        // History observers must never advance acknowledgement/read positions.
        messages.setViewing(visible: false, atBottom: false);
        histories[id] = messages;
        void history() {
          final current = conversations.snapshot.items
              .where((c) => c.conversationId == id)
              .firstOrNull;
          for (final message in latestMeetingNotices(
            messages.snapshot.items,
            readSeq: current?.state?.readSeq ?? 0,
            limit: config.noticeHistoryLimit,
          )) {
            deliver(message);
          }
        }

        subscriptions.add(messages.stream.listen((_) => history(), onError: sink.addError));
        history();
      }
    }

    subscriptions.add(conversations.stream.listen((_) => update(), onError: sink.addError));
    update();
    void close() {
      if (disposed) return;
      disposed = true;
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
      conversations.dispose();
      for (final history in histories.values) {
        history.dispose();
      }
    }

    ref.onDispose(close);
    sink.onCancel = close;
  });
}

/// Keep the latest trusted outcome per meeting, above the shared SDK read
/// position. Limit notification bursts when a user returns after being offline.
List<MessageView> latestMeetingNotices(
  List<MessageView> items, {
  required int readSeq,
  required int limit,
}) {
  final latest = <String, MessageView>{};
  for (final message in items.reversed) {
    final notice = parseMeetingRecordNotice(message);
    if (notice == null || (message.seq ?? 0) <= readSeq) continue;
    latest.putIfAbsent(notice.meetingId, () => message);
    if (latest.length >= limit) break;
  }
  return latest.values.toList().reversed.toList();
}
