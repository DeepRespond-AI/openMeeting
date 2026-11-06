import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/im/user_profile.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/widgets/text_limit.dart';
import 'package:meeting/features/meetings/presentation/widgets/feedback.dart';
import 'package:meeting/features/settings/presentation/widgets/account_section.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/test_config.dart';

Widget app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('zh'),
  supportedLocales: appSupportedLocales,
  localizationsDelegates: localizationsDelegates,
  home: Scaffold(body: home),
);

void main() {
  for (final character in ['会', 'a', '😀']) {
    testWidgets('rename limits 51 to 50 code points and saves ($character)', (tester) async {
      String? saved;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              child: const Text('open'),
              onPressed: () async => saved = await promptText(
                context,
                title: '重命名会议',
                initialValue: '',
                hint: '会议名称',
                emptyError: '会议名称不能为空',
                maxLength: 50,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('0/50'), findsOneWidget);
      await tester.enterText(find.byType(TextField), character * 51);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, character * 50);
      expect(find.text('50/50'), findsOneWidget);
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(saved, character * 50);
    });
  }

  testWidgets('empty or legacy overlong title cannot save; cancel leaves it unchanged', (
    tester,
  ) async {
    String? saved;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            child: const Text('open'),
            onPressed: () async => saved = await promptText(
              context,
              title: '重命名会议',
              initialValue: '会' * 51,
              hint: '会议名称',
              emptyError: '会议名称不能为空',
              maxLength: 50,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('51/50'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('会议名称不能为空'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  test('formatter preserves composing Chinese and clamps once composition is committed', () {
    const formatter = CodePointLengthFormatter(50);
    final composing = TextEditingValue(
      text: '会' * 51,
      selection: const TextSelection.collapsed(offset: 51),
      composing: const TextRange(start: 49, end: 51),
    );
    expect(formatter.formatEditUpdate(TextEditingValue.empty, composing), composing);
    final committed = formatter.formatEditUpdate(
      composing,
      composing.copyWith(composing: TextRange.empty),
    );
    expect(committed.text, '会' * 50);
    expect(committed.selection.extentOffset, 50);
  });

  testWidgets('real account dialog limits emoji nickname to 32 and updates the profile', (
    tester,
  ) async {
    late ProviderContainer container;
    final repository = FakeAuthRepository();
    await tester.runAsync(() async {
      container = await createTestContainer(
        config: loadConfigWithServer('http://server.test'),
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          imUserProfileProvider('u1').overrideWith((_) => Stream.value(null)),
        ],
      );
      await container.read(sessionControllerProvider.future);
      await container.read(sessionControllerProvider.notifier).login('13800138000', '123456');
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: app(const SingleChildScrollView(child: AccountSection())),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    await tester.tap(find.byTooltip(l10n.settingsEditName));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '😀' * 33);
    await tester.pumpAndSettle();
    expect(find.text('32/32'), findsOneWidget);
    await tester.tap(find.text(l10n.commonSave));
    await tester.pumpAndSettle();
    expect(repository.user.name, '😀' * 32);
    expect(repository.calls, contains('updateName'));
    expect(tester.takeException(), isNull);
  });
}
