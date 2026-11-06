import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/context_extensions.dart';
import 'chat_emoji_picker.dart';

/// Meeting-only composer: attachment, emoji, draft and send share one row.
class MeetingChatComposer extends StatefulWidget {
  const MeetingChatComposer({
    required this.controller,
    required this.busy,
    required this.maxLength,
    required this.onAttachment,
    required this.onSend,
    super.key,
  });
  final TextEditingController controller;
  final bool busy;
  final int maxLength;
  final ValueChanged<String> onAttachment;
  final VoidCallback onSend;

  @override
  State<MeetingChatComposer> createState() => _MeetingChatComposerState();
}

class _MeetingChatComposerState extends State<MeetingChatComposer> {
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _emoji() async {
    _focus.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => ChatEmojiPicker(onSelected: _insertEmoji),
    );
    if (mounted && !widget.busy) _focus.requestFocus();
  }

  void _insertEmoji(String emoji) {
    if (widget.busy) return;
    final value = widget.controller.value;
    final selection = value.selection.isValid && value.selection.end <= value.text.length
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final next = value.replaced(selection, emoji);
    final limited = LengthLimitingTextInputFormatter(widget.maxLength)
        .formatEditUpdate(value, next);
    // Keep the existing draft intact when adding an emoji would exceed the limit.
    if (limited.text == next.text) widget.controller.value = next;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: context.radius.lgAll,
        border: Border.all(color: context.colors.border, width: context.sizes.borderWidth),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.xxs),
        child: Row(
          key: const ValueKey('meeting-chat-composer'),
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PopupMenuButton<String>(
              key: const ValueKey('meeting-chat-attach'),
              tooltip: l.liveAttach,
              enabled: !widget.busy,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'image', child: Text(l.imImage)),
                PopupMenuItem(value: 'video', child: Text(l.imVideo)),
                PopupMenuItem(value: 'file', child: Text(l.imFile)),
              ],
              onSelected: widget.onAttachment,
              icon: const Icon(Icons.attach_file),
            ),
            IconButton(
              key: const ValueKey('meeting-chat-emoji'),
              tooltip: l.liveChatEmoji,
              onPressed: widget.busy ? null : _emoji,
              icon: const Icon(Icons.sentiment_satisfied_alt_outlined),
            ),
            Expanded(
              child: TextField(
                key: const ValueKey('meeting-chat-input'),
                controller: widget.controller,
                focusNode: _focus,
                enabled: !widget.busy,
                minLines: 1,
                maxLines: 3,
                maxLength: widget.maxLength,
                style: context.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: l.liveChatMessageHint,
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: context.spacing.sm),
                  counterText: '',
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (_, value, _) => IconButton(
                key: const ValueKey('meeting-chat-send'),
                tooltip: l.liveSend,
                onPressed: widget.busy || value.text.trim().isEmpty ? null : widget.onSend,
                icon: widget.busy
                    ? SizedBox.square(
                        dimension: context.sizes.iconMd,
                        child: const CircularProgressIndicator(),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
