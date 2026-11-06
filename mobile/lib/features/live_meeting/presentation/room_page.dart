import 'dart:async';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_config_provider.dart';
import '../../../core/im/channel_media.dart';
import '../../../core/im/rtc_telemetry.dart';
import '../../../core/im/widgets/conversation_chat_page.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/utils/copy_text.dart';
import '../../../core/widgets/app_switch_list_tile.dart';
import '../../../core/widgets/text_limit.dart';
import '../domain/live_models.dart';
import 'live_feedback.dart';
import 'media_panels.dart';
import 'meeting_gallery.dart';
import 'recording_panel.dart';
import 'room_controller.dart';
import 'room_metrics.dart';
import 'screen_controller.dart';

part 'room_page.g.dart';

lk.VideoTrack? cameraVideo(
  ChannelHandle? channel,
  List<ChannelTrack> tracks,
  LiveParticipant participant,
) {
  final track = tracks
      .where(
        (t) => t.kind == 'video' && t.username == participant.userId && !isScreenTrack(channel, t),
      )
      .firstOrNull
      ?.track;
  return track is lk.VideoTrack ? track : null;
}

@riverpod
Stream<List<ChannelTrack>> authorizedTracks(Ref ref) =>
    ref.watch(roomChannelProvider)?.tracks ?? Stream.value([]);

class LiveRoomPage extends ConsumerWidget {
  const LiveRoomPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Theme(data: AppTheme.dark(), child: const _RoomBody());
}

class _RoomBody extends ConsumerStatefulWidget {
  const _RoomBody();
  @override
  ConsumerState<_RoomBody> createState() => _RoomBodyState();
}

class _RoomBodyState extends ConsumerState<_RoomBody> {
  String? _enteredRoomId;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(roomControllerProvider),
        l = context.l10n,
        controller = ref.read(roomControllerProvider.notifier);
    // Keep capture lifecycle attached even when the meeting is minimized.
    ref.watch(roomScreenProvider);
    if (current is RoomActive) {
      if (current.connection == 'connected' && current.media == 'connected') {
        _enteredRoomId = current.room.id;
      }
    } else {
      _enteredRoomId = null;
    }
    // Gate only the first entry. Once shown, a room stays visible during
    // later reconnects/retries; background media state never becomes a banner.
    final initializing = current is RoomActive && _enteredRoomId != current.room.id;
    final terminal = current is RoomEnded || current is RoomIdle || current is RoomFailed;
    return PopScope(
      canPop: terminal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(askLeave(context, ref));
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: terminal,
          title: Text(
            switch (current) {
              RoomActive(:final room) => room.title,
              RoomWaiting(:final room) => room.title,
              _ => l.liveRoom,
            },
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (!terminal)
              IconButton(
                key: const ValueKey('minimize-live-meeting'),
                tooltip: l.liveMinimize,
                onPressed: () => context.go(AppRoutes.meetings),
                icon: const Icon(Icons.home_outlined),
              ),
            if (!terminal)
              IconButton(
                tooltip: l.liveLeave,
                onPressed: () => askLeave(context, ref),
                icon: const Icon(Icons.logout),
              ),
          ],
        ),
        body: switch (current) {
          RoomJoining() => const _MeetingEntry(),
          RoomWaiting(:final room, :final error) => Center(
            child: Padding(
              padding: context.spacing.page,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top),
                  context.spacing.gapLg,
                  Text(l.liveWaiting),
                  Text(l.liveCodeValue(room.code)),
                  if (error != null) LiveError(error),
                  TextButton(onPressed: controller.leave, child: Text(l.liveCancelJoin)),
                ],
              ),
            ),
          ),
          RoomFailed(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LiveError(message),
                TextButton(
                  onPressed: () => context.go(AppRoutes.meetings),
                  child: Text(l.liveBackHome),
                ),
              ],
            ),
          ),
          // The app router removes the room and its open sheets on completion.
          RoomEnded() => const SizedBox.shrink(),
          RoomActive() =>
            initializing
                ? _MeetingEntry(
                    error:
                        current.error ??
                        (['error', 'unavailable'].contains(current.media)
                            ? l.liveMediaUnavailable
                            : null),
                    onRetry: controller.retryMedia,
                  )
                : ActiveRoom(current),
          RoomIdle() => Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.meetings),
              child: Text(l.liveBackHome),
            ),
          ),
        },
        bottomNavigationBar: current is RoomActive && !initializing ? RoomToolbar(current) : null,
      ),
    );
  }
}

class _MeetingEntry extends StatelessWidget {
  const _MeetingEntry({this.error, this.onRetry});
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (error == null) ...[
          const CircularProgressIndicator(),
          context.spacing.gapMd,
          Text(context.l10n.liveJoining),
        ] else
          LiveError(error!, onRetry: onRetry),
      ],
    ),
  );
}

Future<void> askLeave(BuildContext context, WidgetRef ref) async {
  final current = ref.read(roomControllerProvider), l = context.l10n;
  if (current is RoomWaiting) {
    await ref.read(roomControllerProvider.notifier).leave();
    return;
  }
  if (current is! RoomActive) return;
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(current.self.isHost ? l.liveEnd : l.liveLeave),
      content: Text(current.self.isHost ? l.liveEndHint : l.liveLeaveHint),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.liveBack)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.liveConfirm)),
      ],
    ),
  );
  if (yes == true) {
    await ref.read(roomScreenProvider.notifier).stop();
    await ref.read(roomControllerProvider.notifier).leave(end: current.self.isHost);
  }
}

class ActiveRoom extends ConsumerWidget {
  const ActiveRoom(this.current, {super.key});
  final RoomActive current;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n,
        channel = ref.watch(roomChannelProvider),
        tracks = ref.watch(authorizedTracksProvider).value ?? [];
    final metrics = ref.watch(roomMetricsProvider).value ?? const RoomMetrics();
    final screen = ref.watch(roomScreenProvider);
    final owner = current.room.participants
        .where((p) => p.screenSharing && p.screenShareId != null)
        .firstOrNull;
    final selfNetwork = metrics.network[current.self.userId];
    final mediaPreparing = [
      'idle',
      'connecting',
      'releasing',
      'reconnecting',
    ].contains(current.media);
    return Column(
      children: [
        RoomRecordingBanner(current),
        Padding(
          padding: context.spacing.card,
          child: Row(
            children: [
              Expanded(child: Text(l.liveCodeValue(current.room.code))),
              NetworkBadge(
                metrics: selfNetwork,
                connected: current.media == 'connected' && current.connection == 'connected',
              ),
              Text(l.liveMembersCount(current.room.participants.length)),
            ],
          ),
        ),
        if (screen.error != null)
          Padding(
            padding: context.spacing.card,
            child: Text(
              screenError(context, screen.error)!,
              style: TextStyle(color: context.colors.destructive),
            ),
          ),
        if (screen.phase == ScreenPhase.sharing)
          ListTile(
            dense: true,
            leading: const Icon(Icons.screen_share),
            title: Text(l.liveShareSharing),
            trailing: TextButton(
              onPressed: ref.read(roomScreenProvider.notifier).stop,
              child: Text(l.liveShareStop),
            ),
          ),
        if (current.error != null || (!mediaPreparing && current.media != 'connected'))
          LiveError(
            current.error ?? l.liveMediaUnavailable,
            onRetry: current.media != 'connected'
                ? () => ref.read(roomControllerProvider.notifier).retryMedia()
                : () => ref.read(roomControllerProvider.notifier).refresh(),
          ),
        if (current.connection == 'reconnecting')
          Padding(padding: context.spacing.card, child: Text(l.liveReconnecting)),
        Expanded(
          flex: owner != null ? 2 : 3,
          child: MeetingGallery(
            tiles: {
              for (final participant in current.room.participants)
                participant.id: Card(
                  key: ValueKey('participant-${participant.id}'),
                  margin: EdgeInsets.zero,
                  shape: metrics.speaker == participant.userId && participant.micOn
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(context.spacing.md),
                          side: BorderSide(
                            color: context.colors.primary,
                            width: context.sizes.borderWidth * 2,
                          ),
                        )
                      : null,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (participant.camOn && cameraVideo(channel, tracks, participant) != null)
                        lk.VideoTrackRenderer(
                          cameraVideo(channel, tracks, participant)!,
                          fit: lk.VideoViewFit.cover,
                          mirrorMode: participant.isSelf
                              ? lk.VideoViewMirrorMode.mirror
                              : lk.VideoViewMirrorMode.off,
                        )
                      else
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: owner != null ? context.sizes.touchTarget : 0,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CircleAvatar(
                                radius: owner != null ? context.sizes.iconSm : null,
                                child: Text(participant.name.characters.firstOrNull ?? '?'),
                              ),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          color: context.colors.surface.withValues(alpha: .85),
                          padding: context.spacing.card,
                          child: Row(
                            children: [
                              Icon(
                                participant.micOn ? Icons.mic : Icons.mic_off,
                                size: context.sizes.iconSm,
                                color: participant.micOn
                                    ? context.colors.success
                                    : context.colors.destructive,
                              ),
                              context.spacing.gapXs,
                              Expanded(
                                child: Text(
                                  participant.isSelf ? l.liveMe : participant.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (participant.isHost) const Icon(Icons.star_outline),
                              if (participant.handRaised) const Icon(Icons.back_hand_outlined),
                              if (metrics.speaker == participant.userId && participant.micOn)
                                Tooltip(
                                  message: l.liveSpeaking,
                                  child: Icon(
                                    Icons.graphic_eq,
                                    size: context.sizes.iconSm,
                                    color: context.colors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            },
            invite: OutlinedButton(
              key: const ValueKey('meeting-invite'),
              onPressed: () async {
                try {
                  await copyText(l.liveInvitation(current.room.title, current.room.code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l.commonCopied)));
                  }
                } on Object catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(describeLiveError(context, error))));
                  }
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_outlined),
                  context.spacing.gapXs,
                  Text(l.liveInvite, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        if (owner != null)
          Expanded(
            flex: 3,
            child: ScreenStage(
              owner: owner,
              track: owner.isSelf && screen.phase == ScreenPhase.sharing
                  ? screen.video
                  : sharedTrack(channel, tracks, owner)?.track,
            ),
          ),
      ],
    );
  }
}

class RoomToolbar extends ConsumerWidget {
  const RoomToolbar(this.current, {super.key});
  final RoomActive current;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n, c = ref.read(roomControllerProvider.notifier);
    return SafeArea(
      child: Material(
        color: context.colors.surface,
        child: Padding(
          padding: context.spacing.card,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              tool(
                context,
                current.self.micOn ? Icons.mic : Icons.mic_off,
                l.liveMic,
                current.busy || current.media != 'connected' || current.self.mutedByHost
                    ? null
                    : () => c.mic(!current.self.micOn),
              ),
              tool(
                context,
                current.self.camOn ? Icons.videocam : Icons.videocam_off,
                l.liveCamera,
                current.busy || current.media != 'connected'
                    ? null
                    : () => c.cam(!current.self.camOn),
              ),
              tool(
                context,
                Icons.people_outline,
                l.liveMembers,
                () => roomSheet(context, const MembersPanel()),
              ),
              tool(
                context,
                Icons.chat_bubble_outline,
                l.liveChat,
                () => roomSheet(context, const RoomChatPanel()),
              ),
              tool(
                context,
                Icons.more_horiz,
                l.liveMore,
                () => roomSheet(context, const RoomMorePanel()),
              ),
              tool(
                context,
                Icons.logout,
                current.self.isHost ? l.liveEnd : l.liveLeave,
                () => askLeave(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tool(BuildContext context, IconData icon, String label, VoidCallback? callback) =>
      Expanded(
        child: Tooltip(
          message: label,
          child: TextButton(
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.symmetric(horizontal: context.spacing.xxs),
            ),
            onPressed: callback,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      );
}

Future<void> roomSheet(BuildContext context, Widget child) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Consumer(
    builder: (context, ref, _) {
      ref.listen(roomControllerProvider, (_, next) {
        if (next is! RoomActive && context.mounted) {
          Navigator.of(context).popUntil((route) => route is PageRoute);
        }
      });
      return SizedBox(
        height:
            MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top - kToolbarHeight,
        child: child,
      );
    },
  ),
);

class MembersPanel extends ConsumerWidget {
  const MembersPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomControllerProvider),
        l = context.l10n,
        c = ref.read(roomControllerProvider.notifier);
    if (state is! RoomActive) return const SizedBox.shrink();
    return Column(
      children: [
        ListTile(
          title: Text(l.liveMembersCount(state.room.participants.length)),
          trailing: IconButton(
            tooltip: l.liveClose,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        if (state.error != null) LiveError(state.error!),
        Expanded(
          child: ListView(
            padding: context.spacing.page,
            children: [
              if (state.self.isHost && state.room.waiting.isNotEmpty) ...[
                Text(l.liveWaitingRoom, style: Theme.of(context).textTheme.titleMedium),
                for (final person in state.room.waiting)
                  Card(
                    child: ListTile(
                      title: Text(person.name),
                      subtitle: Wrap(
                        children: [
                          TextButton(
                            onPressed: state.busy
                                ? null
                                : () => c.action('admit', participantId: person.participantId),
                            child: Text(l.liveAdmit),
                          ),
                          TextButton(
                            onPressed: state.busy
                                ? null
                                : () => c.action('deny', participantId: person.participantId),
                            child: Text(l.liveDeny),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              if (state.self.isHost)
                FilledButton.tonal(
                  onPressed: state.busy ? null : () => c.action('mute-all'),
                  child: Text(l.liveMuteAll),
                ),
              for (final person in state.room.participants)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(person.name.characters.firstOrNull ?? '?')),
                    title: Text(person.name),
                    subtitle: Text(person.isHost ? l.liveHost : l.liveMember),
                    trailing: person.handRaised ? const Icon(Icons.back_hand_outlined) : null,
                    onTap: !state.self.isHost || person.isSelf
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) => SimpleDialog(
                              title: Text(person.name),
                              children: [
                                SimpleDialogOption(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    unawaited(
                                      c.action(
                                        'mute',
                                        participantId: person.id,
                                        values: {'muted': !person.mutedByHost},
                                      ),
                                    );
                                  },
                                  child: Text(person.mutedByHost ? l.liveUnmute : l.liveMute),
                                ),
                                if (person.handRaised)
                                  SimpleDialogOption(
                                    onPressed: () {
                                      Navigator.pop(dialogContext);
                                      unawaited(c.action('approve-hand', participantId: person.id));
                                    },
                                    child: Text(l.liveApproveHand),
                                  ),
                                for (final action in [
                                  ('remove', l.liveRemove),
                                  ('transfer-host', l.liveTransfer),
                                ])
                                  SimpleDialogOption(
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);
                                      final yes = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(action.$2),
                                          content: Text(person.name),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: Text(l.liveBack),
                                            ),
                                            FilledButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: Text(l.liveConfirm),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (yes == true) {
                                        await c.action(action.$1, participantId: person.id);
                                      }
                                    },
                                    child: Text(action.$2),
                                  ),
                              ],
                            ),
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

class RoomChatPanel extends ConsumerWidget {
  const RoomChatPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomControllerProvider);
    if (state is! RoomActive) return const SizedBox.shrink();
    final binding = ref.watch(roomChatSessionProvider);
    return Column(
      children: [
        ListTile(
          title: Text(context.l10n.liveChat),
          trailing: IconButton(
            tooltip: context.l10n.liveClose,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        Expanded(
          child: binding.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                LiveError(error, onRetry: () => ref.invalidate(roomChatSessionProvider)),
            data: (view) => ConversationChatPage(
              key: ValueKey(view.conversationKey),
              conversationKey: view.conversationKey,
              initial: view,
              meeting: true,
              participantNames: {
                for (final p in state.room.participants)
                  if (p.userId != null) p.userId!: p.name,
              },
            ),
          ),
        ),
      ],
    );
  }
}

class RoomMorePanel extends ConsumerWidget {
  const RoomMorePanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomControllerProvider),
        l = context.l10n,
        c = ref.read(roomControllerProvider.notifier);
    if (state is! RoomActive) return const SizedBox.shrink();
    final screen = ref.watch(roomScreenProvider);
    return ListView(
      padding: context.spacing.page,
      children: [
        ListTile(
          title: Text(l.liveMore),
          trailing: IconButton(
            tooltip: l.liveClose,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        if (state.error != null) LiveError(state.error!),
        if (!state.self.isHost)
          ListTile(
            leading: const Icon(Icons.back_hand_outlined),
            title: Text(state.self.handRaised ? l.liveLowerHand : l.liveRaiseHand),
            onTap: state.busy ? null : c.hand,
          ),
        ListTile(
          leading: const Icon(Icons.cameraswitch_outlined),
          title: Text(l.liveSwitchCamera),
          onTap: state.busy ? null : c.switchCamera,
        ),
        ListTile(
          leading: const Icon(Icons.volume_up_outlined),
          title: Text(l.liveSpeaker),
          onTap: state.busy ? null : () => c.speaker(true),
        ),
        ListTile(
          leading: const Icon(Icons.hearing_outlined),
          title: Text(l.liveEarpiece),
          onTap: state.busy ? null : () => c.speaker(false),
        ),
        ListTile(
          leading: const Icon(Icons.screen_share_outlined),
          key: const ValueKey('screen-share-action'),
          title: Text(screen.phase == ScreenPhase.sharing ? l.liveShareStop : l.liveShare),
          subtitle: Text(
            screen.phase == ScreenPhase.capturing || screen.phase == ScreenPhase.publishing
                ? l.liveShareStarting
                : screenError(context, screen.error) ?? l.liveShareCaptureHint,
          ),
          onTap: state.busy || state.media != 'connected' || screen.phase == ScreenPhase.stopping
              ? null
              : () async {
                  if (screen.phase != ScreenPhase.idle) {
                    await ref.read(roomScreenProvider.notifier).stop();
                  } else {
                    await ref
                        .read(roomScreenProvider.notifier)
                        .start(l.liveShareSharing, l.liveShareCaptureHint);
                  }
                },
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(l.liveSettings),
          onTap: () => roomSheet(context, const RoomSettingsPanel()),
        ),
      ],
    );
  }
}

class RoomSettingsPanel extends ConsumerStatefulWidget {
  const RoomSettingsPanel({super.key});
  @override
  ConsumerState<RoomSettingsPanel> createState() => _RoomSettingsPanelState();
}

class _RoomSettingsPanelState extends ConsumerState<RoomSettingsPanel> {
  final title = TextEditingController(), password = TextEditingController();
  bool pwd = false, waiting = false;
  String? validation;
  @override
  void initState() {
    super.initState();
    final state = ref.read(roomControllerProvider);
    if (state is RoomActive) {
      title.text = state.room.title;
      pwd = state.room.pwdEnabled;
      waiting = state.room.waitRoom;
    }
  }

  @override
  void dispose() {
    title.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomControllerProvider), l = context.l10n;
    if (state is! RoomActive) return const SizedBox.shrink();
    final enabled = state.self.isHost && !state.busy;
    return ListView(
      padding: context.spacing.page.add(
        EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      ),
      children: [
        ListTile(
          title: Text(l.liveSettings),
          trailing: IconButton(
            tooltip: l.liveClose,
            onPressed: state.busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        Text(l.liveSettingsHint),
        if (!state.self.isHost) Text(l.liveHostOnly),
        context.spacing.gapLg,
        TextField(
          controller: title,
          maxLength: ref.watch(appConfigProvider).live.titleMax,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          inputFormatters: [CodePointLengthFormatter(ref.watch(appConfigProvider).live.titleMax)],
          buildCounter: codePointCounter(title, ref.watch(appConfigProvider).live.titleMax),
          enabled: enabled,
          decoration: InputDecoration(labelText: l.liveTitle),
        ),
        AppSwitchListTile(
          title: Text(l.liveRequirePassword),
          value: pwd,
          onChanged: enabled ? (v) => setState(() => pwd = v) : null,
        ),
        if (pwd)
          TextField(
            controller: password,
            enabled: enabled,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.livePassword,
              hintText: state.room.pwdEnabled ? l.liveKeepPassword : l.livePasswordInvalid,
            ),
          ),
        AppSwitchListTile(
          title: Text(l.liveWaitingRoom),
          value: waiting,
          onChanged: enabled ? (v) => setState(() => waiting = v) : null,
        ),
        if (validation != null) LiveError(validation!),
        if (state.error != null) LiveError(state.error!),
        if (state.self.isHost)
          FilledButton(
            onPressed: !enabled
                ? null
                : () async {
                    if (title.text.trim().isEmpty) {
                      setState(() => validation = l.liveTitleRequired);
                      return;
                    }
                    if (pwd &&
                        (!state.room.pwdEnabled || password.text.isNotEmpty) &&
                        !RegExp(r'^[0-9]{4,6}$').hasMatch(password.text)) {
                      setState(() => validation = l.livePasswordInvalid);
                      return;
                    }
                    setState(() => validation = null);
                    final saved = await ref.read(roomControllerProvider.notifier).settings({
                      'title': title.text.trim(),
                      'pwdEnabled': pwd,
                      'waitRoom': waiting,
                      if (pwd && password.text.isNotEmpty) 'pwd': password.text,
                    });
                    if (saved && context.mounted) Navigator.pop(context);
                  },
            child: Text(state.busy ? l.liveSaving : l.liveSave),
          ),
      ],
    );
  }
}
