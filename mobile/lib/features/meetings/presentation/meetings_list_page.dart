import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception_l10n.dart';
import '../../../core/api/models/meeting_models.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/brand_logo.dart';
import '../domain/meeting_search.dart';
import 'meeting_detail_controller.dart';
import 'meeting_formatting.dart';
import 'meetings_list_controller.dart';
import 'widgets/feedback.dart';
import 'widgets/server_status_banner.dart';

/// Home: branded app bar, transcript search, meeting list with pull-to-refresh and
/// swipe-to-delete, "start recording" FAB and "import audio" action.
class MeetingsListPage extends ConsumerWidget {
  const MeetingsListPage({this.upcoming, super.key});
  final Widget? upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final importEnabled = ref.watch(appConfigProvider.select((c) => c.features.importAudio));
    final searching = ref.watch(meetingSearchControllerProvider.select((s) => s.isActive));

    return DefaultTabController(
      length: upcoming == null ? 1 : 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: upcoming == null
              ? null
              : TabBar(
                  tabs: [
                    Tab(text: l10n.liveHistoryRecords),
                    Tab(text: l10n.liveUpcomingTab),
                  ],
                ),
          title: Row(
            children: [
              const BrandLogo(),
              context.spacing.gapSm,
              Flexible(child: Text(l10n.appName, overflow: TextOverflow.ellipsis)),
            ],
          ),
          actions: [
            if (importEnabled)
              IconButton(
                tooltip: l10n.meetingsImportAudio,
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: () => context.push(AppRoutes.import),
              ),
            IconButton(
              tooltip: l10n.navSettings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(AppRoutes.recording),
          icon: const Icon(Icons.mic_none),
          label: Text(l10n.meetingsStartRecording),
        ),
        body: upcoming == null
            ? _historyBody(searching)
            : TabBarView(children: [_historyBody(searching), upcoming!]),
      ),
    );
  }

  Widget _historyBody(bool searching) => Column(
    children: [
      const ServerStatusBanner(),
      const _SearchField(),
      Expanded(child: searching ? const _SearchResults() : const _MeetingsList()),
    ],
  );
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(meetingSearchControllerProvider.notifier);
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.md, spacing.sm, spacing.md, spacing.xs),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) => TextField(
          controller: _controller,
          onChanged: notifier.setQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.meetingsSearchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: context.l10n.meetingsSearchClear,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _controller.clear();
                      notifier.clear();
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _MeetingsList extends ConsumerWidget {
  const _MeetingsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetings = ref.watch(meetingsListControllerProvider);
    final controller = ref.read(meetingsListControllerProvider.notifier);
    return AsyncValueView(
      value: meetings,
      onRetry: controller.refresh,
      data: (items) => RefreshIndicator(
        onRefresh: controller.refresh,
        child: items.isEmpty
            ? const _EmptyState()
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  context.spacing.md,
                  context.spacing.xs,
                  context.spacing.md,
                  context.sizes.buttonHeight + context.spacing.xxl, // FAB clearance
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => context.spacing.gapXs,
                itemBuilder: (context, i) => _DismissibleMeetingCard(meeting: items[i]),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A scrollable so pull-to-refresh still works on an empty list.
    return ListView(
      padding: context.spacing.page,
      children: [
        SizedBox(height: context.spacing.xxl),
        Icon(Icons.event_note_outlined, size: context.sizes.logoLg, color: context.colors.brand200),
        context.spacing.gapMd,
        Text(
          l10n.meetingsEmpty,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.copyWith(color: context.colors.foreground),
        ),
        context.spacing.gapXs,
        Text(
          l10n.meetingsEmptyHint,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(color: context.colors.mutedForeground),
        ),
      ],
    );
  }
}

class _DismissibleMeetingCard extends ConsumerWidget {
  const _DismissibleMeetingCard({required this.meeting});

  final MeetingSummary meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Dismissible(
      key: ValueKey(meeting.id),
      direction: meeting.canManage ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsetsDirectional.only(end: context.spacing.lg),
        decoration: BoxDecoration(color: colors.destructive, borderRadius: context.radius.mdAll),
        child: Icon(Icons.delete_outline, color: colors.onDestructive),
      ),
      confirmDismiss: (_) => confirmDialog(
        context,
        title: l10n.meetingsDeleteTitle,
        message: l10n.meetingsDeleteMessage(_titleOf(context, meeting.title)),
        confirmLabel: l10n.commonDelete,
        destructive: true,
      ),
      onDismissed: (_) async {
        try {
          await ref.read(meetingsListControllerProvider.notifier).deleteMeeting(meeting.id);
          if (context.mounted) showSnack(context, ref, l10n.meetingsDeleted);
        } on Object catch (e) {
          if (context.mounted) {
            showSnack(context, ref, l10n.meetingsDeleteFailed(describeError(e, l10n)), error: true);
          }
        }
      },
      child: _MeetingCard(meeting: meeting),
    );
  }
}

String _titleOf(BuildContext context, String title) =>
    title.trim().isEmpty ? context.l10n.meetingsUntitled : title;

class _MeetingCard extends ConsumerWidget {
  const _MeetingCard({required this.meeting});

  final MeetingSummary meeting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The list endpoint returns created_at; older servers only send id + title, in which
    // case fall back to the (lazily loaded) per-meeting metadata.
    final createdAt =
        meeting.createdAt ??
        ref.watch(meetingDetailControllerProvider(meeting.id).select((m) => m.value?.createdAt));
    final maxDays = ref.watch(appConfigProvider.select((c) => c.meetingsUi.relativeDateMaxDays));
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: _MeetingIcon(),
        title: Text(
          _titleOf(context, meeting.title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleSmall?.copyWith(color: context.colors.foreground),
        ),
        subtitle: createdAt == null
            ? null
            : Text(
                formatRelativeDate(
                  createdAt,
                  now: DateTime.now(),
                  maxDays: maxDays,
                  l10n: context.l10n,
                  locale: localeTagOf(context),
                ),
                style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
              ),
        trailing: Icon(Icons.chevron_right, color: context.colors.mutedForeground),
        onTap: () => context.push(AppRoutes.meetingDetail(meeting.id)),
      ),
    );
  }
}

class _MeetingIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.sizes.touchTarget,
      height: context.sizes.touchTarget,
      decoration: BoxDecoration(color: context.colors.brand50, borderRadius: context.radius.mdAll),
      child: Icon(Icons.graphic_eq, color: context.colors.brand600, size: context.sizes.iconMd),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(meetingSearchControllerProvider);
    final notifier = ref.read(meetingSearchControllerProvider.notifier);
    final meetings = ref.watch(meetingsListControllerProvider);
    return AsyncValueView(
      value: meetings,
      onRetry: ref.read(meetingsListControllerProvider.notifier).refresh,
      data: (items) {
        final results = matchingMeetings(items, search.query, search.results.value ?? const []);
        if (results.isEmpty) {
          if (search.results.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (search.results.hasError) {
            return ErrorView(error: search.results.error!, onRetry: notifier.retry);
          }
          return Center(
            child: Text(
              context.l10n.meetingsSearchEmpty,
              style: context.textTheme.bodyMedium?.copyWith(color: context.colors.mutedForeground),
            ),
          );
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(
            context.spacing.md,
            context.spacing.xs,
            context.spacing.md,
            context.sizes.buttonHeight + context.spacing.xxl,
          ),
          children: [
            if (search.results.isLoading) const LinearProgressIndicator(),
            if (search.results.hasError)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.spacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.meetingsSearchPartialWarning,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ),
                    context.spacing.gapXs,
                    TextButton(onPressed: notifier.retry, child: Text(context.l10n.commonRetry)),
                  ],
                ),
              ),
            for (final r in results) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  title: Text(
                    _titleOf(context, r.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall,
                  ),
                  subtitle: r.matchContext.isEmpty
                      ? null
                      : _Highlighted(text: r.matchContext, query: search.query),
                  onTap: () => context.push(AppRoutes.meetingDetail(r.id)),
                ),
              ),
              context.spacing.gapXs,
            ],
          ],
        );
      },
    );
  }
}

/// [text] with every case-insensitive occurrence of [query] emphasised.
class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final base = context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground);
    final mark = base?.copyWith(
      color: context.colors.onAccent,
      backgroundColor: context.colors.accent,
      fontWeight: FontWeight.w600,
    );
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    var start = 0;
    while (q.isNotEmpty) {
      final i = lower.indexOf(q, start);
      if (i < 0) break;
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(TextSpan(text: text.substring(i, i + q.length), style: mark));
      start = i + q.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
