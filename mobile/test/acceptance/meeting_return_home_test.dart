// Focused navigation acceptance with real app router, room UI and leave/end
// controller operations. Repository/identity/native boundaries are explicit fakes.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_router.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/update/update_controller.dart';
import 'package:meeting/core/widgets/brand_logo.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_config.dart';

class ReturnRepo extends Mock implements LiveRepository {}

class ReturnSession extends SessionController {
  @override
  Future<AuthState> build() async => const AuthState.signedIn(User(id: 'return-user', name: '测试'));
}

class ReturnUpdate extends UpdateController {
  @override
  UpdateState build() => const UpdateState();
}

class ReturnRoom extends RoomController {
  ReturnRoom(this.initial);
  final LiveRoomState initial;
  @override
  LiveRoomState build() => initial;
}

void main() {
  if (Platform.environment['MEETING_RETURN_UI'] != '1') return;
  final budgetFile = File('../.artifacts/meeting-return-home/budget.json');
  if (budgetFile.existsSync()) {
    final started = (jsonDecode(budgetFile.readAsStringSync()) as Map)['started'] as num;
    if (DateTime.now().millisecondsSinceEpoch - started >
        const Duration(minutes: 30).inMilliseconds) {
      throw StateError('Cumulative E2E budget exhausted; use API fallback.');
    }
  }
  setUpAll(() => registerFallbackValue(DateTime(2026)));
  final out = Directory('../.artifacts/meeting-return-home');
  final rows = <Map<String, Object?>>[];
  var number = 0;
  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets('mobile completion navigation $size', (t) async {
      debugDisableShadows = false;
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.runAsync(() async {
        await (FontLoader('Roboto')..addFont(
              Future.value(
                ByteData.sublistView(await File('C:/Windows/Fonts/msyh.ttc').readAsBytes()),
              ),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final l = lookupAppLocalizations(const Locale('zh'));
      Future<void> scenario(
        String name, {
        bool host = true,
        bool remote = false,
        bool waiting = false,
        bool failed = false,
        bool openSheet = false,
      }) async {
        final screenshots = <String>[];
        final row = <String, Object?>{
          'platform': 'mobile',
          'viewport': '${size.width.toInt()}x${size.height.toInt()}',
          'operation': name,
          'expected': failed ? '失败仍在会议内，错误可见，重试后直接首页' : '直接首页，房间和弹层关闭，无结束中转页',
          'pass': false,
          'screenshot': null,
          'screenshots': screenshots,
        };
        rows.add(row);
        final repo = ReturnRepo();
        var reject = failed;
        when(() => repo.end(any())).thenAnswer((_) async {
          if (reject) throw StateError('fixture end unavailable');
          return 'record-id';
        });
        when(() => repo.action(any(), any())).thenAnswer((_) async {
          if (reject) throw StateError('fixture leave unavailable');
        });
        when(() => repo.schedules(any(), any())).thenAnswer((_) async => []);
        final self = LiveParticipant(id: 'self', name: '测试', isSelf: true, isHost: host);
        final room = LiveRoom(
          id: 'room',
          code: '123456',
          title: '结束直接返回首页',
          hostId: 'self',
          participants: [self],
        );
        final initial = waiting
            ? LiveRoomState.waiting(room: room, self: self)
            : LiveRoomState.active(
                room: room,
                self: self,
                connection: 'connected',
                media: 'unavailable',
              );
        final c = await createTestContainer(
          prefs: {'settings.onboardingCompleted': true, 'settings.localeMode': 'zh'},
          overrides: [
            sessionControllerProvider.overrideWith(ReturnSession.new),
            updateControllerProvider.overrideWith(ReturnUpdate.new),
            liveRepositoryProvider.overrideWithValue(repo),
            roomControllerProvider.overrideWith(() => ReturnRoom(initial)),
          ],
        );
        final key = GlobalKey();
        Future<void> shot(String state) async {
          if (Platform.environment['MEETING_RETURN_CAPTURE'] != '1') return;
          // Widget-test settling does not wait for asset decoding on the host.
          await t.runAsync(
            () => precacheImage(const AssetImage(BrandAssets.logo), key.currentContext!),
          );
          await t.pumpAndSettle();
          final file =
              'screenshots/mobile-${(++number).toString().padLeft(2, '0')}-${size.width.toInt()}-$state.png';
          await t.runAsync(() async {
            final surface = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final img = await surface.toImage();
            final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
            final target = File('${out.path}/$file');
            target.parent.createSync(recursive: true);
            target.writeAsBytesSync(bytes!.buffer.asUint8List());
            img.dispose();
          });
          screenshots.add(file);
        }

        try {
          await t.runAsync(() => c.read(sessionControllerProvider.future));
          final router = c.read(appRouterProvider);
          router.go(AppRoutes.liveRoom);
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: RepaintBoundary(
                key: key,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  routerConfig: router,
                  theme: AppTheme.light(),
                  locale: const Locale('zh'),
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: appSupportedLocales,
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(find.byType(LiveRoomPage), findsOneWidget);
          if (openSheet) {
            await t.tap(find.text(l.liveMore));
            await t.pumpAndSettle();
            expect(find.byType(BottomSheet), findsOneWidget);
            await shot('open-sheet');
          }
          Future<void> leave() async {
            if (remote) {
              await c.read(roomControllerProvider.notifier).eventReceived({
                'type': 'room_ended',
                'data': {'meetingId': 'record-id'},
              }, 0);
            } else if (waiting) {
              await t.tap(find.text(l.liveCancelJoin));
            } else {
              await t.tap(find.text(host ? l.liveEnd : l.liveLeave));
              await t.pumpAndSettle();
              if (host && !failed) await shot('end-confirm');
              await t.tap(find.text(l.liveConfirm));
            }
            await t.pumpAndSettle();
          }

          await leave();
          if (failed) {
            expect(router.routeInformationProvider.value.uri.path, AppRoutes.liveRoom);
            expect(find.textContaining('fixture'), findsWidgets);
            if (host) await shot('end-error');
            reject = false;
            await leave();
          }
          expect(router.routeInformationProvider.value.uri.path, AppRoutes.meetings);
          expect(find.byType(LiveRoomPage), findsNothing);
          expect(find.byType(BottomSheet), findsNothing);
          expect(find.text(l.liveEnded), findsNothing);
          expect(find.text(l.liveBackHome), findsNothing);
          row['pass'] = true;
          row['actual'] = '路由/房间/弹层/中转文案断言全部通过';
          if (host && !waiting && !failed) await shot('home');
        } catch (error) {
          row['actual'] = error.toString();
          rethrow;
        } finally {
          stdout.writeln(jsonEncode(row));
          out.createSync(recursive: true);
          File(
            '${out.path}/mobile-results${Platform.environment['MEETING_RETURN_CAPTURE'] == '1' ? '-capture' : ''}.json',
          ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
          await t.pumpWidget(const SizedBox.shrink());
          c.dispose();
          await t.pump();
        }
      }

      await scenario('主持人结束后返回首页');
      await scenario('成员主动离会返回首页', host: false);
      await scenario('远端结束时关闭已打开抽屉', host: false, remote: true, openSheet: true);
      await scenario('等候室取消直接首页', waiting: true);
      await scenario('结束失败留在原处，重试成功', failed: true);
      await scenario('离会失败留在原处，重试成功', host: false, failed: true);
      debugDisableShadows = true;
    });
  }
}
