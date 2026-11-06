import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/session_controller.dart';
import '../config/app_config_provider.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'endpoints.dart';

part 'meeting_recording.g.dart';

@riverpod
Future<Map<String, dynamic>> meetingRecording(Ref ref, String id) async {
  ref.watch(currentUserProvider);
  try {
    return await apiCall(() async {
      final response = await ref
          .watch(apiClientProvider)
          .get<Map<String, dynamic>>(Endpoints.meetingRecording(id));
      return response.data!;
    });
  } finally {
    // The detail page owns the subscription across tabs. Recover from temporary
    // read errors and observe the host retry even when this client saw a failure.
    if (ref.mounted) {
      final timer = Timer(ref.read(appConfigProvider).polling.jobInterval, ref.invalidateSelf);
      ref.onDispose(timer.cancel);
    }
  }
}

@riverpod
class RecordingRetry extends _$RecordingRetry {
  @override
  FutureOr<void> build(String id) {}
  Future<bool> retry() async {
    if (state.isLoading) return false;
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => apiCall(() async {
        await ref.read(apiClientProvider).post<void>(Endpoints.meetingRecordingRetry(id));
      }),
    );
    if (!ref.mounted) return false;
    state = next;
    if (!state.hasError) ref.invalidate(meetingRecordingProvider(id));
    return !state.hasError;
  }
}
