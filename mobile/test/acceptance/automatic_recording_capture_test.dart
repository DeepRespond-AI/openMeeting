// Visual-only supplemental evidence. Production widgets, explicit static data;
// no business E2E or network retry after the cumulative budget expired.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/meeting_recording.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/home_page.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/schedule_sheet.dart';
import 'package:meeting/features/meetings/data/just_audio_engine.dart';
import 'package:meeting/features/meetings/presentation/meeting_detail_controller.dart';
import 'package:meeting/features/meetings/presentation/meeting_detail_page.dart';
import 'package:meeting/features/summary/domain/summary_state.dart';
import 'package:meeting/features/summary/presentation/summary_controller.dart';

import '../helpers/test_config.dart';
import 'desktop_parity_ui_test.dart' show VmPlayback;

class VisualSession extends SessionController {
  @override
  Future<AuthState> build() async =>
      const AuthState.signedIn(User(id: 'visual-user', name: '视觉测试'));
}

class VisualAutomaticRoom extends RoomController {
  @override
  LiveRoomState build() => const LiveRoomState.active(
    room: LiveRoom(
      id: 'visual-room',
      code: '123456',
      title: '自动录音 · 视觉夹具',
      hostId: 'p',
      recording: LiveRecording(active: true, epoch: 1),
      participants: [LiveParticipant(id: 'p', name: '主持人', isHost: true, isSelf: true)],
    ),
    self: LiveParticipant(id: 'p', name: '主持人', isHost: true, isSelf: true),
    connection: 'connected',
    media: 'unavailable',
  );
}

class VisualDetail extends MeetingDetailController {
  @override
  Future<MeetingMetadata> build(String meetingId) async =>
      const MeetingMetadata(id: 'visual-record', title: '共享会议记录 · 视觉夹具', canManage: false);
}

class VisualSummary extends SummaryController {
  @override
  Future<SummaryState> build(String meetingId) async => const SummaryState.empty();
}

void main() {
  if (Platform.environment['MOBILE_AUTO_RECORDS_CAPTURE'] != '1') return;
  testWidgets('supplemental visual capture only: dialogs, created card, read-only menu', (t) async {
    debugDisableShadows = false;
    final out = Directory('../.artifacts/mobile-auto-records'),
        key = GlobalKey(),
        rows = <Map<String, Object?>>[];
    await t.runAsync(() async {
      final bytes = await File('C:/Windows/Fonts/msyh.ttc').readAsBytes();
      await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final c = await createTestContainer(
      overrides: [
        audioPlaybackEngineFactoryProvider.overrideWithValue(VmPlayback.new),
        sessionControllerProvider.overrideWith(VisualSession.new),
        roomControllerProvider.overrideWith(VisualAutomaticRoom.new),
        meetingDetailControllerProvider('visual-record').overrideWith(VisualDetail.new),
        summaryControllerProvider('visual-record').overrideWith(VisualSummary.new),
        meetingRecordingProvider('visual-record').overrideWith((_) async => {'status': 'none'}),
      ],
    );
    await t.runAsync(() => c.read(sessionControllerProvider.future));
    final l = lookupAppLocalizations(const Locale('zh'));
    Future<void> mount(Widget body) async {
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('zh'),
              theme: AppTheme.light(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: appSupportedLocales,
              home: body,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    Future<void> shot(String name, Size size) async {
      final file = 'screenshots/${59 + rows.length}-补拍-$name.png';
      final surface = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await surface.toImage(pixelRatio: 1),
            data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${out.path}/$file').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      rows.add({
        'action': name,
        'expected': 'production widget painted and visible; static visual fixture only',
        'actual': 'opened, settled, captured, then closed',
        'passed': true,
        'screenshot': file,
        'viewport': [size.width, size.height],
        'scope': 'component visual fixture; no network/business E2E',
      });
      File('${out.path}/supplemental-capture.json')
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
      // ignore: avoid_print
      print(jsonEncode(rows.last));
    }

    for (final viewport in [('手机窄屏', const Size(390, 844)), ('平板横屏', const Size(1024, 768))]) {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = viewport.$2;
      await mount(const Scaffold(body: SafeArea(child: ScheduleSheet())));
      await t.tap(find.byKey(const ValueKey('schedule-date')));
      await t.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await shot('${viewport.$1}-日期弹窗', viewport.$2);
      Navigator.of(t.element(find.byType(DatePickerDialog))).pop();
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('schedule-time')));
      await t.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await shot('${viewport.$1}-时间弹窗', viewport.$2);
      Navigator.of(t.element(find.byType(TimePickerDialog))).pop();
      await t.pumpAndSettle();
      final item = LiveSchedule(
        id: 'visual-schedule',
        code: '123456',
        title: '新建预定卡片 · 视觉夹具',
        startAt: DateTime.now().add(const Duration(days: 1)),
        durationMin: 30,
        host: {'id': 'visual-user', 'name': '视觉测试'},
      );
      await mount(
        Scaffold(
          body: SafeArea(child: SingleChildScrollView(child: ScheduleCard(item))),
        ),
      );
      await shot('${viewport.$1}-新增预定卡片', viewport.$2);
      await t.tap(find.text(l.liveCancelSchedule));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await shot('${viewport.$1}-取消预定弹窗', viewport.$2);
      await t.tap(find.text(l.liveBack));
      await t.pumpAndSettle();
      await mount(const LiveRoomPage());
      await t.tap(find.text(l.liveEnd));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await shot('${viewport.$1}-结束弹窗', viewport.$2);
      await t.tap(find.text(l.liveBack));
      await t.pumpAndSettle();
      await mount(const MeetingDetailPage(meetingId: 'visual-record'));
      await t.tap(find.byTooltip(l.meetingsActions));
      await t.pumpAndSettle();
      expect(find.text(l.commonRename), findsNothing);
      expect(find.text(l.meetingsActionDelete), findsNothing);
      expect(find.text(l.meetingsActionCopyTranscript), findsOneWidget);
      await shot('${viewport.$1}-成员只读菜单', viewport.$2);
      await t.tapAt(const Offset(8, 150));
      await t.pumpAndSettle();
    }
    await t.pumpWidget(const SizedBox.shrink());
    c.dispose();
    await t.pump();
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    debugDisableShadows = true;
  });
}
