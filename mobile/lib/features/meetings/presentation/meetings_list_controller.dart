import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/models/meeting_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/data/meetings_changed.dart';
import '../data/meetings_repository_impl.dart';

part 'meetings_list_controller.freezed.dart';
part 'meetings_list_controller.g.dart';

/// Meeting list state. Reloads when the signed-in user changes or meetings change elsewhere.
@riverpod
class MeetingsListController extends _$MeetingsListController {
  @override
  Future<List<MeetingSummary>> build() {
    ref.watch(currentUserProvider.select((u) => u?.id));
    // Recording / import created a meeting elsewhere → reload.
    ref.watch(meetingsChangedProvider);
    return ref.watch(meetingsRepositoryProvider).listMeetings();
  }

  /// Pull-to-refresh: re-runs [build] while keeping the current list visible
  /// (state becomes AsyncLoading with the previous value). Errors land in state.
  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Surfaced through `state` (AsyncError); nothing to rethrow for RefreshIndicator.
    }
  }

  /// Optimistically removes the meeting, then deletes it on the server. On failure the item
  /// is put back at its original position and the error is rethrown (the UI shows it).
  Future<void> deleteMeeting(String id) async {
    final before = state.value;
    if (before != null) {
      state = AsyncData([
        for (final m in before)
          if (m.id != id) m,
      ]);
    }
    try {
      await ref.read(meetingsRepositoryProvider).delete(id);
    } on Object {
      if (ref.mounted && before != null) {
        final current = state.value ?? const <MeetingSummary>[];
        final index = before.indexWhere((m) => m.id == id);
        final restored = [...current];
        if (index >= 0 && !restored.any((m) => m.id == id)) {
          restored.insert(index.clamp(0, restored.length), before[index]);
        }
        state = AsyncData(restored);
      }
      rethrow;
    }
  }

  /// Applies a change made elsewhere (detail page) without refetching.
  void applyTitle(String id, String title) {
    final items = state.value;
    if (items == null) return;
    state = AsyncData([for (final m in items) m.id == id ? m.copyWith(title: title) : m]);
  }

  /// Drops a meeting deleted elsewhere (detail page).
  void removeLocally(String id) {
    final items = state.value;
    if (items == null) return;
    state = AsyncData([
      for (final m in items)
        if (m.id != id) m,
    ]);
  }
}

/// Search box state; the page combines transcript hits with local title matches.
@freezed
abstract class MeetingSearchState with _$MeetingSearchState {
  const factory MeetingSearchState({
    /// Current (trimmed) query; empty = not searching (the list is shown).
    @Default('') String query,
    @Default(AsyncData<List<TranscriptSearchResult>>(<TranscriptSearchResult>[]))
    AsyncValue<List<TranscriptSearchResult>> results,
  }) = _MeetingSearchState;

  const MeetingSearchState._();

  bool get isActive => query.isNotEmpty;
}

/// Debounced transcript search (`AppConfig.pagination.meetingSearchDebounce`); responses for
/// an outdated query are dropped.
@riverpod
class MeetingSearchController extends _$MeetingSearchController {
  Timer? _debounce;
  int _generation = 0;

  @override
  MeetingSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const MeetingSearchState();
  }

  void setQuery(String raw) {
    final query = raw.trim();
    if (query == state.query) return;
    _debounce?.cancel();
    final generation = ++_generation;
    if (query.isEmpty) {
      state = const MeetingSearchState();
      return;
    }
    state = state.copyWith(
      query: query,
      results: const AsyncLoading<List<TranscriptSearchResult>>(),
    );
    final delay = ref.read(appConfigProvider).pagination.meetingSearchDebounce;
    _debounce = Timer(delay, () => unawaited(_run(query, generation)));
  }

  /// Runs the current query again (retry button).
  Future<void> retry() async {
    if (state.query.isEmpty) return;
    _debounce?.cancel();
    state = state.copyWith(results: const AsyncLoading<List<TranscriptSearchResult>>());
    await _run(state.query, ++_generation);
  }

  void clear() => setQuery('');

  Future<void> _run(String query, int generation) async {
    final result = await AsyncValue.guard(
      () => ref.read(meetingsRepositoryProvider).searchTranscripts(query),
    );
    if (!ref.mounted || _generation != generation) return;
    state = state.copyWith(results: result);
  }
}
