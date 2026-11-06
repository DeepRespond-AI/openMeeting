import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im/render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_config_provider.dart';
import '../../im/im_gateway.dart';
import '../../router/app_routes.dart';
import '../../theme/context_extensions.dart';
import '../../widgets/live_feedback.dart';
import '../messaging_controller.dart';
import 'chat_message_tile.dart';
import 'meeting_chat_composer.dart';

class ConversationChatPage extends ConsumerStatefulWidget {
  const ConversationChatPage({
    required this.conversationKey,
    this.initial,
    this.meeting = false,
    this.participantNames = const {},
    super.key,
  });
  final String conversationKey;
  final ConversationView? initial;
  final bool meeting;
  final Map<String, String> participantNames;
  @override
  ConsumerState<ConversationChatPage> createState() => _ConversationChatPageState();
}

class _ConversationChatPageState extends ConsumerState<ConversationChatPage> {
  final text = TextEditingController();
  late final MessagingActions _actions;
  bool recording = false;
  Timer? limit;
  List<MessageView> _latest = [];
  bool _atBottom = true, _foreground = true;
  AppLifecycleListener? _lifecycle;
  @override
  void initState() {
    super.initState();
    _actions = ref.read(messagingActionsProvider.notifier);
    unawaited(_actions.setChatViewing(widget.conversationKey, visible: true));
    _lifecycle = AppLifecycleListener(
      onPause: () {
        _foreground = false;
        unawaited(_actions.setChatViewing(widget.conversationKey, visible: false));
      },
      onResume: () {
        _foreground = true;
        unawaited(
          _actions.setChatViewing(widget.conversationKey, visible: true, atBottom: _atBottom),
        );
      },
    );
  }

  @override
  void dispose() {
    limit?.cancel();
    _lifecycle?.dispose();
    unawaited(_actions.setChatViewing(widget.conversationKey, visible: false));
    if (widget.meeting) unawaited(_actions.cancelMeetingTransfers(_latest));
    text.dispose();
    unawaited(_actions.cancelRecording());
    unawaited(_actions.stopPlayback());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n, im = ref.watch(imClientProvider).value;
    final view = ref.watch(imConversationProvider(widget.conversationKey)).value ?? widget.initial;
    final snapshot = ref.watch(imMessagesProvider(widget.conversationKey)),
        operation = ref.watch(messagingActionsProvider);
    final actions = ref.read(messagingActionsProvider.notifier);
    ref.listen(imMessagesProvider(widget.conversationKey), (_, next) {
      _latest = next.value?.items ?? [];
      unawaited(
        actions.setChatViewing(widget.conversationKey, visible: _foreground, atBottom: _atBottom),
      );
    });
    return Scaffold(
      appBar: widget.meeting
          ? null
          : AppBar(
              title: Text(
                widget.meeting
                    ? l.liveChat
                    : im != null && view != null
                    ? conversationTitle(im, view)
                    : l.liveMessages,
              ),
              actions: [
                if (!widget.meeting && view?.groupId != null)
                  IconButton(
                    tooltip: l.imManageGroup,
                    onPressed: () => context.push(AppRoutes.groupDetail(view!.groupId!)),
                    icon: const Icon(Icons.group_outlined),
                  ),
                if (!widget.meeting && view != null)
                  IconButton(
                    tooltip: l.imPin,
                    onPressed: operation.isLoading ? null : () => actions.pin(view),
                    icon: const Icon(Icons.push_pin_outlined),
                  ),
              ],
            ),
      body: Column(
        children: [
          if (operation.hasError) LiveError(operation.error!),
          Expanded(
            child: snapshot.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => LiveError(
                error,
                onRetry: () => ref.invalidate(imMessagesProvider(widget.conversationKey)),
              ),
              data: (data) => Column(
                children: [
                  if (data.error != null) LiveError(data.error!),
                  if (data.hasOlder)
                    TextButton(
                      onPressed: operation.isLoading
                          ? null
                          : () => actions.loadOlder(widget.conversationKey),
                      child: Text(l.imLoadOlder),
                    ),
                  Expanded(
                    child: data.items.isEmpty
                        ? Center(child: Text(l.liveNoMessages))
                        : NotificationListener<ScrollNotification>(
                            onNotification: (event) {
                              _atBottom = event.metrics.pixels <= event.metrics.minScrollExtent;
                              unawaited(
                                actions.setChatViewing(
                                  widget.conversationKey,
                                  visible: _foreground,
                                  atBottom: _atBottom,
                                ),
                              );
                              return false;
                            },
                            child: ListView(
                              reverse: true,
                              padding: context.spacing.page,
                              children: [
                                for (var index = data.items.length - 1; index >= 0; index--)
                                  if (!data.items[index].erased && data.items[index].type != 'tip')
                                    ChatMessageTile(
                                      key: ValueKey(
                                        data.items[index].clientMsgId ??
                                            data.items[index].messageId ??
                                            data.items[index].seq,
                                      ),
                                      message: data.items[index],
                                      own:
                                          im?.auth.currentUser?.username ==
                                          data.items[index].sender,
                                      fallbackName:
                                          widget.participantNames[data.items[index].sender],
                                      showTime: showChatMessageTime(
                                        data.items[index],
                                        index > 0 ? data.items[index - 1] : null,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: context.spacing.card,
              child: widget.meeting
                  ? MeetingChatComposer(
                      controller: text,
                      busy: operation.isLoading,
                      maxLength: ref.watch(appConfigProvider).live.imTextMax,
                      onAttachment: (type) => actions.attachment(widget.conversationKey, type),
                      onSend: () async {
                        if (await actions.send(widget.conversationKey, text.text) && mounted) {
                          text.clear();
                        }
                      },
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Wrap(
                          spacing: context.spacing.xs,
                          children: [
                            PopupMenuButton<String>(
                              tooltip: l.liveAttach,
                              enabled: !operation.isLoading && !recording,
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'image', child: Text(l.imImage)),
                                PopupMenuItem(value: 'video', child: Text(l.imVideo)),
                                PopupMenuItem(value: 'file', child: Text(l.imFile)),
                              ],
                              onSelected: (type) =>
                                  actions.attachment(widget.conversationKey, type),
                              icon: const Icon(Icons.attach_file),
                            ),
                            if (!widget.meeting)
                              TextButton.icon(
                                onPressed: operation.isLoading
                                    ? null
                                    : () async {
                                        if (recording) {
                                          limit?.cancel();
                                          setState(() => recording = false);
                                          await actions.sendVoice(widget.conversationKey);
                                        } else if (await actions.record() && mounted) {
                                          setState(() => recording = true);
                                          limit = Timer(
                                            Duration(
                                              seconds: ref
                                                  .read(appConfigProvider)
                                                  .live
                                                  .voiceLimitSec,
                                            ),
                                            () {
                                              unawaited(actions.cancelRecording());
                                              if (mounted) {
                                                setState(() => recording = false);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(l.imVoiceLimit)),
                                                );
                                              }
                                            },
                                          );
                                        }
                                      },
                                icon: Icon(recording ? Icons.stop : Icons.mic_none),
                                label: Text(recording ? l.imStopSend : l.imVoice),
                              ),
                            if (recording)
                              TextButton(
                                onPressed: () {
                                  limit?.cancel();
                                  unawaited(actions.cancelRecording());
                                  setState(() => recording = false);
                                },
                                child: Text(l.liveBack),
                              ),
                            TextButton(
                              onPressed: actions.stopPlayback,
                              child: Text(l.imStopPlayback),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: text,
                                enabled: !operation.isLoading && !recording,
                                minLines: 1,
                                maxLines: 3,
                                maxLength: ref.watch(appConfigProvider).live.imTextMax,
                                decoration: InputDecoration(labelText: l.liveMessage),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            IconButton(
                              tooltip: l.liveSend,
                              onPressed:
                                  operation.isLoading || recording || text.text.trim().isEmpty
                                  ? null
                                  : () async {
                                      if (await actions.send(widget.conversationKey, text.text) &&
                                          mounted) {
                                        text.clear();
                                      }
                                    },
                              icon: operation.isLoading
                                  ? const CircularProgressIndicator()
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
