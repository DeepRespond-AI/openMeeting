import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test/acceptance/meeting_history_navigation_test.dart' show runMeetingHistoryFlow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(DateTime(2026)));
  testWidgets('home meeting end history on Android', (t) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39342'));
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..findProxy = (_) => 'DIRECT',
    );
    await dio.post<void>('/begin');
    Future<void> emit(Map<String, Object?> row) => dio.post<void>('/row', data: row);
    Future<void> shot(String name, GlobalKey _) =>
        dio.post<void>('/device-screenshot', data: {'name': name});
    try {
      await runMeetingHistoryFlow(t, emit: emit, native: true);
      await runMeetingHistoryFlow(t, emit: emit, native: true, capture: true, screenshot: shot);
      await dio.post<void>(
        '/done',
        data: {
          'passed': true,
          'scope': 'production navigation UI; repository/identity fixtures; no RTC',
        },
      );
    } catch (error) {
      await dio.post<void>('/done', data: {'passed': false, 'error': '$error'});
      rethrow;
    } finally {
      dio.close();
    }
  });
}
