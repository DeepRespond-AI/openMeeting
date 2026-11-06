// Visual-only supplemental capture after the completed user-flow assertions.
// Production widgets, fixture room state; no business/network E2E is repeated.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/live_meeting/domain/live_models.dart';
import 'package:meeting/features/live_meeting/presentation/room_controller.dart';
import 'package:meeting/features/live_meeting/presentation/room_page.dart';
import 'package:meeting/features/live_meeting/presentation/schedule_sheet.dart';

import '../helpers/test_config.dart';

class VisualRoom extends RoomController {
  @override
  LiveRoomState build() => const LiveRoomState.active(
    room: LiveRoom(
      id: 'visual-only',
      code: '123456',
      title: '会议主题 · 视觉夹具',
      hostId: 'p',
      recording: LiveRecording(),
      participants: [LiveParticipant(id: 'p', name: '主持人', isHost: true, isSelf: true)],
    ),
    self: LiveParticipant(id: 'p', name: '主持人', isHost: true, isSelf: true),
    connection: 'connected',
    media: 'unavailable',
  );
}

void main() {
  if (Platform.environment['MOBILE_PARITY_CAPTURE'] != '1') return;
  testWidgets('visual-only supplemental dialog capture', (t) async {
    debugDisableShadows = false;
    final root = Directory('../.artifacts/mobile-desktop-parity'),
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
      overrides: [roomControllerProvider.overrideWith(VisualRoom.new)],
    );
    final l = lookupAppLocalizations(const Locale('zh'));
    Future<void> mount(Widget body) async {
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
              locale: const Locale('zh'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: appSupportedLocales,
              theme: AppTheme.light(),
              home: body,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    Future<void> shot(String name, Size size) async {
      final file = 'screenshots/${33 + rows.length}-补拍-$name.png';
      final surface = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await surface.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('${root.path}/$file').writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      rows.add({
        'action': name,
        'expected': 'production dialog fully painted; fixture data, visual only',
        'actual': 'opened, settled, captured; closed after capture',
        'passed': true,
        'screenshot': file,
        'viewport': [size.width, size.height],
        'scope': 'component visual fixture',
      });
      await t.runAsync(
        () =>
            File('${root.path}/supplemental-capture.json')
                .writeAsString(const JsonEncoder.withIndent('  ').convert(rows)),
      );
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
      expect(find.byType(DatePickerDialog), findsNothing);
      await t.tap(find.byKey(const ValueKey('schedule-time')));
      await t.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await shot('${viewport.$1}-时间弹窗', viewport.$2);
      Navigator.of(t.element(find.byType(TimePickerDialog))).pop();
      await t.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsNothing);
      await mount(const LiveRoomPage());
      await t.tap(find.text(l.liveEnd));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await shot('${viewport.$1}-结束弹窗', viewport.$2);
      await t.tap(find.text(l.liveBack));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    }
    await t.pumpWidget(const SizedBox());
    c.dispose();
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
    debugDisableShadows = true;
  });
}
