import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/im/im_gateway.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/live_feedback.dart';
import 'messaging_controller.dart';

Future<String?> imPrompt(BuildContext context, String title, {String initial = ''}) async {
  return showDialog<String>(
    context: context,
    builder: (_) => _PromptDialog(title: title, initial: initial),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({required this.title, required this.initial});
  final String title, initial;
  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(controller: controller, autofocus: true, maxLines: 3),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.liveBack)),
      FilledButton(
        onPressed: () => Navigator.pop(context, controller.text),
        child: Text(context.l10n.liveConfirm),
      ),
    ],
  );
}

Future<bool> imConfirm(BuildContext context, String title, String name) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.liveBack),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.liveConfirm),
          ),
        ],
      ),
    ) ??
    false;

class ContactsPage extends ConsumerWidget {
  const ContactsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n,
        operation = ref.watch(messagingActionsProvider),
        actions = ref.read(messagingActionsProvider.notifier);
    final contacts = ref.watch(imFriendsProvider), requests = ref.watch(imRequestsProvider);
    return ListView(
      padding: context.spacing.page,
      children: [
        FilledButton.tonalIcon(
          onPressed: operation.isLoading
              ? null
              : () async {
                  final username = await imPrompt(context, l.imUserId);
                  if (username?.trim().isNotEmpty ?? false) await actions.addContact(username!, '');
                },
          icon: const Icon(Icons.person_add_outlined),
          label: Text(l.imAddContact),
        ),
        context.spacing.gapLg,
        Text(l.imRequests, style: Theme.of(context).textTheme.titleMedium),
        requests.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => LiveError(e, onRetry: () => ref.invalidate(imRequestsProvider)),
          data: (items) => Column(
            children: [
              if (items.isEmpty) Text(l.imNoRequests),
              for (final item in items)
                Card(
                  child: ListTile(
                    title: Text(item.nickname.isEmpty ? item.username : item.nickname),
                    subtitle: Text(item.message),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: l.imAccept,
                          onPressed: operation.isLoading
                              ? null
                              : () => actions.accept(item.username, true),
                          icon: const Icon(Icons.check),
                        ),
                        IconButton(
                          tooltip: l.imDecline,
                          onPressed: operation.isLoading
                              ? null
                              : () => actions.accept(item.username, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(imRequestsProvider.notifier).more(),
                  child: Text(l.imLoadMore),
                ),
            ],
          ),
        ),
        context.spacing.gapLg,
        Text(l.imContacts, style: Theme.of(context).textTheme.titleMedium),
        contacts.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => LiveError(e, onRetry: () => ref.invalidate(imFriendsProvider)),
          data: (items) => Column(
            children: [
              if (items.isEmpty) Text(l.imEmpty),
              for (final friend in items)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(friend.displayName.characters.firstOrNull ?? '?'),
                    ),
                    title: Text(friend.displayName),
                    subtitle: Text(friend.username),
                    onTap: () async {
                      final view = await actions.openSingle(friend.username);
                      if (view != null && context.mounted) {
                        await context.push(
                          AppRoutes.messageThread(view.conversationKey),
                          extra: view,
                        );
                      }
                    },
                    trailing: PopupMenuButton<String>(
                      enabled: !operation.isLoading,
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'remark', child: Text(l.imRemark)),
                        PopupMenuItem(value: 'remove', child: Text(l.imRemoveContact)),
                      ],
                      onSelected: (action) async {
                        if (action == 'remark') {
                          final value = await imPrompt(context, l.imRemark, initial: friend.remark);
                          if (value != null) await actions.remark(friend.username, value);
                        } else if (await imConfirm(
                          context,
                          l.imRemoveContact,
                          friend.displayName,
                        )) {
                          await actions.removeContact(friend.username);
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n,
        operation = ref.watch(messagingActionsProvider),
        actions = ref.read(messagingActionsProvider.notifier);
    final groups = ref.watch(imGroupsProvider), invites = ref.watch(imInvitationsProvider);
    return ListView(
      padding: context.spacing.page,
      children: [
        Text(l.imInvitations, style: Theme.of(context).textTheme.titleMedium),
        invites.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => LiveError(e, onRetry: () => ref.invalidate(imInvitationsProvider)),
          data: (items) => Column(
            children: [
              if (items.isEmpty) Text(l.imNoRequests),
              for (final item in items)
                Card(
                  child: ListTile(
                    title: Text(item.groupId),
                    subtitle: Text(item.message ?? ''),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: l.imAccept,
                          onPressed: operation.isLoading
                              ? null
                              : () => actions.invitation(item.groupId, true),
                          icon: const Icon(Icons.check),
                        ),
                        IconButton(
                          tooltip: l.imDecline,
                          onPressed: operation.isLoading
                              ? null
                              : () => actions.invitation(item.groupId, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        context.spacing.gapLg,
        Text(l.imGroups, style: Theme.of(context).textTheme.titleMedium),
        groups.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => LiveError(e, onRetry: () => ref.invalidate(imGroupsProvider)),
          data: (items) => Column(
            children: [
              if (items.isEmpty) Text(l.imEmpty),
              for (final view in items)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: Text(view.group.name),
                    subtitle: Text(l.liveMembersCount(view.group.memberCount)),
                    onTap: () => context.push(
                      AppRoutes.messageThread(view.groupId),
                      extra: ConversationView({
                        'conversation_key': view.groupId,
                        'conversation_id': view.groupId,
                        'conversation_type': 'group',
                        'group_id': view.groupId,
                      }),
                    ),
                    trailing: IconButton(
                      tooltip: l.imManageGroup,
                      onPressed: () => context.push(AppRoutes.groupDetail(view.groupId)),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class GroupDetailPage extends ConsumerWidget {
  const GroupDetailPage({required this.groupId, super.key});
  final String groupId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n,
        operation = ref.watch(messagingActionsProvider),
        actions = ref.read(messagingActionsProvider.notifier),
        group = ref.watch(imGroupInfoProvider(groupId)),
        members = ref.watch(imMembersProvider(groupId));
    final username = ref.watch(imClientProvider).value?.auth.currentUser?.username;
    return Scaffold(
      appBar: AppBar(title: Text(l.imManageGroup)),
      body: ListView(
        padding: context.spacing.page,
        children: [
          if (operation.hasError) LiveError(operation.error!),
          group.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) =>
                LiveError(e, onRetry: () => ref.invalidate(imGroupInfoProvider(groupId))),
            data: (info) {
              if (info == null) return Text(l.imEmpty);
              final owner = info.owner == username,
                  admin = owner || info.self?.role == GroupRole.admin;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(info.name, style: Theme.of(context).textTheme.headlineSmall),
                  SelectableText(info.groupId),
                  if (info.announcement?.isNotEmpty ?? false) Text(info.announcement!),
                  context.spacing.gapLg,
                  if (admin)
                    FilledButton.tonal(
                      onPressed: operation.isLoading
                          ? null
                          : () async {
                              final name = await imPrompt(
                                context,
                                l.imGroupName,
                                initial: info.name,
                              );
                              if (name == null || name.trim().isEmpty || !context.mounted) return;
                              final announcement = await imPrompt(
                                context,
                                l.imAnnouncement,
                                initial: info.announcement ?? '',
                              );
                              if (announcement != null) {
                                await actions.groupUpdate(groupId, name, announcement);
                              }
                            },
                      child: Text(l.liveEdit),
                    ),
                  if (admin || info.memberInvite != 'disabled')
                    TextButton.icon(
                      onPressed: operation.isLoading
                          ? null
                          : () async {
                              final ids = await imPrompt(context, l.imMemberIds);
                              if (ids?.trim().isNotEmpty ?? false) {
                                await actions.groupInvite(groupId, ids!);
                              }
                            },
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(l.imInvite),
                    ),
                  members.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) =>
                        LiveError(e, onRetry: () => ref.invalidate(imMembersProvider(groupId))),
                    data: (items) => Column(
                      children: [
                        for (final member in items)
                          ListTile(
                            title: Text(
                              member.groupNickname.isNotEmpty
                                  ? member.groupNickname
                                  : member.nickname.isNotEmpty
                                  ? member.nickname
                                  : member.username,
                            ),
                            subtitle: Text(member.username),
                            trailing:
                                member.username == username ||
                                    member.role == GroupRole.owner ||
                                    !admin
                                ? null
                                : PopupMenuButton<String>(
                                    enabled: !operation.isLoading,
                                    itemBuilder: (_) => [
                                      if (owner || member.role == GroupRole.member) ...[
                                        PopupMenuItem(
                                          value: 'mute',
                                          child: Text(member.muted ? l.liveUnmute : l.liveMute),
                                        ),
                                        PopupMenuItem(value: 'remove', child: Text(l.liveRemove)),
                                      ],
                                      if (owner) ...[
                                        PopupMenuItem(value: 'role', child: Text(l.imAdminRole)),
                                        PopupMenuItem(
                                          value: 'transfer',
                                          child: Text(l.liveTransfer),
                                        ),
                                      ],
                                    ],
                                    onSelected: (action) async {
                                      if (['remove', 'transfer'].contains(action) &&
                                          !await imConfirm(
                                            context,
                                            action == 'remove' ? l.liveRemove : l.liveTransfer,
                                            member.username,
                                          )) {
                                        return;
                                      }
                                      await actions.groupMember(groupId, member, action);
                                    },
                                  ),
                          ),
                      ],
                    ),
                  ),
                  context.spacing.gapLg,
                  OutlinedButton(
                    onPressed: operation.isLoading
                        ? null
                        : () async {
                            if (await imConfirm(
                                  context,
                                  owner ? l.imDismissGroup : l.imLeaveGroup,
                                  info.name,
                                ) &&
                                await actions.groupLeave(groupId, owner) &&
                                context.mounted) {
                              context.go(AppRoutes.messages);
                            }
                          },
                    child: Text(owner ? l.imDismissGroup : l.imLeaveGroup),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
