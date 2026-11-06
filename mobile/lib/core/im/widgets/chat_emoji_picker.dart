import 'package:flutter/material.dart';

import '../../theme/context_extensions.dart';

// Same curated Unicode emoji groups as the desktop meeting chat.
const _groups = [
  [
    '😀',
    '😁',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '😉',
    '😍',
    '🤩',
    '😘',
    '😋',
    '🤪',
    '🤨',
    '🤓',
    '😎',
    '🥳',
    '😏',
    '😌',
    '😔',
    '😴',
    '🥱',
    '😅',
    '🤔',
  ],
  [
    '👍',
    '👎',
    '👌',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '🤙',
    '👈',
    '👉',
    '👆',
    '👇',
    '☝️',
    '✋',
    '🖐️',
    '🖖',
    '👋',
    '🤝',
    '🙏',
    '💪',
    '👏',
    '🙌',
    '👐',
    '✊',
  ],
  [
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '💯',
    '🔥',
    '✨',
    '⭐',
    '💫',
    '💥',
    '🎉',
    '🎊',
    '🎈',
    '✅',
    '❌',
    '⚠️',
    '❓',
    '❗',
    '💬',
    '👀',
    '🚀',
  ],
];

class ChatEmojiPicker extends StatelessWidget {
  const ChatEmojiPicker({required this.onSelected, super.key});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: context.sizes.touchTarget * 6,
        child: DefaultTabController(
          length: _groups.length,
          child: Column(
            children: [
              Row(
                children: [
                  context.spacing.gapMd,
                  Expanded(child: Text(l.liveChatEmoji, style: context.textTheme.titleSmall)),
                  IconButton(
                    tooltip: l.liveClose,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              TabBar(
                tabs: [
                  Tab(text: l.liveChatEmojiFaces),
                  Tab(text: l.liveChatEmojiGestures),
                  Tab(text: l.liveChatEmojiSymbols),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (var group = 0; group < _groups.length; group++)
                      GridView.builder(
                        key: PageStorageKey('chat-emoji-group-$group'),
                        padding: context.spacing.page,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: context.sizes.touchTarget + context.spacing.xs,
                          mainAxisSpacing: context.spacing.xxs,
                          crossAxisSpacing: context.spacing.xxs,
                        ),
                        itemCount: _groups[group].length,
                        itemBuilder: (_, index) => TextButton(
                          onPressed: () => onSelected(_groups[group][index]),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(_groups[group][index], style: context.textTheme.titleLarge),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
