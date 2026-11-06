import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/models/summary_models.dart';
import '../../../core/api/retry.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/heartbeat/heartbeat_controller.dart';
import '../data/summary_repository_impl.dart';
import '../domain/summary_content.dart';
import '../domain/summary_document.dart';
import '../domain/summary_state.dart';

part 'summary_controller.g.dart';

Future<void> _defaultSleep(Duration d) => Future<void>.delayed(d);

/// Sleep used between summary polls; overridden in tests.
@riverpod
Sleeper summaryPollSleeper(Ref ref) => _defaultSleep;

/// Summary tab state machine for one meeting (desktop `useSummaryGeneration`):
/// - `build` restores the stored summary and resumes polling if one is in progress;
/// - [generate] POSTs (the server picks the template), then polls every
///   `AppConfig.polling.summaryInterval` up to `summaryMaxPolls`; `pending`/`processing` mean
///   in progress; responses whose `start` differs from our `process_id` are ignored;
/// - [stop] DELETEs and restores the previous summary;
/// - [save] PUTs `{"summary":{"markdown": md}}` (Markdown summaries only; HTML / mixed are read-only).
///
/// The server may rename the meeting when a summary completes: the detail page listens for
/// `generating → ready` and reloads the meeting metadata.
@riverpod
class SummaryController extends _$SummaryController {
  /// Incremented to abandon an older polling loop.
  int _generation = 0;

  @override
  Future<SummaryState> build(String meetingId) async {
    ref.watch(currentUserProvider);
    ref.onDispose(() => _generation++);
    final res = await ref.watch(summaryRepositoryProvider).get(meetingId);
    final restored = _stateFrom(res);
    if (restored is SummaryGenerating && restored.processId != null) {
      final generation = ++_generation;
      scheduleMicrotask(() => unawaited(_poll(restored.processId!, generation)));
    }
    return restored;
  }

  SummaryState? get _current => state.value;

  /// Starts (or restarts) a generation.
  Future<void> generate({String? customPrompt}) async {
    final current = _current;
    if (current == null || current.isGenerating) return;
    final previous = current.visible;
    final llm = ref.read(capabilitiesProvider)?.llm;
    if (llm != null && !llm.ready) {
      state = AsyncData(
        SummaryState.failed(reason: SummaryFailure.llmNotReady, previous: previous),
      );
      return;
    }
    final generation = ++_generation;
    state = AsyncData(SummaryState.generating(previous: previous));
    final ProcessStarted started;
    try {
      started = await ref
          .read(summaryRepositoryProvider)
          .start(meetingId, customPrompt: customPrompt);
    } on Object catch (e) {
      if (!_isCurrent(generation)) return;
      state = AsyncData(
        SummaryState.failed(
          reason: SummaryFailure.request,
          error: ApiException.from(e),
          previous: previous,
        ),
      );
      return;
    }
    if (!_isCurrent(generation)) return;
    state = AsyncData(SummaryState.generating(processId: started.processId, previous: previous));
    await _poll(started.processId, generation);
  }

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  Future<void> _poll(String processId, int generation) async {
    final polling = ref.read(appConfigProvider).polling;
    final sleep = ref.read(summaryPollSleeperProvider);
    final repo = ref.read(summaryRepositoryProvider);
    for (var i = 0; i < polling.summaryMaxPolls; i++) {
      await sleep(polling.summaryInterval);
      if (!_isCurrent(generation)) return;
      final SummaryResponse res;
      try {
        res = await repo.get(meetingId);
      } on Object {
        // Transient polling error: keep polling (bounded by summaryMaxPolls).
        continue;
      }
      if (!_isCurrent(generation)) return;
      final current = _current;
      if (current is SummaryGenerating) {
        state = AsyncData(current.copyWith(polls: i + 1));
      }
      if (res.start != processId) continue; // stale response of another run
      if (res.status.isInProgress) continue;
      final next = _finalState(res, current?.visible, fresh: true);
      state = AsyncData(next);
      return;
    }
    if (!_isCurrent(generation)) return;
    state = AsyncData(
      SummaryState.failed(reason: SummaryFailure.timeout, previous: _current?.visible),
    );
  }

  /// Stops the running generation (`DELETE`) and shows the previous summary again.
  /// Errors are rethrown for the UI.
  Future<void> stop() async {
    final current = _current;
    if (current is! SummaryGenerating) return;
    await ref.read(summaryRepositoryProvider).cancel(meetingId);
    _generation++;
    if (!ref.mounted) return;
    final previous = current.previous;
    state = AsyncData(
      previous == null ? const SummaryState.empty() : SummaryState.ready(summary: previous),
    );
  }

  /// Saves an edited Markdown summary. Rethrows `ApiException` (400 empty/invalid, 404 no summary).
  Future<void> save(String markdown) async {
    await ref.read(summaryRepositoryProvider).saveMarkdown(meetingId, markdown);
    if (ref.mounted) {
      state = AsyncData(SummaryState.ready(summary: SummaryDocument(content: markdown)));
    }
  }

  /// State for a response that is not (or no longer) in progress.
  static SummaryState _finalState(
    SummaryResponse res,
    SummaryDocument? previous, {
    bool fresh = false,
  }) {
    final document = SummaryContent.documentOf(res.data);
    switch (res.status) {
      case SummaryStatus.completed:
        return document != null
            ? SummaryState.ready(summary: document, fresh: fresh)
            : SummaryState.failed(
                reason: SummaryFailure.emptyResult,
                message: res.error,
                previous: previous,
              );
      case SummaryStatus.failed || SummaryStatus.error:
        return SummaryState.failed(
          reason: SummaryFailure.generation,
          message: res.error,
          previous: document ?? previous,
        );
      case SummaryStatus.cancelled ||
          SummaryStatus.idle ||
          SummaryStatus.unknown ||
          SummaryStatus.pending ||
          SummaryStatus.processing:
        final shown = document ?? previous;
        return shown != null ? SummaryState.ready(summary: shown) : const SummaryState.empty();
    }
  }

  /// Initial state from the stored summary.
  static SummaryState _stateFrom(SummaryResponse res) {
    final document = SummaryContent.documentOf(res.data);
    if (res.status.isInProgress) {
      return SummaryState.generating(processId: res.start, previous: document);
    }
    return _finalState(res, null);
  }
}
