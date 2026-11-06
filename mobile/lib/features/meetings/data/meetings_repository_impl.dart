import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/models/meeting_models.dart';
import '../domain/meeting_audio_source.dart';
import '../domain/meetings_repository.dart';

part 'meetings_repository_impl.g.dart';

/// HTTP header names / values used by the audio probe.
abstract final class _AudioProbe {
  static const String range = 'Range';

  /// Smallest possible range: the probe must not download the recording.
  static const String firstByte = 'bytes=0-0';
}

class DioMeetingsRepository implements MeetingsRepository {
  DioMeetingsRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<MeetingSummary>> listMeetings() => apiCall(() async {
    final res = await _dio.get<List<dynamic>>(Endpoints.meetings);
    return [
      for (final item in res.data ?? const <dynamic>[])
        MeetingSummary.fromJson(item as Map<String, dynamic>),
    ];
  });

  @override
  Future<List<TranscriptSearchResult>> searchTranscripts(String query) => apiCall(() async {
    final res = await _dio.get<List<dynamic>>(
      Endpoints.transcriptSearch,
      queryParameters: {QueryParams.query: query},
    );
    return [
      for (final item in res.data ?? const <dynamic>[])
        TranscriptSearchResult.fromJson(item as Map<String, dynamic>),
    ];
  });

  @override
  Future<MeetingMetadata> getMetadata(String meetingId) => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.meetingMetadata(meetingId));
    return MeetingMetadata.fromJson(res.data!);
  });

  @override
  Future<PaginatedTranscripts> getTranscripts(
    String meetingId, {
    required int limit,
    required int offset,
  }) => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      Endpoints.meetingTranscripts(meetingId),
      queryParameters: {QueryParams.limit: limit, QueryParams.offset: offset},
    );
    return PaginatedTranscripts.fromJson(res.data!);
  });

  @override
  Future<MeetingMetadata> rename(String meetingId, String title) => apiCall(() async {
    final res = await _dio.patch<Map<String, dynamic>>(
      Endpoints.meeting(meetingId),
      data: {'title': title},
    );
    return MeetingMetadata.fromJson(res.data!);
  });

  @override
  Future<void> delete(String meetingId) => apiCall(() async {
    await _dio.delete<void>(Endpoints.meeting(meetingId));
  });

  @override
  Future<MeetingAudioSource> resolveAudio(String meetingId) => apiCall(() async {
    final Response<ResponseBody> res;
    try {
      res = await _dio.get<ResponseBody>(
        Endpoints.meetingAudio(meetingId),
        options: Options(
          followRedirects: false,
          responseType: ResponseType.stream,
          headers: {_AudioProbe.range: _AudioProbe.firstByte},
          validateStatus: (status) => status != null && status < HttpStatus.badRequest,
        ),
      );
    } on DioException catch (e) {
      final error = ApiException.fromDio(e);
      if (error.kind == ApiErrorKind.notFound) return const MeetingAudioSource.none();
      throw await _withStreamedDetail(error, e.response);
    }
    // Never consume the body: the probe only needs the status line / headers.
    await res.data?.stream.listen(null).cancel();
    final requestUri = res.requestOptions.uri;
    if (res.isRedirect || _isRedirectStatus(res.statusCode)) {
      final location = res.headers.value(HttpHeaders.locationHeader);
      if (location == null || location.isEmpty) {
        throw const ApiException(kind: ApiErrorKind.unknown);
      }
      return MeetingAudioSource.redirect(requestUri.resolve(location));
    }
    final auth = res.requestOptions.headers[AuthHeader.name];
    return MeetingAudioSource.direct(requestUri, {if (auth is String) AuthHeader.name: auth});
  });

  /// The probe uses a streamed response, so the error interceptor could not read the JSON
  /// `detail`; read it here.
  static Future<ApiException> _withStreamedDetail(
    ApiException error,
    Response<dynamic>? response,
  ) async {
    final body = response?.data;
    final status = response?.statusCode;
    if (body is! ResponseBody || status == null || error.message != null) return error;
    try {
      final text = await utf8.decodeStream(body.stream);
      Object? json;
      try {
        json = jsonDecode(text);
      } on FormatException {
        json = text;
      }
      return ApiException.fromResponse(status, json, cause: error.cause);
    } on Object {
      return error;
    }
  }

  static bool _isRedirectStatus(int? status) =>
      status != null &&
      status >= HttpStatus.multipleChoices &&
      status < HttpStatus.badRequest &&
      status != HttpStatus.notModified;
}

/// Override in tests: `meetingsRepositoryProvider.overrideWithValue(FakeMeetingsRepository())`.
@Riverpod(keepAlive: true)
MeetingsRepository meetingsRepository(Ref ref) =>
    DioMeetingsRepository(ref.watch(apiClientProvider));
