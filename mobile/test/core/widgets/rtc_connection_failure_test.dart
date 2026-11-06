import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/im/rtc_connection_failure.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/widgets/live_feedback.dart';

void main() {
  for (final width in [390.0, 1200.0]) {
    testWidgets('RTC timeout is readable and retry works at width $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final windowsFont = File('C:/Windows/Fonts/msyh.ttc');
        if (windowsFont.existsSync()) {
          await (FontLoader(
            'Roboto',
          )..addFont(Future.value(ByteData.sublistView(await windowsFont.readAsBytes())))).load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      var attempts = 0;
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.dark(),
          home: RepaintBoundary(
            key: capture,
            child: Scaffold(
              body: SafeArea(child: LiveError(rtcJoinTimedOut, onRetry: () => attempts++)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('音视频服务未能在入会时限内就绪'), findsOneWidget);
      expect(find.text('invalid_state'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(attempts, 1);
      expect(tester.takeException(), isNull);
      final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File(
          '../.artifacts/quick-meeting-invalid-state/screenshots/timeout-${width.toInt()}.png',
        );
        await output.parent.create(recursive: true);
        await output.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
