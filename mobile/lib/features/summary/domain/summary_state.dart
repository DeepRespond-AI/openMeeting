import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api/api_exception.dart';
import 'summary_document.dart';

part 'summary_state.freezed.dart';

/// Why a generation ended without a summary (localized by the UI unless [SummaryFailed.message]
/// carries a server text).
enum SummaryFailure {
  /// Server reported `failed` / `error`.
  generation,

  /// Completed but the result had no visible content.
  emptyResult,

  /// `summaryMaxPolls` reached while still in progress.
  timeout,

  /// The server's LLM is not ready (capabilities).
  llmNotReady,

  /// Starting / polling the request failed (see [SummaryFailed.error]).
  request,
}

/// Summary tab state machine:
/// `empty | ready` → (generate) → `generating` → `ready | failed`; `stop` → back.
@freezed
sealed class SummaryState with _$SummaryState {
  /// No summary yet.
  const factory SummaryState.empty() = SummaryEmpty;

  /// A generation is running. [processId] = `process_id` of the run (`null` until the POST
  /// returned); poll responses with another `start` are ignored. [previous] keeps the
  /// old summary visible while regenerating.
  const factory SummaryState.generating({
    String? processId,
    SummaryDocument? previous,
    @Default(0) int polls,
  }) = SummaryGenerating;

  /// A summary is available. [fresh] = it was just produced by a generation of this session
  /// (the page then reloads the meeting title, which the server may have changed).
  const factory SummaryState.ready({required SummaryDocument summary, @Default(false) bool fresh}) =
      SummaryReady;

  /// The last generation failed. [previous] = summary still stored on the server
  /// (it restores the old one when a regeneration fails).
  const factory SummaryState.failed({
    required SummaryFailure reason,
    String? message,
    ApiException? error,
    SummaryDocument? previous,
  }) = SummaryFailed;

  const SummaryState._();

  bool get isGenerating => this is SummaryGenerating;

  /// The summary to display (current or previous).
  SummaryDocument? get visible => switch (this) {
    SummaryEmpty() => null,
    SummaryGenerating(:final previous) => previous,
    SummaryReady(:final summary) => summary,
    SummaryFailed(:final previous) => previous,
  };
}

extension SummaryAutoStart on SummaryState {
  /// True when there is nothing to show yet, so an automatic summary may start.
  bool get canAutoStart => switch (this) {
    SummaryEmpty() => true,
    SummaryFailed(:final previous) => previous == null,
    _ => false,
  };
}
