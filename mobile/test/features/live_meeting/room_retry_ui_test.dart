import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/im/rtc_connection_failure.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/live_meeting/data/live_repository_impl.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/domain/live_repository.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_config.dart';

class _Repo extends Mock implements LiveRepository {}

const _me = LiveParticipant(id: 'self', userId: 'self', name: '测试用户', isSelf: true);
const _room = LiveRoom(
  id: 'room',
  code: '123456',
  title: '测试会议',
  hostId: 'host',
  participants: [_me],
);

// Real retryMedia and real meeting page. Only the initial room and SDK attach
// are fixture boundaries; repository requests still go through retryMedia.
class _Controller extends RoomController {
  @override
  LiveRoomState build() => const LiveRoomState.active(
    room: _room,
    self: _me,
    connection: 'connected',
    media: 'error',
    error: rtcJoinTimedOut,
  );

  @override
  Future<void> connectMedia(Map<String, dynamic> config) async {
    expect(config['transport'], 'fixture');
    state = (state as RoomActive).copyWith(media: 'connected', error: null);
  }

  void failMedia() =>
      state = (state as RoomActive).copyWith(media: 'error', error: rtcJoinTimedOut);
}

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('one actionable RTC retry with loading, failure and recovery at $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.runAsync(() async {
        final font = File('C:/Windows/Fonts/msyh.ttc');
        if (font.existsSync()) {
          await (FontLoader(
            'Roboto',
          )..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())))).load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final repo = _Repo();
      var pending = Completer<Map<String, dynamic>>();
      var requests = 0;
      when(() => repo.media(_room.id)).thenAnswer((_) {
        requests++;
        return pending.future;
      });
      final container = await createTestContainer(
        overrides: [
          liveRepositoryProvider.overrideWithValue(repo),
          roomControllerProvider.overrideWith(_Controller.new),
        ],
      );
      final capture = GlobalKey();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark(),
            home: RepaintBoundary(key: capture, child: const LiveRoomPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('重试'), findsOneWidget);
      expect(find.textContaining('入会时限'), findsOneWidget);
      expect(find.text('音视频尚未连接，成员控制和聊天仍可使用'), findsNothing);
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(requests, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('音视频正在后台连接，可先使用聊天和成员功能'), findsNothing);
      expect(find.byKey(const ValueKey('participant-self')), findsNothing);
      expect(find.text('重试'), findsNothing);
      await container.read(roomControllerProvider.notifier).retryMedia();
      expect(requests, 1);
      pending.completeError(const ApiException(kind: ApiErrorKind.unavailable, message: '音视频暂不可用'));
      await tester.pumpAndSettle();
      expect(find.text('重试'), findsOneWidget);
      expect(find.text('音视频暂不可用'), findsOneWidget);
      verifyNever(() => repo.room(any()));
      pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(requests, 2);
      pending.complete({'transport': 'fixture'});
      await tester.pumpAndSettle();
      expect(find.text('重试'), findsNothing);
      expect(find.textContaining('音视频暂不可用'), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('participant-self')), findsOneWidget);
      // Subsequent media failures/retries must not send an entered room back
      // to initialization or reintroduce a background-connection notice.
      (container.read(roomControllerProvider.notifier) as _Controller).failMedia();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('participant-self')), findsOneWidget);
      pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.text('重试'));
      await tester.pump();
      expect(find.byKey(const ValueKey('participant-self')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('音视频正在后台连接，可先使用聊天和成员功能'), findsNothing);
      pending.complete({'transport': 'fixture'});
      await tester.pumpAndSettle();
      // Capture only on an explicit second run after the assertion suite passed.
      if (Platform.environment['ROOM_RETRY_CAPTURE'] == '1') {
        Future<void> shot(String step, String expected) async {
          final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
            final path =
                '../.artifacts/mobile-room-single-retry/screenshots/${width.toInt()}/$step.png';
            await File(path).parent.create(recursive: true);
            await File(path).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
            stdout.writeln(
              jsonEncode({
                'operation': step,
                'expected': expected,
                'actual': 'captured after flow assertions passed',
                'pass': true,
                'viewport': '${width.toInt()}x800',
                'screenshot': path,
              }),
            );
          });
        }

        (container.read(roomControllerProvider.notifier) as _Controller).failMedia();
        await tester.pumpAndSettle();
        await shot('01-连接超时', 'one retry and one timeout explanation');
        pending = Completer<Map<String, dynamic>>();
        await tester.tap(find.text('重试'));
        await tester.pump();
        await shot('02-重新连接中', 'visible loading indicator');
        pending.completeError(
          const ApiException(kind: ApiErrorKind.unavailable, message: '音视频暂不可用'),
        );
        await tester.pumpAndSettle();
        await shot('03-重试失败', 'one retry and actionable failure');
        pending = Completer<Map<String, dynamic>>();
        await tester.tap(find.text('重试'));
        await tester.pump();
        pending.complete({'transport': 'fixture'});
        await tester.pumpAndSettle();
        await shot('04-连接恢复', 'normal meeting page without retry');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
