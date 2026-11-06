import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_exception_l10n.dart';
import '../../../core/api/meeting_recording.dart';
import '../../../core/api/models/meeting_models.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/data/background_work.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../import/domain/job_run_state.dart';
import '../../summary/domain/summary_state.dart';
import '../../summary/presentation/summary_controller.dart';
import '../../summary/presentation/summary_panel.dart';
import '../domain/meeting_detail_route.dart';
import '../domain/meeting_markdown.dart';
import 'meeting_detail_controller.dart';
import 'meeting_exporter.dart';
import 'meeting_formatting.dart';
import 'meeting_player_controller.dart';
import 'retranscribe_controller.dart';
import 'widgets/feedback.dart';
import 'widgets/meeting_player_bar.dart';
import 'widgets/recording_download.dart';
import 'widgets/retranscribe_sheet.dart';
import 'widgets/room_recording_status.dart';
import 'widgets/transcript_list.dart';

enum _MeetingAction { rename, copyTranscript, share, retranscribe, delete }

/// Tabs of the meeting page, in display order (desktop `MeetingDetailsTabs`).
enum _MeetingTab { info, transcript, summary }

/// Meeting detail: Meeting info (editable header, audio player) / Transcript / AI summary tabs
/// and an actions menu (rename, copy transcript, share Markdown, retranscribe, delete).
/// Opens on the info tab and switches to the summary once one exists or is being generated,
/// unless the user picked a tab.
///
/// While the meeting has background work ([MeetingSync]: recording sync, import
/// transcription) the transcript shows a processing state; it reloads when the work ends.
/// `?autoSummary=1` (see [MeetingDetailRoute]) starts a summary once on open when none exists,
/// after that background work.
class MeetingDetailPage extends ConsumerStatefulWidget {
  const MeetingDetailPage({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends ConsumerState<MeetingDetailPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _autoSummaryHandled = false;
  bool _tabChosen = false;
  late final TabController _tabs = TabController(length: _MeetingTab.values.length, vsync: this);

  String get _id => widget.meetingId;

  bool get _syncing => ref.read(meetingSyncProvider).contains(_id);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabs.dispose();
    super.dispose();
  }

  /// Shows the summary once it exists or is being generated (not after a manual choice).
  void _maybeShowSummary(SummaryState? summary) {
    if (_tabChosen || summary == null || _tabs.index == _MeetingTab.summary.index) return;
    if (summary is SummaryReady || summary is SummaryGenerating) {
      _tabs.animateTo(_MeetingTab.summary.index);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The summary may already be loaded (provider cached) → no change event would fire.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final summary = ref.read(summaryControllerProvider(_id)).value;
      _maybeShowSummary(summary);
      _maybeAutoSummary(summary).ignore();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    ref.invalidate(meetingRecordingProvider(_id));
    ref.invalidate(transcriptsControllerProvider(_id));
    ref.invalidate(summaryControllerProvider(_id));
  }

  Future<void> _maybeAutoSummary(SummaryState? summary) async {
    // Wait for the background work: the transcript is not complete before.
    if (_autoSummaryHandled || summary == null || !mounted || _syncing) return;
    final metadata = await ref.read(meetingDetailControllerProvider(_id).future);
    if (!mounted || !metadata.canManage) return;
    _autoSummaryHandled = true;
    final query = GoRouterState.of(context).uri.queryParameters;
    if (!MeetingDetailRoute.wantsAutoSummary(query)) return;
    if (!summary.canAutoStart) return;
    // Nothing was transcribed (e.g. silence): the server would only answer with an error.
    try {
      final transcripts = await ref.read(transcriptsControllerProvider(_id).future);
      if (transcripts.totalCount == 0) return;
    } on Object {
      return;
    }
    if (!mounted) return;
    ref.read(summaryControllerProvider(_id).notifier).generate().ignore();
    showSnack(context, ref, context.l10n.summaryAutoStarted);
  }

  String _formattedDate(MeetingMetadata meeting) {
    final created = meeting.createdAt;
    return created == null ? '' : formatMeetingDateTime(created, localeTagOf(context));
  }

  String _titleOf(String title) => title.trim().isEmpty ? context.l10n.meetingsUntitled : title;

  // ------------------------------------------------------------------ actions

  Future<void> _rename(MeetingMetadata meeting) async {
    final l10n = context.l10n;
    final title = await promptText(
      context,
      title: l10n.commonRename,
      initialValue: meeting.title,
      hint: l10n.meetingsTitleHint,
      emptyError: l10n.meetingsTitleEmpty,
      maxLength: ref.read(appConfigProvider).live.titleMax,
    );
    if (title == null || title == meeting.title || !mounted) return;
    try {
      await ref.read(meetingDetailControllerProvider(_id).notifier).rename(title);
      if (mounted) showSnack(context, ref, l10n.meetingsRenamed);
    } on Object catch (e) {
      if (mounted) {
        showSnack(context, ref, l10n.meetingsRenameFailed(describeError(e, l10n)), error: true);
      }
    }
  }

  Future<void> _copyTranscript(MeetingMetadata meeting) async {
    final l10n = context.l10n;
    try {
      final doc = await ref
          .read(meetingExporterProvider)
          .transcriptDocument(
            meeting.copyWith(title: _titleOf(meeting.title)),
            formattedDate: _formattedDate(meeting),
            labels: markdownLabelsOf(l10n),
          );
      if (!mounted) return;
      if (doc == null) {
        showSnack(context, ref, l10n.meetingsTranscriptCopyEmpty);
        return;
      }
      await Clipboard.setData(ClipboardData(text: doc));
      if (mounted) showSnack(context, ref, l10n.meetingsTranscriptCopied);
    } on Object catch (e) {
      if (mounted) {
        showSnack(context, ref, l10n.meetingsExportFailed(describeError(e, l10n)), error: true);
      }
    }
  }

  Future<void> _share(MeetingMetadata meeting) async {
    final l10n = context.l10n;
    final title = _titleOf(meeting.title);
    try {
      final doc = await ref
          .read(meetingExporterProvider)
          .meetingDocument(
            meeting.copyWith(title: title),
            formattedDate: _formattedDate(meeting),
            labels: markdownLabelsOf(l10n),
          );
      if (!mounted) return;
      if (doc == null) {
        showSnack(context, ref, l10n.meetingsShareEmpty);
        return;
      }
      await SharePlus.instance.share(ShareParams(text: doc, subject: title));
    } on Object catch (e) {
      if (mounted) {
        showSnack(context, ref, l10n.meetingsExportFailed(describeError(e, l10n)), error: true);
      }
    }
  }

  Future<void> _delete(MeetingMetadata meeting) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.meetingsDeleteTitle,
      message: l10n.meetingsDeleteMessage(_titleOf(meeting.title)),
      confirmLabel: l10n.commonDelete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(meetingDetailControllerProvider(_id).notifier).delete();
      if (!mounted) return;
      showSnack(context, ref, l10n.meetingsDeleted);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.meetings);
      }
    } on Object catch (e) {
      if (mounted) {
        showSnack(context, ref, l10n.meetingsDeleteFailed(describeError(e, l10n)), error: true);
      }
    }
  }

  Future<void> _onAction(_MeetingAction action, MeetingMetadata meeting) => switch (action) {
    _MeetingAction.rename => _rename(meeting),
    _MeetingAction.copyTranscript => _copyTranscript(meeting),
    _MeetingAction.share => _share(meeting),
    _MeetingAction.retranscribe => showRetranscribeSheet(context, _id),
    _MeetingAction.delete => _delete(meeting),
  };

  String _summaryDocument(MeetingMetadata meeting, String markdown) => buildSummaryMarkdown(
    title: _titleOf(meeting.title),
    meetingId: meeting.id,
    formattedDate: _formattedDate(meeting),
    summaryMarkdown: markdown,
    labels: markdownLabelsOf(context.l10n),
  );

  Future<void> _copySummary(MeetingMetadata meeting, String markdown) async {
    final l10n = context.l10n;
    if (markdown.trim().isEmpty) {
      showSnack(context, ref, l10n.summaryCopyEmpty);
      return;
    }
    await Clipboard.setData(ClipboardData(text: _summaryDocument(meeting, markdown)));
    if (mounted) showSnack(context, ref, l10n.summaryCopied);
  }

  Future<void> _shareSummary(MeetingMetadata meeting, String markdown) async {
    await SharePlus.instance.share(
      ShareParams(text: _summaryDocument(meeting, markdown), subject: _titleOf(meeting.title)),
    );
  }

  // ------------------------------------------------------------------ build

  void _listen() {
    final l10n = context.l10n;
    ref.listen(summaryControllerProvider(_id), (prev, next) {
      final value = next.value;
      _maybeShowSummary(value);
      _maybeAutoSummary(value).ignore();
      if (prev?.value is SummaryGenerating && value is SummaryReady && value.fresh) {
        // The server may rename the meeting from the summary.
        ref.read(meetingDetailControllerProvider(_id).notifier).reload().ignore();
        showSnack(context, ref, l10n.summaryCompleted);
      }
    });
    // The player lives in the info tab; keep it (and playback) alive on the other tabs.
    ref.listen(meetingPlayerControllerProvider(_id), (_, _) {});
    ref.listen(meetingRecordingProvider(_id), (previous, next) {
      final status = next.value?['status'];
      if (!next.isLoading &&
          previous?.value?['status'] != status &&
          ['completed', 'failed', 'cancelled'].contains(status)) {
        ref.invalidate(meetingDetailControllerProvider(_id));
        ref.invalidate(transcriptsControllerProvider(_id));
      }
    });
    // Background work finished: reload the transcript (and duration / title), then the
    // automatic summary may start.
    ref.listen(meetingSyncProvider.select((ids) => ids.contains(_id)), (was, syncing) {
      if (was != true || syncing) return;
      ref.invalidate(transcriptsControllerProvider(_id));
      ref.read(meetingDetailControllerProvider(_id).notifier).reload().ignore();
      _maybeAutoSummary(ref.read(summaryControllerProvider(_id)).value).ignore();
    });
    // The server removes the meeting of a failed import.
    ref.listen(backgroundNoticesProvider, (_, notice) {
      if (notice is ImportFailedNotice && notice.meetingId == _id) context.go(AppRoutes.meetings);
    });
    ref.listen(retranscribeControllerProvider(_id), (prev, next) {
      if (prev == next) return;
      switch (next) {
        case JobCompleted(:final job):
          showSnack(context, ref, l10n.meetingsRetranscribeComplete(job.segments ?? 0));
        case final JobFailed failed:
          showSnack(context, ref, describeJobFailure(failed, l10n), error: true);
        case JobCancelled():
          showSnack(context, ref, l10n.meetingsRetranscribeCancelled);
        case JobIdle() || JobUploading() || JobSubmitted() || JobRunning():
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _listen();
    final l10n = context.l10n;
    final metadata = ref.watch(meetingDetailControllerProvider(_id));
    final meeting = metadata.value;
    final syncing = ref.watch(meetingSyncProvider.select((ids) => ids.contains(_id)));
    final recording = ref.watch(meetingRecordingProvider(_id));

    return Scaffold(
      appBar: AppBar(
        title: Text(meeting == null ? l10n.navMeetingDetail : _titleOf(meeting.title)),
        actions: [
          if (meeting != null)
            PopupMenuButton<_MeetingAction>(
              tooltip: l10n.meetingsActions,
              onSelected: (a) => _onAction(a, meeting),
              itemBuilder: (_) => [
                if (meeting.canManage)
                  _menuItem(_MeetingAction.rename, Icons.edit_outlined, l10n.commonRename),
                _menuItem(
                  _MeetingAction.copyTranscript,
                  Icons.copy_outlined,
                  l10n.meetingsActionCopyTranscript,
                ),
                _menuItem(_MeetingAction.share, Icons.ios_share, l10n.meetingsActionShare),
                if (meeting.canManage)
                  _menuItem(
                    _MeetingAction.retranscribe,
                    Icons.replay_outlined,
                    l10n.meetingsActionRetranscribe,
                    enabled: meeting.hasAudio,
                  ),
                if (meeting.canManage)
                  _menuItem(
                    _MeetingAction.delete,
                    Icons.delete_outline,
                    l10n.meetingsActionDelete,
                    destructive: true,
                  ),
              ],
            ),
        ],
      ),
      body: AsyncValueView(
        value: metadata,
        onRetry: () => ref.invalidate(meetingDetailControllerProvider(_id)),
        data: (meeting) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: context.colors.surface,
              child: TabBar(
                controller: _tabs,
                onTap: (_) => _tabChosen = true,
                tabs: [
                  for (final tab in _MeetingTab.values)
                    Tab(
                      text: switch (tab) {
                        _MeetingTab.info => l10n.meetingsTabInfo,
                        _MeetingTab.transcript => l10n.meetingsTabTranscript,
                        _MeetingTab.summary => l10n.meetingsTabSummary,
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  for (final tab in _MeetingTab.values)
                    switch (tab) {
                      _MeetingTab.info => ListView(
                        children: [
                          _Header(
                            meeting: meeting,
                            onRename: meeting.canManage ? () => _rename(meeting) : null,
                          ),
                          if (!meeting.canManage)
                            Padding(
                              padding: context.spacing.card,
                              child: Text(l10n.liveSharedRecord),
                            ),
                          RoomRecordingStatus(meetingId: _id, canManage: meeting.canManage),
                          MeetingPlayerBar(meetingId: _id),
                          if (meeting.hasAudio) RecordingDownload(meetingId: _id),
                        ],
                      ),
                      _MeetingTab.transcript => TranscriptList(
                        meetingId: _id,
                        processing: syncing,
                        recordingStatus: recording.value?['status'] as String?,
                        statusError: recording.hasError,
                      ),
                      _MeetingTab.summary => SummaryPanel(
                        meetingId: _id,
                        onCopy: (md) => _copySummary(meeting, md),
                        onShare: (md) => _shareSummary(meeting, md),
                        canManage: meeting.canManage,
                      ),
                    },
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_MeetingAction> _menuItem(
    _MeetingAction action,
    IconData icon,
    String label, {
    bool enabled = true,
    bool destructive = false,
  }) {
    final color = destructive ? context.colors.destructive : null;
    return PopupMenuItem(
      value: action,
      enabled: enabled,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.meeting, required this.onRename});

  final MeetingMetadata meeting;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.spacing;
    final muted = context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground);
    final created = meeting.createdAt;
    final duration = (meeting.audioDuration ?? 0) > 0 ? formatClock(meeting.audioDuration) : null;
    final title = meeting.title.trim().isEmpty ? l10n.meetingsUntitled : meeting.title;
    return Container(
      color: context.colors.surface,
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onRename,
            borderRadius: context.radius.smAll,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: context.colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onRename != null) SizedBox(width: spacing.xxs),
                if (onRename != null)
                  Icon(
                    Icons.edit_outlined,
                    size: context.sizes.iconSm,
                    color: context.colors.mutedForeground,
                  ),
              ],
            ),
          ),
          SizedBox(height: spacing.xxs),
          Wrap(
            spacing: spacing.md,
            children: [
              if (created != null)
                Text(
                  l10n.meetingsCreatedAt(formatMeetingDateTime(created, localeTagOf(context))),
                  style: muted,
                ),
              if (duration != null) Text(l10n.meetingsDuration(duration), style: muted),
            ],
          ),
        ],
      ),
    );
  }
}
