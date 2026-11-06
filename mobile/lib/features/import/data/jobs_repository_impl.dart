import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/direct_upload.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/api/models/job_models.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_config_provider.dart';
import '../domain/jobs_repository.dart';

part 'jobs_repository_impl.g.dart';

/// Multipart / JSON field names of the job endpoints (server/API.md §1.5).
abstract final class _JobFields {
  static const String file = 'file';
  static const String title = 'title';
  static const String language = 'language';
  static const String meetingId = 'meeting_id';
}

class DioJobsRepository implements JobsRepository {
  DioJobsRepository(this._dio, this._network);

  final Dio _dio;
  final NetworkConfig _network;

  @override
  Future<Job> startImport(
    ImportUpload upload, {
    TransferProgress? onProgress,
    CancellationSignal? cancel,
  }) => apiCall(() async {
    final token = CancelToken();
    unawaited(cancel?.whenCancelled.then((_) => token.cancel()));
    if (cancel?.isCancelled ?? false) token.cancel();
    final direct = await directFileUpload(
      _dio,
      _network,
      Endpoints.jobsImport,
      File(upload.filePath),
      fileName: upload.fileName,
      extra: {_JobFields.title: upload.title, _JobFields.language: upload.language},
      cancelToken: token,
      onProgress: onProgress,
    );
    if (direct != null) return Job.fromJson(direct);
    final form = FormData.fromMap({
      _JobFields.file: await MultipartFile.fromFile(upload.filePath, filename: upload.fileName),
      _JobFields.title: upload.title,
      if (upload.language != null) _JobFields.language: upload.language,
    });
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.jobsImport,
      data: form,
      options: transferOptions(_network),
      cancelToken: token,
      onSendProgress: onProgress,
    );
    return Job.fromJson(res.data!);
  });

  @override
  Future<Job> retranscribe(String meetingId, {String? language}) => apiCall(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      Endpoints.jobsRetranscribe,
      data: {_JobFields.meetingId: meetingId, _JobFields.language: language},
    );
    return Job.fromJson(res.data!);
  });

  @override
  Future<Job> getJob(String jobId) => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(Endpoints.job(jobId));
    return Job.fromJson(res.data!);
  });

  @override
  Future<Job> cancelJob(String jobId) => apiCall(() async {
    final res = await _dio.delete<Map<String, dynamic>>(Endpoints.job(jobId));
    return Job.fromJson(res.data!);
  });
}

@Riverpod(keepAlive: true)
JobsRepository jobsRepository(Ref ref) => DioJobsRepository(
  ref.watch(apiClientProvider),
  ref.watch(appConfigProvider.select((c) => c.network)),
);
