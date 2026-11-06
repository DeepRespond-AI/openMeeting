import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/models/meeting_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/data/meetings_changed.dart';
import '../data/meetings_repository_impl.dart';
import 'meetings_list_controller.dart';

part 'meeting_detail_controller.freezed.dart';
part 'meeting_detail_controller.g.dart';

/// Meeting metadata (title, created time, duration). Also watched by list cards for the date.
@riverpod
class MeetingDetailController extends _$MeetingDetailController {
  @override
  Future<MeetingMetadata> build(String meetingId) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    ref.watch(meetingsChangedProvider);
    return ref.watch(meetingsRepositoryProvider).getMetadata(meetingId);
  }

  /// Re-fetches metadata keeping the current value visible (e.g. after the summary renamed it).
  Future<void> reload() async {
    final result = await AsyncValue.guard(
      () => ref.read(meetingsRepositoryProvider).getMetadata(meetingId),
    );
    if (!ref.mounted) return;
    if (result case AsyncData(:final value)) {
      state = result;
      _syncList(value.title);
    }
  }

  /// Optimistic rename; rolls back and rethrows on failure.
  Future<void> rename(String title) async {
    final before = state.value;
    if (before != null) state = AsyncData(before.copyWith(title: title));
    try {
      final saved = await ref.read(meetingsRepositoryProvider).rename(meetingId, title);
      if (!ref.mounted) return;
      state = AsyncData(saved);
      _syncList(saved.title);
    } on Object {
      if (ref.mounted && before != null) state = AsyncData(before);
      rethrow;
    }
  }

  /// Deletes the meeting on the server and drops it from the list.
  Future<void> delete() async {
    await ref.read(meetingsRepositoryProvider).delete(meetingId);
    if (ref.exists(meetingsListControllerProvider)) {
      ref.read(meetingsListControllerProvider.notifier).removeLocally(meetingId);
    }
  }

  void _syncList(String title) {
    if (ref.exists(meetingsListControllerProvider)) {
      ref.read(meetingsListControllerProvider.notifier).applyTitle(meetingId, title);
    }
  }
}

/// Paginated transcript rows of one meeting.
@freezed
abstract class TranscriptsState with _$TranscriptsState {
  const factory TranscriptsState({
    @Default(<MeetingTranscript>[]) List<MeetingTranscript> items,
    @Default(0) int totalCount,
    @Default(false) bool hasMore,
    @Default(false) bool loadingMore,

    /// Failure of the last [TranscriptsController.loadMore] (first page errors → AsyncError).
    Object? loadMoreError,
  }) = _TranscriptsState;
}

/// Transcript list with infinite scrolling (`AppConfig.pagination.transcriptPageSize`).
@riverpod
class TranscriptsController extends _$TranscriptsController {
  int get _pageSize => ref.read(appConfigProvider).pagination.transcriptPageSize;

  @override
  Future<TranscriptsState> build(String meetingId) async {
    ref.watch(currentUserProvider.select((user) => user?.id));
    final page = await ref
        .watch(meetingsRepositoryProvider)
        .getTranscripts(meetingId, limit: _pageSize, offset: 0);
    return TranscriptsState(
      items: page.transcripts,
      totalCount: page.totalCount,
      hasMore: page.hasMore,
    );
  }

  /// Loads the next page (no-op while loading or when everything is loaded).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, loadMoreError: null));
    try {
      final page = await ref
          .read(meetingsRepositoryProvider)
          .getTranscripts(meetingId, limit: _pageSize, offset: current.items.length);
      if (!ref.mounted) return;
      final known = {for (final t in current.items) t.id};
      state = AsyncData(
        current.copyWith(
          items: [
            ...current.items,
            for (final t in page.transcripts)
              if (!known.contains(t.id)) t,
          ],
          totalCount: page.totalCount,
          hasMore: page.hasMore,
          loadingMore: false,
        ),
      );
    } on Object catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: e));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Surfaced through `state`.
    }
  }
}
