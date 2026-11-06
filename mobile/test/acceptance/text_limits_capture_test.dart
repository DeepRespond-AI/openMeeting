// Supplemental Flutter-engine visual evidence; not an Android device run.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/user_profile.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/features/meetings/presentation/widgets/feedback.dart';
import 'package:meeting/features/settings/presentation/widgets/account_section.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/test_config.dart';

void main() {
  if (Platform.environment['FIELD_LIMITS_CAPTURE'] != '1') return;
  testWidgets('capture production rename and account widgets after assertions pass', (
    tester,
  ) async {
    final directory = Directory('../.artifacts/field-limits');
    final rows = <Map<String, Object?>>[];
    await tester.runAsync(() async {
      final bytes = await File('C:/Windows/Fonts/msyh.ttc').readAsBytes();
      await (FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final repository = FakeAuthRepository();
    final container = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        imUserProfileProvider('u1').overrideWith((_) => Stream.value(null)),
      ],
    );
    await tester.runAsync(() async {
      await container.read(sessionControllerProvider.future);
      await container.read(sessionControllerProvider.notifier).login('13800138000', '123456');
    });
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final size in [const Size(960, 720), const Size(390, 844)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      final boundary = GlobalKey();
      String savedTitle = '字段限制验证会议';
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              locale: const Locale('zh'),
              supportedLocales: appSupportedLocales,
              localizationsDelegates: localizationsDelegates,
              home: Scaffold(
                appBar: AppBar(title: const Text('字段限制验证')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: StatefulBuilder(
                    builder: (context, setState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(savedTitle),
                        FilledButton(
                          onPressed: () async {
                            final title = await promptText(
                              context,
                              title: '重命名会议',
                              initialValue: '',
                              hint: '会议名称',
                              emptyError: l10n.meetingsTitleEmpty,
                              maxLength: 50,
                            );
                            if (title != null) setState(() => savedTitle = title);
                          },
                          child: const Text('重命名会议'),
                        ),
                        const AccountSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> shot(String state) async {
        final filename = '${17 + rows.length}-flutter-${size.width.toInt()}-$state.png';
        final surface = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await surface.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('${directory.path}/screenshots/$filename')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
        rows.add({
          'operation': state,
          'expected': '真实 Flutter 组件正常绘制',
          'actual': '已打开、绘制和截图',
          'pass': true,
          'screenshot': 'screenshots/$filename',
          'viewport': [size.width, size.height],
          'inspected': false,
        });
        File('${directory.path}/flutter-captures.json')
            .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
        // ignore: avoid_print
        print(jsonEncode(rows.last));
      }

      await shot('正常');
      await tester.tap(find.text('重命名会议'));
      await tester.pumpAndSettle();
      expect(find.text('0/50'), findsOneWidget);
      await shot('空标题');
      await tester.tap(find.text(l10n.commonSave));
      await tester.pumpAndSettle();
      expect(find.text(l10n.meetingsTitleEmpty), findsOneWidget);
      await shot('空标题错误');
      await tester.enterText(find.byType(TextField), '会议标题长度边界' * 8);
      await tester.pumpAndSettle();
      expect(find.text('50/50'), findsOneWidget);
      await shot('50字上限');
      await tester.tap(find.text(l10n.commonSave));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.settingsEditName));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '移动端昵称长度边界' * 4);
      await tester.pumpAndSettle();
      expect(find.text('32/32'), findsOneWidget);
      await shot('昵称32字');
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -100));
      await tester.pumpAndSettle();
      await shot('关闭弹窗并滚动');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
