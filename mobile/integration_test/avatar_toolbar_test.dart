import 'dart:io';

import 'package:deeprespond_im/deeprespond_im.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test/acceptance/avatar_toolbar_ui_test.dart' show runAvatarFlow;
import '../test/helpers/avatar_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    AvatarFixture.register();
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const MessageView({}));
  });
  testWidgets('Android avatar and toolbar focused acceptance', (t) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39341'));
    await dio.post<void>('/begin');
    var converted = false;
    Future<void> emit(Map<String, Object?> row) async {
      await dio.post<void>('/row', data: row);
    }

    Future<void> shot(String name, GlobalKey _) async {
      if (!converted) {
        await binding.convertFlutterSurfaceToImage();
        converted = true;
      }
      await t.pump();
      final bytes = await binding.takeScreenshot(name);
      await dio.post<void>(
        '/screenshot',
        queryParameters: {'name': name},
        data: Stream.value(bytes),
        options: Options(headers: {'content-type': 'application/octet-stream'}),
      );
    }

    try {
      await runAvatarFlow(
        t,
        imageBase: Uri.parse('http://127.0.0.1:39341'),
        emit: emit,
        screenshot: shot,
        capture: false,
        native: true,
      );
      await runAvatarFlow(
        t,
        imageBase: Uri.parse('http://127.0.0.1:39341'),
        emit: emit,
        screenshot: shot,
        capture: true,
        native: true,
      );
      await dio.post<void>(
        '/done',
        data: {
          'passed': true,
          'native': Platform.operatingSystem,
          'sdkBoundary': 'explicit fixture',
          'picker': 'fixture',
        },
      );
    } catch (error) {
      await dio.post<void>('/done', data: {'passed': false, 'error': error.toString()});
      rethrow;
    } finally {
      dio.close();
    }
  });
}
