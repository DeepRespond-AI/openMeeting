import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:integration_test/integration_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:meeting/core/im/screen_capture.dart';
import 'package:mocktail/mocktail.dart';

import '../test/acceptance/core_parity_ui_test.dart' show runCoreFlow;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(DateTime(2026)));
  testWidgets('core mobile route flows and native MediaProjection', (t) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39342'));
    await dio.post<void>('/begin');
    var converted = false;
    Future<void> emit(Map<String, Object?> row) => dio.post<void>('/row', data: row);
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
      await runCoreFlow(t, emit: emit, screenshot: shot, capture: false, native: true);
      await runCoreFlow(t, emit: emit, screenshot: shot, capture: true, native: true);
      await dio.post<void>('/done', data: {'passed': true, 'scope': 'core UI only'});
    } catch (error) {
      await dio.post<void>('/done', data: {'passed': false, 'error': '$error'});
      rethrow;
    } finally {
      dio.close();
    }
  });
  // A separate test restores the normal Android Flutter surface after UI
  // screenshots. Texture-backed video is verified from native pixels directly.
  testWidgets('native MediaProjection pixels and system consent', (t) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39342'));
    Future<void> emit(Map<String, Object?> row) => dio.post<void>('/row', data: row);
    try {
      for (final allow in [false, true]) {
        ScreenCapture? capture;
        rtc.RTCVideoRenderer? renderer;
        final row = <String, Object?>{
          'platform': 'android-native-capture',
          'phase': 'assertions',
          'operation': allow ? '原生屏幕采集允许' : '原生屏幕采集拒绝',
          'expected': allow ? '真实 MediaProjection 生成 video 轨道并释放' : '系统拒绝返回 ScreenCaptureDenied',
          'actual': '',
          'pass': false,
        };
        try {
          await t.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: Colors.red,
                        child: Center(child: Text('Native capture RED')),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: Colors.green,
                        child: Center(child: Text('Native capture GREEN')),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: Colors.blue,
                        child: Center(child: Text('Native capture BLUE')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          final pending = NativeScreenCapture.create(
            '屏幕共享',
            '正在测试屏幕采集',
          ).then<Object>((value) => value, onError: (Object error) => error);
          await dio.post<void>('/consent', data: {'allow': allow});
          final outcome = await pending;
          if (allow) {
            if (outcome is! ScreenCapture) throw StateError('$outcome');
            capture = outcome;
            expect(capture.video, isA<lk.LocalVideoTrack>());
            final track = capture.video as lk.LocalVideoTrack;
            expect(track.mediaStreamTrack.kind, 'video');
            expect(track.mediaStreamTrack.enabled, true);
            // Android screen tracks need not expose width/height in getSettings.
            // Verify the native renderer actually receives a frame instead.
            renderer = rtc.RTCVideoRenderer();
            var firstFrame = false;
            renderer.onFirstFrameRendered = () => firstFrame = true;
            await renderer.initialize();
            await renderer.setSrcObject(
              stream: track.mediaStream,
              trackId: track.mediaStreamTrack.id,
            );
            final deadline = DateTime.now().add(const Duration(seconds: 10));
            while ((!firstFrame || renderer.videoWidth == 0 || renderer.videoHeight == 0) &&
                DateTime.now().isBefore(deadline)) {
              await t.pump(const Duration(milliseconds: 100));
            }
            expect(firstFrame, true, reason: 'Native screen capture must deliver a frame');
            expect(renderer.videoWidth, greaterThan(0));
            expect(renderer.videoHeight, greaterThan(0));
            final frame = (await track.mediaStreamTrack.captureFrame().timeout(
              const Duration(seconds: 10),
            )).asUint8List();
            final codec = await ui.instantiateImageCodec(frame);
            final image = (await codec.getNextFrame()).image;
            final pixels = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
            final colors = <int>{};
            for (var y = image.height ~/ 10; y < image.height; y += image.height ~/ 10) {
              for (var x = image.width ~/ 10; x < image.width; x += image.width ~/ 10) {
                colors.add(pixels.getUint32((y * image.width + x) * 4));
              }
            }
            expect(
              colors.length,
              greaterThan(3),
              reason: 'Actual native frame must contain non-uniform screen pixels',
            );
            await dio.post<void>(
              '/screenshot',
              queryParameters: {'name': 'screenshots/android-14-960-native-frame.png'},
              data: Stream.value(frame),
              options: Options(headers: {'content-type': 'application/octet-stream'}),
            );
            image.dispose();
            codec.dispose();
            await t.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: ColoredBox(
                                color: Colors.red,
                                child: Center(child: Text('RED')),
                              ),
                            ),
                            Expanded(
                              child: ColoredBox(
                                color: Colors.green,
                                child: Center(child: Text('GREEN')),
                              ),
                            ),
                            Expanded(
                              child: ColoredBox(
                                color: Colors.blue,
                                child: Center(child: Text('BLUE')),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: lk.VideoTrackRenderer(
                          track,
                          fit: lk.VideoViewFit.contain,
                          cachedRenderer: renderer,
                          autoDisposeRenderer: false,
                          mirrorMode: lk.VideoViewMirrorMode.off,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
            for (var i = 0; i < 30 && find.byType(rtc.RTCVideoView).evaluate().isEmpty; i++) {
              await t.pump(const Duration(milliseconds: 100));
            }
            expect(find.byType(rtc.RTCVideoView), findsOneWidget);
            await t.pump(const Duration(milliseconds: 500));
            await t.pump();
            await dio.post<void>(
              '/device-screenshot',
              data: {'name': 'screenshots/android-11-960-native-capture.png'},
            );
            row['screenshot'] = 'screenshots/android-11-960-native-capture.png';
            row['frame'] = 'screenshots/android-14-960-native-frame.png';
            row['actual'] =
                '真实 Android 首帧与 ${renderer.videoWidth}×${renderer.videoHeight} 画面；未发布至远端';
          } else {
            expect(outcome, isA<ScreenCaptureDenied>());
            row['actual'] = '系统取消已返回授权拒绝';
          }
          row['pass'] = true;
        } catch (error) {
          row['actual'] = '$error';
          rethrow;
        } finally {
          await t.pumpWidget(const SizedBox());
          await renderer?.dispose();
          await capture?.dispose();
          await emit(row);
        }
      }
      await dio.post<void>(
        '/done',
        data: {
          'passed': true,
          'native': Platform.operatingSystem,
          'rtcPublication': 'fixture',
          'mediaProjection': 'real native capture',
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
