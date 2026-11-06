import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:deeprespond_im_flutter/deeprespond_im_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/context_extensions.dart';
import '../../widgets/live_feedback.dart';
import '../im_gateway.dart';
import '../messaging_controller.dart';
import '../user_profile.dart';
import 'inline_video.dart';
import 'user_identity.dart';

enum _MessageAction { copy, delete, recall }

bool showChatMessageTime(MessageView message, MessageView? previous) {
  final time = message.createdAt?.toLocal(), before = previous?.createdAt?.toLocal();
  if (time == null) return false;
  return before == null ||
      time.difference(before) >= const Duration(minutes: 5) ||
      !DateUtils.isSameDay(time, before);
}

/// Meeting and direct messages share one bubble, action menu and recall notice.
class ChatMessageTile extends ConsumerWidget {
  const ChatMessageTile({
    required this.message,
    required this.own,
    this.fallbackName,
    this.showTime = false,
    super.key,
  });
  final MessageView message;
  final bool own, showTime;
  final String? fallbackName;

  Future<void> _act(BuildContext context, WidgetRef ref, _MessageAction action, String text) async {
    final actions = ref.read(messagingActionsProvider.notifier), l = context.l10n;
    if (action == _MessageAction.delete) {
      actions.clearMessageError();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Consumer(
          builder: (context, ref, _) {
            final operation = ref.watch(messagingActionsProvider);
            return PopScope(
              canPop: !operation.isLoading,
              child: AlertDialog(
                title: Text(l.imMessageDeleteTitle),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.imMessageDeleteDescription),
                    if (operation.hasError)
                      Padding(
                        padding: EdgeInsets.only(top: context.spacing.xs),
                        child: Text(
                          describeLiveError(context, operation.error!),
                          style: TextStyle(color: context.colors.destructive),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: operation.isLoading ? null : () => Navigator.pop(dialogContext),
                    child: Text(l.imMessageCancel),
                  ),
                  FilledButton(
                    onPressed: operation.isLoading
                        ? null
                        : () async {
                            if (await actions.deleteMessage(message) && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                    child: Text(l.imMessageConfirm),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else if (action == _MessageAction.copy) {
      final copied = await actions.copyMessage(text);
      if (context.mounted && copied) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l.imMessageCopied)));
      }
    } else {
      final result = await actions.recall(message);
      if (!context.mounted || result == null || result.recalled) return;
      final seconds = result.windowSeconds;
      final text = seconds == null || seconds <= 0
          ? l.imMessageRecallUnavailable
          : seconds % 60 == 0
          ? l.imMessageRecallExpiredMinutes(seconds ~/ 60)
          : l.imMessageRecallExpiredSeconds(seconds);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.erased) return const SizedBox.shrink();
    final l = context.l10n, spacing = context.spacing, colors = context.colors;
    final im = ref.watch(imClientProvider).value;
    final profile = ref.watch(imUserProfileProvider(message.sender ?? '')).value;
    final name = identityName(profile, fallbackName, l.imUnknownUser);
    final time = message.createdAt?.toLocal();
    final now = DateTime.now();
    final timeText = time == null
        ? ''
        : '${DateUtils.isSameDay(time, now) ? '' : '${MaterialLocalizations.of(context).formatMediumDate(time)} '}'
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(time), alwaysUse24HourFormat: true)}';
    final label = showTime && time != null
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: Center(
              child: Text(
                timeText,
                style: context.textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
              ),
            ),
          )
        : const SizedBox.shrink();
    if (message.recalled != null) {
      return Column(
        children: [
          label,
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.sm),
            child: Text(
              own ? l.imMessageRecalledSelf : l.imMessageRecalledOther(name),
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
          ),
        ],
      );
    }
    final body = message.body, text = body?['text'] as String? ?? body?['name'] as String? ?? '';
    final busy = ref.watch(messagingActionsProvider).isLoading;
    final sent = message.local.status == 'sent';
    final menuKey = GlobalKey<PopupMenuButtonState<_MessageAction>>();
    final menu = PopupMenuButton<_MessageAction>(
      key: menuKey,
      tooltip: l.imMessageActions,
      enabled: !busy,
      icon: Icon(Icons.more_horiz, size: context.sizes.iconMd, color: colors.mutedForeground),
      onSelected: (action) => _act(context, ref, action, text),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MessageAction.copy,
          enabled: text.isNotEmpty,
          child: Text(l.imMessageCopy),
        ),
        PopupMenuItem(
          value: _MessageAction.delete,
          enabled: sent
              ? message.seq != null && message.conversationId != null
              : message.clientMsgId != null,
          child: Text(l.imMessageDelete),
        ),
        if (own && sent && message.seq != null && message.conversationId != null)
          PopupMenuItem(value: _MessageAction.recall, child: Text(l.imRecall)),
      ],
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.type == 'image' && body?['url'] is String && im != null)
          InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: l.liveClose,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                    Flexible(
                      child: InteractiveViewer(
                        child: Image(
                          image: DRImage(body['url'] as String, client: im),
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, _) => LiveError(error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Image(
              image: DRImage(body!['url'] as String, client: im),
              height: context.sizes.logoLg * 2,
              fit: BoxFit.contain,
              errorBuilder: (_, error, _) => LiveError(error),
            ),
          )
        else if (message.type == 'video' && body?['url'] is String)
          ImInlineVideo(url: body!['url'] as String)
        else
          SelectableText(
            text.isEmpty ? l.imAttachment : text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: own ? colors.onPrimary : colors.foreground,
            ),
          ),
        if (message.local.status == 'uploading')
          LinearProgressIndicator(value: message.local.progress),
        if (['image', 'video', 'voice', 'file'].contains(message.type))
          Wrap(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: own ? colors.onPrimary : colors.primary,
                ),
                onPressed: busy
                    ? null
                    : () => ref.read(messagingActionsProvider.notifier).download(message),
                icon: const Icon(Icons.download_outlined),
                label: Text(l.imDownload),
              ),
              if (message.type == 'voice')
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: own ? colors.onPrimary : colors.primary,
                  ),
                  onPressed: busy
                      ? null
                      : () => ref.read(messagingActionsProvider.notifier).playVoice(message),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l.imPlay),
                ),
            ],
          ),
      ],
    );
    final bubble = Flexible(
      child: GestureDetector(
        onLongPress: busy ? null : () => menuKey.currentState?.showButtonMenu(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
          decoration: BoxDecoration(
            color: own ? colors.primary : colors.surface,
            borderRadius: BorderRadius.circular(context.radius.sm),
            border: own ? null : Border.all(color: colors.border),
          ),
          child: content,
        ),
      ),
    );
    final avatar = ImUserAvatar(
      username: message.sender ?? '',
      fallbackName: fallbackName,
      size: context.sizes.iconXl,
    );
    final column = Expanded(
      child: Column(
        crossAxisAlignment: own ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(color: colors.mutedForeground),
          ),
          SizedBox(height: spacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: own ? [menu, bubble] : [bubble, menu],
          ),
          if (!sent)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.local.status == 'failed' ? l.imMessageSendFailed : l.imMessageSending,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: message.local.status == 'failed'
                        ? colors.destructive
                        : colors.mutedForeground,
                  ),
                ),
                if (message.local.status == 'failed')
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => ref.read(messagingActionsProvider.notifier).retry(message),
                    child: Text(l.liveRetry),
                  ),
              ],
            ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        label,
        Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: own ? [column, spacing.gapXs, avatar] : [avatar, spacing.gapXs, column],
          ),
        ),
      ],
    );
  }
}
