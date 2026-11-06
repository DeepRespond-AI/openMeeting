import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/direct_upload.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/models/meeting_models.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../domain/recording_repository.dart';
import '../domain/segment_upload.dart';

part 'recording_repository_impl.g.dart';

/// Decimal places of `start`/`end` query values (server/API.md §1.2: three decimals).
const int segmentTimeFractionDigits = 3;

class DioRecordingRepository implements RecordingRepository {
  DioRecordingRepository(this._dio, this._config);

  final Dio _dio;
  final AppConfig _config;

  @override
  Future<MeetingMetadata> createMeeting(String title) => apiCall(() async {
    final res = await _dio.post<Map<String, dynamic>>(Endpoints.meetings, data: {'title': title});
    return MeetingMetadata.fromJson(res.data!);
  });

  @override
  Future<SegmentResult> uploadSegment(SegmentUpload upload, Uint8List pcm) => apiCall(() async {
    final language = upload.language;
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.meetingSegments(upload.meetingId),
      queryParameters: {
        QueryParams.seq: upload.seq,
        QueryParams.start: upload.startSec.toStringAsFixed(segmentTimeFractionDigits),
        QueryParams.end: upload.endSec.toStringAsFixed(segmentTimeFractionDigits),
        QueryParams.language: ?language,
      },
      data: Stream<List<int>>.value(pcm),
      options: Options(
        contentType: _config.recording.segmentContentType,
        headers: {Headers.contentLengthHeader: pcm.length},
      ),
    );
    return SegmentResult.fromJson(res.data!);
  });

  @override
  Future<AudioUploadResult> uploadAudio(
    String meetingId,
    File file, {
    double? duration,
    UploadProgress? onProgress,
  }) => apiCall(() async {
    final direct = await directFileUpload(
      _dio,
      _config.network,
      Endpoints.meetingAudio(meetingId),
      file,
      fileName: _config.recording.audioUploadFileName,
      extra: {'duration': duration},
      onProgress: onProgress,
    );
    if (direct != null) return AudioUploadResult.fromJson(direct);
    final length = await file.length();
    final res = await _dio.put<Map<String, dynamic>>(
      Endpoints.meetingAudio(meetingId),
      queryParameters: {QueryParams.filename: _config.recording.audioUploadFileName},
      data: file.openRead(),
      options: transferOptions(
        _config.network,
        contentType: _config.recording.audioContentType,
        headers: {Headers.contentLengthHeader: length},
      ),
      onSendProgress: onProgress,
    );
    return AudioUploadResult.fromJson(res.data!);
  });

  @override
  Future<void> renameMeeting(String meetingId, String title) => apiCall(() async {
    await _dio.patch<Object?>(Endpoints.meeting(meetingId), data: {'title': title});
  });

  @override
  Future<void> deleteMeeting(String meetingId) => apiCall(() async {
    await _dio.delete<Object?>(Endpoints.meeting(meetingId));
  });
}

/// Override in tests with a fake.
@Riverpod(keepAlive: true)
RecordingRepository recordingRepository(Ref ref) =>
    DioRecordingRepository(ref.watch(apiClientProvider), ref.watch(appConfigProvider));
