import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test/acceptance/home_grid_ui_test.dart' show runHomeGridFlow;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(DateTime(2026)));
  testWidgets('native home entries, schedule recovery and adaptive gallery', (t) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39352'));
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..findProxy = (_) => 'DIRECT',
    );
    await dio.post<void>('/begin');
    Future<void> emit(Map<String, Object?> row) => dio.post<void>('/row', data: row);
    Future<void> shot(String name, GlobalKey _) =>
        dio.post<void>('/device-screenshot', data: {'name': name});

    try {
      await runHomeGridFlow(t, emit: emit, native: true);
      await runHomeGridFlow(t, emit: emit, native: true, capture: true, screenshot: shot);
      await dio.post<void>(
        '/done',
        data: {
          'passed': true,
          'scope': 'production UI and navigation; explicit identity/business/media fixtures',
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
