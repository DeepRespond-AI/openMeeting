import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/models/summary_models.dart';
import '../domain/summary_repository.dart';

part 'summary_repository_impl.g.dart';

/// JSON field names of the summary endpoints (server/API.md §1.6).
abstract final class _SummaryFields {
  static const String customPrompt = 'custom_prompt';
  static const String language = 'language';
  static const String text = 'text';
  static const String summary = 'summary';
  static const String markdown = 'markdown';
}

class DioSummaryRepository implements SummaryRepository {
  DioSummaryRepository(this._dio);

  final Dio _dio;

  @override
  Future<ProcessStarted> start(String meetingId, {String? customPrompt}) => apiCall(() async {
    final prompt = customPrompt?.trim();
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.meetingSummary(meetingId),
      data: {
        _SummaryFields.customPrompt: (prompt == null || prompt.isEmpty) ? null : prompt,
        _SummaryFields.language: null,
        _SummaryFields.text: null,
      },
    );
    return ProcessStarted.fromJson(res.data!);
  });

  @override
  Future<SummaryResponse> get(String meetingId) => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.meetingSummary(meetingId));
    return SummaryResponse.fromJson(res.data!);
  });

  @override
  Future<void> cancel(String meetingId) => apiCall(() async {
    await _dio.delete<void>(Endpoints.meetingSummary(meetingId));
  });

  @override
  Future<void> saveMarkdown(String meetingId, String markdown) => apiCall(() async {
    await _dio.put<void>(
      Endpoints.meetingSummary(meetingId),
      data: {
        _SummaryFields.summary: {_SummaryFields.markdown: markdown},
      },
    );
  });
}

@Riverpod(keepAlive: true)
SummaryRepository summaryRepository(Ref ref) => DioSummaryRepository(ref.watch(apiClientProvider));
