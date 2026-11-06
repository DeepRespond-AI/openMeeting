import 'dart:async';

import 'package:deeprespond_im/render.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/im/im_gateway.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/app_switch_list_tile.dart';
import '../../../core/widgets/live_feedback.dart';
import 'messaging_controller.dart';
import 'social_pages.dart';

export '../../../core/im/widgets/conversation_chat_page.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n,
        client = ref.watch(imClientProvider),
        operation = ref.watch(messagingActionsProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.liveMessages),
          bottom: TabBar(
            tabs: [
              Tab(text: l.imConversations),
              Tab(text: l.imContacts),
              Tab(text: l.imGroups),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: l.imNew,
          onPressed: () =>
              showDialog<void>(context: context, builder: (_) => const NewConversationDialog()),
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            if (operation.hasError) LiveError(operation.error!),
            Expanded(
              child: client.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: LiveError(e, onRetry: () => ref.invalidate(imClientProvider))),
                data: (im) => TabBarView(
                  children: [
                    ref
                        .watch(imConversationsProvider)
                        .when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) =>
                              LiveError(e, onRetry: () => ref.invalidate(imConversationsProvider)),
                          data: (items) => items.isEmpty
                              ? Center(child: Text(l.imEmpty))
                              : ListView(
                                  children: [
                                    for (final view in items)
                                      ListTile(
                                        leading: CircleAvatar(
                                          child: Text(
                                            conversationTitle(im, view).characters.firstOrNull ??
                                                '?',
                                          ),
                                        ),
                                        title: Text(
                                          conversationTitle(im, view),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          view.lastMessage == null
                                              ? ''
                                              : summarize(
                                                  view.lastMessage!,
                                                  nameOf: (username) => displayName(im, username),
                                                ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: view.unreadCount > 0
                                            ? Badge(label: Text('${view.unreadCount}'))
                                            : null,
                                        onTap: () => context.push(
                                          AppRoutes.messageThread(view.conversationKey),
                                          extra: view,
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                    const ContactsPage(),
                    const GroupsPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewConversationDialog extends ConsumerStatefulWidget {
  const NewConversationDialog({super.key});
  @override
  ConsumerState<NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends ConsumerState<NewConversationDialog> {
  final name = TextEditingController(), members = TextEditingController();
  bool group = false;
  @override
  void dispose() {
    name.dispose();
    members.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n,
        operation = ref.watch(messagingActionsProvider),
        action = ref.read(messagingActionsProvider.notifier);
    return AlertDialog(
      title: Text(l.imNew),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSwitchListTile(
              title: Text(l.imCreateGroup),
              value: group,
              onChanged: operation.isLoading ? null : (v) => setState(() => group = v),
            ),
            TextField(
              controller: name,
              enabled: !operation.isLoading,
              decoration: InputDecoration(labelText: group ? l.imGroupName : l.imUserId),
              onChanged: (_) => setState(() {}),
            ),
            if (group)
              TextField(
                controller: members,
                enabled: !operation.isLoading,
                decoration: InputDecoration(labelText: l.imMemberIds),
              ),
            if (operation.hasError) LiveError(operation.error!),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: operation.isLoading ? null : () => Navigator.pop(context),
          child: Text(l.liveBack),
        ),
        FilledButton(
          onPressed: operation.isLoading || name.text.trim().isEmpty
              ? null
              : () async {
                  final router = GoRouter.of(context);
                  final view = group
                      ? await action.createGroup(name.text, members.text)
                      : await action.openSingle(name.text);
                  if (view != null && context.mounted) {
                    Navigator.pop(context);
                    unawaited(
                      router.push(AppRoutes.messageThread(view.conversationKey), extra: view),
                    );
                  }
                },
          child: Text(operation.isLoading ? l.liveSaving : l.imCreate),
        ),
      ],
    );
  }
}
