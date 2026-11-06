// Real server/IM/RTC, real Android capture. Bridge transfers an existing test
// session only over ADB loopback and coordinates the Windows participant.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:meeting/app.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/session_store.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config_provider.dart';
import 'package:meeting/core/config/settings_store.dart';
import 'package:meeting/core/im/channel_media.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/home_page.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/screen_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real Windows Android screen sharing', (t) async {
    final bridge = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:39343'));
    bridge.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => HttpClient()..findProxy = (_) => 'DIRECT',
    );
    final config = await loadAppConfig();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings.onboardingCompleted', true);
    await prefs.setString('settings.localeMode', 'zh');
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      retry: (_, _) => null,
    );
    final session = (await bridge.get<Map<String, dynamic>>('/session')).data!;
    await c
        .read(sessionStoreProvider)
        .save(
          StoredSession(
            token: session['token'] as String,
            user: User.fromJson(Map<String, dynamic>.from(session['user'] as Map)),
            serverUrl: config.defaultServerUrl,
          ),
        );
    await c.read(sessionControllerProvider.future);
    await c.read(sessionControllerProvider.notifier).refreshMe();
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const App()));
    Future<void> wait(bool Function() ready, {int seconds = 55}) async {
      final end = DateTime.now().add(Duration(seconds: seconds));
      while (!ready()) {
        if (DateTime.now().isAfter(end)) {
          throw StateError('Native interop state timeout: ${c.read(roomControllerProvider)}');
        }
        await t.pump(const Duration(milliseconds: 100));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        final error = t.takeException();
        if (error != null) throw StateError('Flutter: $error');
      }
    }

    await wait(() => find.byType(LiveHomePage).evaluate().isNotEmpty);
    await bridge.post<void>(
      '/complete',
      data: {'operation': 'boot', 'pass': true, 'actual': 'Real app/session ready'},
    );
    final deadline = DateTime.now().add(const Duration(minutes: 25));
    try {
      while (DateTime.now().isBefore(deadline)) {
        final cmd = (await bridge.get<Map<String, dynamic>>('/command')).data!;
        final action = cmd['action'] as String;
        if (action == 'wait') {
          await t.pump(const Duration(milliseconds: 100));
          await Future<void>.delayed(const Duration(milliseconds: 250));
          continue;
        }
        final row = <String, Object?>{
          'operation': action,
          'expected': cmd['expected'] ?? action,
          'pass': false,
        };
        try {
          if (action == 'join') {
            final joining = c.read(roomControllerProvider.notifier).join(cmd['code'] as String);
            c.read(appRouterProvider).go(AppRoutes.liveRoom);
            await t.pump();
            await joining;
            await wait(() {
              final s = c.read(roomControllerProvider);
              return s is RoomActive && s.media == 'connected';
            });
            await t.pump(const Duration(seconds: 1));
            expect(find.byType(SnackBar), findsNothing);
            row['actual'] = 'Real Android IM RTC connected; no record notice overlay';
          } else if (action == 'deny' || action == 'start') {
            final starting = c.read(roomScreenProvider.notifier).start('会议屏幕共享', '允许共享当前屏幕');
            await Future<void>.delayed(const Duration(milliseconds: 800));
            await bridge.post<void>('/consent', data: {'allow': action == 'start'});
            await starting;
            final state = c.read(roomScreenProvider);
            expect(state.phase, action == 'start' ? ScreenPhase.sharing : ScreenPhase.idle);
            if (action == 'deny') expect(state.error, ScreenFailure.denied);
            row['actual'] = '${state.phase.name}/${state.error?.name}';
          } else if (action == 'remote') {
            lk.VideoTrack? track;
            await wait(() {
              final tracks = c.read(authorizedTracksProvider).value ?? [];
              for (final tr in tracks) {
                if (tr.username != (session['user'] as Map)['id'] &&
                    isScreenTrack(c.read(roomChannelProvider), tr) &&
                    tr.track is lk.VideoTrack) {
                  track = tr.track as lk.VideoTrack;
                  return true;
                }
              }
              return false;
            });
            await t.pump(const Duration(seconds: 2));
            final bytes = await track!.mediaStreamTrack.captureFrame();
            final codec = await ui.instantiateImageCodec(bytes.asUint8List());
            final frame = await codec.getNextFrame();
            expect(frame.image.width, greaterThan(100));
            expect(frame.image.height, greaterThan(100));
            final pixels = (await frame.image.toByteData())!;
            final colors = <int>{};
            for (var i = 0; i < pixels.lengthInBytes - 4; i += 4000) {
              colors.add(pixels.getUint32(i));
            }
            expect(colors.length, greaterThan(3));
            await bridge.post<void>(
              '/frame/mobile-remote-frame-${cmd['tag'] ?? 'assertions'}.png',
              data: Stream.value(bytes.asUint8List()),
              options: Options(headers: {'content-type': 'application/octet-stream'}),
            );
            row['actual'] =
                'Remote real pixels ${frame.image.width}x${frame.image.height}, colors=${colors.length}';
            frame.image.dispose();
            codec.dispose();
          } else if (action == 'stop') {
            await c.read(roomScreenProvider.notifier).stop();
            expect(c.read(roomScreenProvider).phase, ScreenPhase.idle);
            row['actual'] = 'Capture and publication stopped';
          } else if (action == 'state') {
            final s = c.read(roomControllerProvider);
            row['actual'] = s is RoomActive
                ? '${s.media}, shared=${s.room.participants.where((p) => p.screenSharing).length}'
                : '${s.runtimeType}';
          } else if (action == 'finish') {
            row['actual'] = 'Finished';
          } else {
            throw StateError('Unknown action');
          }
          row['pass'] = true;
        } catch (e) {
          row['actual'] = '$e';
        }
        await t.pump(const Duration(milliseconds: 400));
        await bridge.post<void>('/complete', data: row);
        if (action == 'finish') break;
      }
    } finally {
      await c.read(roomScreenProvider.notifier).stop();
      await c.read(roomControllerProvider.notifier).cleanup();
      c.dispose();
      bridge.close();
    }
  }, timeout: const Timeout(Duration(minutes: 28)));
}
