import 'dart:async';
import 'dart:io';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im_flutter/deeprespond_im_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import '../api/api_exception.dart';
import '../config/app_config_provider.dart';
import 'im_gateway.dart';
import 'snapshot_stream.dart';

part 'messaging_controller.g.dart';

class ImVideoSession {
  const ImVideoSession(this.controller);
  final VideoPlayerController controller;
}

@riverpod
Future<ImVideoSession> imVideoPlayer(Ref ref, String url) async {
  VideoPlayerController? owned;
  var disposed = false;
  ref.onDispose(() {
    disposed = true;
    if (owned != null) unawaited(owned.dispose());
  });
  final client = await ref.watch(imClientProvider.future);
  final resolved = await client.files.resolveUrl(url);
  if (disposed) throw const ApiException(kind: ApiErrorKind.cancelled);
  final player = VideoPlayerController.networkUrl(Uri.parse(resolved.downloadUrl));
  owned = player;
  await player.initialize();
  if (disposed) throw const ApiException(kind: ApiErrorKind.cancelled);
  return ImVideoSession(player);
}

@riverpod
Stream<List<ConversationView>> imConversations(Ref ref) async* {
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) return;
  final list = client.conversations.list();
  ref.onDispose(list.dispose);
  List<ConversationView> visible(List<ConversationView> items) =>
      items.where((v) => v.state?.membership != 'dismissed').toList();
  await for (final snapshot in snapshotStream(() => list.snapshot, list.stream)) {
    if (snapshot.error != null) throw snapshot.error!;
    yield visible(snapshot.items);
  }
}

@riverpod
Stream<List<Friend>> imFriends(Ref ref) async* {
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) return;
  final list = client.friends.list();
  ref.onDispose(list.dispose);
  await for (final snapshot in snapshotStream(() => list.snapshot, list.stream)) {
    if (snapshot.error != null) throw snapshot.error!;
    yield snapshot.items;
  }
}

@riverpod
Stream<List<GroupView>> imGroups(Ref ref) async* {
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) return;
  final list = client.groups.list();
  ref.onDispose(list.dispose);
  await for (final snapshot in snapshotStream(() => list.snapshot, list.stream)) {
    if (snapshot.error != null) throw snapshot.error!;
    yield snapshot.items;
  }
}

@riverpod
Future<MessageList> imMessageList(Ref ref, String key) async {
  MessageList? opened;
  ref.onDispose(() => opened?.dispose());
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) throw const ApiException(kind: ApiErrorKind.cancelled);
  final list = client.messages.open(key);
  // A room can own the list before its chat sheet is visible. Background
  // synchronization must not acknowledge messages as if the user read them.
  list.setViewing(visible: false);
  opened = list;
  return list;
}

@riverpod
Stream<MessageListSnapshot> imMessages(Ref ref, String key) async* {
  final initialPageSize = ref.watch(appConfigProvider).live.imPageSize;
  final list = await ref.watch(imMessageListProvider(key).future);
  if (!ref.mounted) return;
  // A partial local cache can anchor the SDK window after the first message.
  // Catch-up restores earlier messages without expanding that window. Expand
  // an undersized first page once through the public SDK API; subsequent
  // history loading remains an explicit user action.
  var checkedInitialPage = false;
  await for (final snapshot in snapshotStream(() => list.snapshot, list.stream)) {
    if (!ref.mounted) return;
    yield snapshot;
    if (!ref.mounted) return;
    if (!checkedInitialPage && snapshot.loading == MessageListLoading.none) {
      checkedInitialPage = true;
      if (snapshot.error == null && snapshot.hasOlder && snapshot.items.length < initialPageSize) {
        await list.loadOlder();
      }
    }
  }
}

@riverpod
Stream<List<GroupMember>> imMembers(Ref ref, String id) async* {
  final client = await ref.watch(imClientProvider.future);
  if (!ref.mounted) return;
  final list = client.groups.members(id);
  ref.onDispose(list.dispose);
  await for (final snapshot in snapshotStream(() => list.snapshot, list.stream)) {
    if (snapshot.error != null) throw snapshot.error!;
    yield snapshot.items;
  }
}

@riverpod
Future<GroupInfo?> imGroupInfo(Ref ref, String id) async =>
    (await (await ref.watch(imClientProvider.future)).groups.get(id, refresh: true))?.group;
@riverpod
Future<ConversationView?> imConversation(Ref ref, String key) async {
  final pendingClient = ref.watch(imClientProvider.future);
  final rows = ref.watch(imConversationsProvider).value ?? <ConversationView>[];
  final client = await pendingClient;
  final current = rows
      .where(
        (v) =>
            v.conversationKey == key ||
            (key.startsWith('draft:') && v.peer == key.substring('draft:'.length)),
      )
      .firstOrNull;
  if (current != null) return current;
  return key.startsWith('draft:')
      ? client.conversations.openSingle(key.substring('draft:'.length))
      : client.conversations.get(key);
}

@riverpod
Future<List<GroupRequest>> imInvitations(Ref ref) async {
  final limit = ref.watch(appConfigProvider).live.imPageSize;
  final client = await ref.watch(imClientProvider.future);
  return (await client.groups.invitations.received(
    status: GroupRequestStatus.pending,
    limit: limit,
  )).items;
}

@riverpod
class ImRequests extends _$ImRequests {
  String? _cursor;
  @override
  Future<List<FriendRequest>> build() async {
    final limit = ref.watch(appConfigProvider).live.imPageSize;
    final client = await ref.watch(imClientProvider.future);
    final page = await client.friends.requests.received(
      status: FriendRequestStatus.pending,
      limit: limit,
    );
    _cursor = page.nextCursor;
    return page.items;
  }

  Future<void> more() async {
    if (_cursor == null) return;
    final limit = ref.read(appConfigProvider).live.imPageSize;
    final client = await ref.read(imClientProvider.future),
        page = await client.friends.requests.received(
          status: FriendRequestStatus.pending,
          cursor: _cursor,
          limit: limit,
        );
    if (!ref.mounted) return;
    _cursor = page.nextCursor;
    state = AsyncData([...?state.value, ...page.items]);
  }
}

@riverpod
class MessagingActions extends _$MessagingActions {
  bool _busy = false, _recording = false;
  Object? _partialFailure;
  DRCancelToken? _downloadCancel;
  AudioPlayer? _audio;
  @override
  FutureOr<void> build() {
    ref.onDispose(() {
      _downloadCancel?.cancel();
      if (_recording) unawaited(VoiceRecorder.cancel());
      unawaited(_audio?.dispose() ?? Future<void>.value());
    });
  }

  Future<T?> perform<T>(Future<T> Function(DRClient) task) async {
    if (_busy) return null;
    _busy = true;
    _partialFailure = null;
    state = const AsyncLoading();
    try {
      final client = await ref.read(imClientProvider.future);
      final result = await task(client);
      if (ref.mounted) {
        state = _partialFailure == null
            ? const AsyncData(null)
            : AsyncError(_partialFailure!, StackTrace.current);
      }
      return result;
    } on Object catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return null;
    } finally {
      _busy = false;
    }
  }

  Future<ConversationView?> openSingle(String username) =>
      perform((im) => im.conversations.openSingle(username.trim()));
  Future<ConversationView?> createGroup(String name, String members) => perform((im) async {
    final result = await im.groups.create(
      name: name.trim(),
      type: GroupType.private,
      members: members.split(RegExp(r'[\s,，]+')).where((v) => v.isNotEmpty).toSet().toList(),
    );
    final view =
        await im.conversations.get(result.groupId) ??
        ConversationView({
          'conversation_key': result.groupId,
          'conversation_id': result.groupId,
          'conversation_type': 'group',
          'group_id': result.groupId,
        });
    final failed = result.results.where((v) => !v.ok);
    if (failed.isNotEmpty && ref.mounted) {
      _partialFailure = StateError(
        failed.map((v) => '${v.username}: ${v.message ?? v.code}').join('\n'),
      );
    }
    return view;
  });
  Future<bool> send(String key, String text) async =>
      await perform((im) async {
        await im.messages.send(SendTarget.conversation(key), OutgoingContent.text(text.trim()));
        return true;
      }) ??
      false;
  Future<void> loadOlder(String key) => perform((_) async {
    await (await ref.read(imMessageListProvider(key).future)).loadOlder();
  }).then((_) {});
  Future<void> markRead(String key) async {
    try {
      (await ref.read(imMessageListProvider(key).future)).markRead();
    } on Object catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }

  Future<void> setChatViewing(String key, {required bool visible, bool atBottom = true}) async {
    try {
      void apply(MessageList list) {
        list.setViewing(visible: visible, atBottom: atBottom);
        if (visible && atBottom) list.markRead();
      }

      // Sheet disposal may also dispose this notifier before an await resumes.
      // Update an already-open list synchronously, without starting a new one
      // merely because a hidden sheet is being released.
      final provider = imMessageListProvider(key);
      final current = ref.read(provider).asData?.value;
      if (current != null) {
        apply(current);
        return;
      }
      if (!visible) return;
      final list = await ref.read(provider.future);
      if (!ref.mounted) return;
      apply(list);
    } on Object catch (error, stack) {
      if (ref.mounted && visible) state = AsyncError(error, stack);
    }
  }

  Future<void> pin(ConversationView view) => perform((im) async {
    if (view.conversationId != null) {
      await im.conversations.setPinned(view.conversationId!, view.state?.pinnedAt == null);
    }
  }).then((_) {});
  Future<void> attachment(String key, String type) => perform((im) async {
    final result = await FilePicker.pickFiles();
    if (result.isEmpty) return;
    final file = result.single;
    if ((await file.length() ?? 0) > ref.read(appConfigProvider).live.attachmentMaxBytes) {
      throw const ApiException(kind: ApiErrorKind.payloadTooLarge);
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > ref.read(appConfigProvider).live.attachmentMaxBytes) {
      throw const ApiException(kind: ApiErrorKind.payloadTooLarge);
    }
    final input = DRFile.fromBytes(bytes, name: file.name);
    final content = switch (type) {
      'image' => OutgoingContent.image(input),
      'video' => OutgoingContent.video(input),
      _ => OutgoingContent.file(input, name: file.name),
    };
    await im.messages.send(SendTarget.conversation(key), content);
  }).then((_) {});
  Future<bool> record() async =>
      await perform((_) async {
        await VoiceRecorder.start();
        _recording = true;
        return true;
      }) ??
      false;
  Future<void> cancelRecording() async {
    if (!_recording) return;
    await VoiceRecorder.cancel();
    _recording = false;
  }

  Future<bool> sendVoice(String key) async =>
      await perform((im) async {
        final voice = await VoiceRecorder.stop();
        _recording = false;
        await im.messages.send(SendTarget.conversation(key), voice.toContent());
        return true;
      }) ??
      false;
  Future<String?> download(MessageView message) => perform<String?>((im) async {
    final url = message.body?['url'];
    if (url is! String || !im.files.isFileUrl(url)) {
      throw const ApiException(kind: ApiErrorKind.validation);
    }
    final directory = await getTemporaryDirectory();
    final name = 'im-${message.messageId ?? message.clientMsgId}';
    final path = '${directory.path}${Platform.pathSeparator}$name';
    _downloadCancel = DRCancelToken();
    try {
      await im.files.download(url, path, cancel: _downloadCancel);
      final bytes = await File(path).readAsBytes();
      return (await FilePicker.saveFile(
        fileName: message.body?['name'] as String? ?? name,
        bytes: bytes,
      ))?.toString();
    } finally {
      _downloadCancel = null;
      await File(path).delete().catchError((Object _) => File(path));
    }
  });
  void cancelDownload() => _downloadCancel?.cancel();
  Future<void> cancelMeetingTransfers(List<MessageView> messages) async {
    _downloadCancel?.cancel();
    final client = ref.read(imClientProvider).value;
    if (client == null) return;
    for (final message in messages) {
      if (message.clientMsgId != null &&
          ['queued', 'uploading', 'sending', 'failed'].contains(message.local.status)) {
        await client.messages.discard(message.clientMsgId!);
      }
    }
  }

  Future<void> playVoice(MessageView message) => perform((im) async {
    final url = message.body?['url'];
    if (url is! String || !im.files.isFileUrl(url)) {
      throw const ApiException(kind: ApiErrorKind.validation);
    }
    final download = await im.files.resolveUrl(url);
    final player = _audio ??= AudioPlayer();
    await player.setUrl(download.downloadUrl);
    unawaited(player.play());
  }).then((_) {});
  Future<void> stopPlayback() async {
    await _audio?.stop();
  }

  Future<void> toggleVideo(String url) async {
    try {
      final player = (await ref.read(imVideoPlayerProvider(url).future)).controller;
      if (player.value.isPlaying) {
        await player.pause();
      } else {
        await player.play();
      }
    } on Object catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }

  void clearMessageError() {
    if (!_busy) state = const AsyncData(null);
  }

  Future<bool> copyMessage(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } on Object catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
      return false;
    }
  }

  Future<bool> deleteMessage(MessageView message) async =>
      await perform((im) async {
        if (message.local.status == 'sent' &&
            message.conversationId != null &&
            message.seq != null) {
          await im.messages.deleteForMe(message.conversationId!, [message.seq!]);
        } else if (message.clientMsgId != null && message.local.status != 'sent') {
          await im.messages.discard(message.clientMsgId!);
        } else {
          throw const ApiException(kind: ApiErrorKind.validation);
        }
        return true;
      }) ??
      false;

  Future<({bool recalled, int? windowSeconds})?> recall(MessageView message) => perform((im) async {
    if (message.conversationId == null ||
        message.seq == null ||
        message.sender != im.auth.currentUser?.username) {
      return (recalled: false, windowSeconds: null);
    }
    // Same fallback as the SDK; deployed configuration remains authoritative.
    final seconds = im.config?.recallWindowSeconds ?? 120;
    if (!im.messages.canRecall(message)) return (recalled: false, windowSeconds: seconds);
    try {
      await im.messages.recall(message.conversationId!, message.seq!);
    } on DRException catch (error) {
      if (error.reason == 'recall_window_expired') return (recalled: false, windowSeconds: seconds);
      rethrow;
    }
    return (recalled: true, windowSeconds: null);
  });
  Future<void> retry(MessageView message) => perform((im) async {
    if (message.clientMsgId != null) await im.messages.resend(message.clientMsgId!);
  }).then((_) {});
  Future<void> addContact(String username, String message) =>
      perform((im) => im.friends.requests.send(username: username.trim(), message: message))
          .then((_) {});
  Future<void> accept(String username, bool yes) => perform((im) async {
    if (yes) {
      await im.friends.requests.accept(username);
    } else {
      await im.friends.requests.decline(username);
    }
    ref.invalidate(imRequestsProvider);
  }).then((_) {});
  Future<void> remark(String username, String value) =>
      perform((im) => im.friends.update(username, remark: value)).then((_) {});
  Future<void> removeContact(String username) =>
      perform((im) => im.friends.remove(username)).then((_) {});
  Future<void> invitation(String groupId, bool yes) => perform((im) async {
    if (yes) {
      await im.groups.invitations.accept(groupId);
    } else {
      await im.groups.invitations.decline(groupId);
    }
    ref.invalidate(imInvitationsProvider);
  }).then((_) {});
  Future<void> groupUpdate(String id, String name, String announcement) =>
      perform((im) => im.groups.update(id, name: name.trim(), announcement: announcement))
          .then((_) {
            ref.invalidate(imGroupInfoProvider(id));
          });
  Future<void> groupInvite(String id, String names) => perform((im) async {
    final results = await im.groups.invite(
      id,
      names.split(RegExp(r'[\s,，]+')).where((v) => v.isNotEmpty).toSet().toList(),
    );
    final failures = results.where((v) => !v.ok);
    if (failures.isNotEmpty) {
      throw StateError(failures.map((v) => '${v.username}: ${v.message ?? v.code}').join('\n'));
    }
  }).then((_) {});
  Future<void> groupMember(String id, GroupMember member, String action) => perform((im) async {
    switch (action) {
      case 'mute':
        if (member.muted) {
          await im.groups.unmute(id, member.username);
        } else {
          await im.groups.mute(id, member.username);
        }
      case 'remove':
        final results = await im.groups.removeMembers(id, [member.username]);
        if (results.any((v) => !v.ok)) {
          throw StateError(results.first.message ?? results.first.code ?? '');
        }
      case 'role':
        await im.groups.setRole(
          id,
          member.username,
          member.role == GroupRole.admin ? GroupRole.member : GroupRole.admin,
        );
      case 'transfer':
        await im.groups.transferOwner(id, member.username);
    }
    ref.invalidate(imGroupInfoProvider(id));
  }).then((_) {});
  Future<bool> groupLeave(String id, bool dismiss) async =>
      await perform((im) async {
        if (dismiss) {
          await im.groups.dismiss(id);
        } else {
          await im.groups.leave(id);
        }
        return true;
      }) ??
      false;
}
