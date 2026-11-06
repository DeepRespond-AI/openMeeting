// Production search page/controller with an explicit repository and navigation probe.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/core/heartbeat/heartbeat_controller.dart';
import 'package:meeting/core/l10n/l10n.dart';
import 'package:meeting/core/router/app_routes.dart';
import 'package:meeting/core/theme/app_theme.dart';
import 'package:meeting/core/widgets/brand_logo.dart';
import 'package:meeting/features/meetings/data/meetings_repository_impl.dart';
import 'package:meeting/features/meetings/presentation/meetings_list_page.dart';

import '../features/meetings/fake_meetings_repository.dart';
import '../helpers/test_config.dart';

class _IdleHeartbeat extends HeartbeatController {
  @override
  HeartbeatState build() => const HeartbeatState();
}

void main() {
  final output = Directory(
    Platform.environment['MEETING_SEARCH_OUTPUT'] ??
        '../.artifacts/mobile-history-search-gateway-20261029',
  )..createSync(recursive: true);
  final rows = <Map<String, Object?>>[];
  void emit(Map<String, Object?> row) {
    rows.add(row);
    File('${output.path}/results.json').writeAsStringSync(jsonEncode(rows));
    stdout.writeln(jsonEncode(row));
  }

  FakeMeetingsRepository fixture() => FakeMeetingsRepository()
    ..items = [
      MeetingSummary(id: 'budget', title: '移动端预算评审', createdAt: DateTime(2026, 10, 29)),
      MeetingSummary(id: 'design', title: 'Design Review', createdAt: DateTime(2026, 10, 28)),
      MeetingSummary(id: 'notes', title: '研发周会', createdAt: DateTime(2026, 10, 27)),
      MeetingSummary(id: 'literal', title: '进度 100%_完成', createdAt: DateTime(2026, 10, 26)),
      MeetingSummary(
        id: 'long',
        title: '长标题的历史会议记录用于验证搜索结果在窄屏中能够正常截断且保持点击区域和卡片布局',
        createdAt: DateTime(2026, 10, 25),
      ),
      MeetingSummary(
        id: 'english-1',
        title: 'Meeting Transcript Review – Insufficient Content',
        createdAt: DateTime(2026, 10, 24),
      ),
      MeetingSummary(
        id: 'english-2',
        title: 'Meeting Report – Transcript Lacking Substantive Content',
        createdAt: DateTime(2026, 10, 23),
      ),
    ]
    ..searchResults = {
      '预算': [
        const TranscriptSearchResult(id: 'notes', title: '研发周会', matchContext: '讨论预算和费用'),
        const TranscriptSearchResult(id: 'budget', title: '旧标题', matchContext: '预算第一段'),
        const TranscriptSearchResult(id: 'budget', title: '旧标题', matchContext: '预算第二段'),
      ],
      '费用': [const TranscriptSearchResult(id: 'notes', title: '研发周会', matchContext: '讨论预算和费用')],
    };

  test('failure fixture independently yields repeatable 404/503 and recovers', () async {
    final repo = fixture();
    final row = <String, Object?>{
      'phase': 'fixture-smoke',
      'operation': '独立冒烟内容搜索失败入口',
      'expected': '404和503分别连续触发两次，解除后返回确定结果',
      'pass': false,
      'screenshot': null,
    };
    try {
      for (final error in [
        const ApiException(kind: ApiErrorKind.notFound, statusCode: 404),
        const ApiException(kind: ApiErrorKind.unavailable, statusCode: 503),
      ]) {
        repo.searchError = error;
        for (var i = 0; i < 2; i++) {
          await expectLater(repo.searchTranscripts('预算'), throwsA(isA<ApiException>()));
        }
      }
      repo.searchError = null;
      expect(await repo.searchTranscripts('预算'), hasLength(3));
      row.addAll({'pass': true, 'actual': '404/503各2次异常；恢复返回3条原始命中'});
    } catch (e) {
      row['actual'] = '$e';
      rethrow;
    } finally {
      emit(row);
    }
  });

  testWidgets('history search: title substrings, transcript union and failure recovery', (t) async {
    final budget = File('${output.path}/budget.json');
    if (!budget.existsSync()) {
      budget.writeAsStringSync(jsonEncode({'started': DateTime.now().millisecondsSinceEpoch}));
    }
    final start = (jsonDecode(budget.readAsStringSync()) as Map)['started'] as int;
    void checkBudget() {
      if (DateTime.now().millisecondsSinceEpoch - start > 1800000) {
        throw StateError('30-minute cumulative E2E budget exhausted');
      }
    }

    await t.runAsync(() async {
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
    var number = 0;
    for (final capture in [false, true]) {
      for (final size in [const Size(390, 844), const Size(1024, 768)]) {
        checkBudget();
        await t.binding.setSurfaceSize(size);
        final repo = fixture();
        final base = loadConfigFile('dev');
        final c = await createTestContainer(
          config: base.copyWith(pagination: base.pagination.copyWith(meetingSearchDebounceMs: 10)),
          overrides: [
            meetingsRepositoryProvider.overrideWithValue(repo),
            heartbeatControllerProvider.overrideWith(_IdleHeartbeat.new),
          ],
        );
        final boundary = GlobalKey();
        final router = GoRouter(
          initialLocation: AppRoutes.history,
          routes: [
            GoRoute(path: AppRoutes.history, builder: (_, _) => const MeetingsListPage()),
            GoRoute(
              path: '${AppRoutes.meetings}/${AppRoutes.meetingDetailPattern}',
              builder: (_, state) => Scaffold(
                appBar: AppBar(title: const Text('导航目标')),
                body: Text('meeting-id:${state.pathParameters[AppRoutes.meetingIdParam]}'),
              ),
            ),
          ],
        );
        final l = lookupAppLocalizations(const Locale('zh'));
        List<String> titles() => [
          for (final tile in t.widgetList<ListTile>(find.byType(ListTile)))
            if (tile.title case Text(:final String data)) data,
        ];
        Future<void> query(String value, {bool settle = true}) async {
          await t.enterText(find.byType(TextField), value);
          await t.pump();
          await t.pump(const Duration(milliseconds: 20));
          if (settle) await t.pumpAndSettle();
        }

        Future<void> step(
          String operation,
          String expected,
          Future<void> Function() run, {
          String? shot,
        }) async {
          checkBudget();
          final row = <String, Object?>{
            'phase': capture ? 'screenshots' : 'assertions',
            'viewport': '${size.width.toInt()}x${size.height.toInt()}',
            'operation': operation,
            'expected': expected,
            'actual': '',
            'pass': false,
            'screenshot': null,
          };
          try {
            await run();
            final exception = t.takeException();
            if (exception != null) throw StateError('$exception');
            row['actual'] = {'visibleTitles': titles(), 'route': router.state.uri.toString()};
            if (capture && shot != null) {
              final path =
                  'screenshots/${(++number).toString().padLeft(2, '0')}-${size.width.toInt()}-$shot.png';
              await t.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                        .toImage();
                final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
                final file = File('${output.path}/$path');
                file.parent.createSync(recursive: true);
                file.writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
              row['screenshot'] = path;
            }
            row['pass'] = true;
          } catch (e) {
            row['actual'] = '$e';
            rethrow;
          } finally {
            emit(row);
          }
        }

        try {
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: c,
              child: RepaintBoundary(
                key: boundary,
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
          await t.runAsync(
            () => precacheImage(const AssetImage(BrandAssets.logo), boundary.currentContext!),
          );
          await t.pumpAndSettle();
          await step('打开历史记录', '正常列表和标题/转写搜索入口可见', () async {
            expect(titles(), containsAll(['移动端预算评审', 'Design Review', '研发周会']));
            expect(find.text(l.meetingsSearchHint), findsOneWidget);
          }, shot: 'normal');
          for (final text in ['移动', '评审']) {
            await step('标题部分匹配：$text', '仅标题包含关键词且没有转写的会议也能找到', () async {
              await query(text);
              expect(titles(), ['移动端预算评审']);
            });
          }
          await step('标题大小写与空格', '输入两侧空格被忽略，英文大小写无关', () async {
            await query('  dEsIgN  ');
            expect(titles(), ['Design Review']);
          }, shot: 'title');
          await step('字面量部分匹配', '百分号和下划线按普通字符匹配', () async {
            await query('%_');
            expect(titles(), ['进度 100%_完成']);
          });
          final pending = Completer<void>();
          await step('转写搜索加载时保留标题命中', '标题中间部分立即命中，进度条显示，旧结果不混入', () async {
            repo.searchGates = {'预算': pending};
            await query('预算', settle: false);
            expect(titles(), ['移动端预算评审']);
            expect(find.byType(LinearProgressIndicator), findsOneWidget);
          }, shot: 'loading');
          await step('合并转写命中', '标题和内容命中取并集，按原列表排序，重复转写只显示一个会议', () async {
            pending.complete();
            await t.pumpAndSettle();
            repo.searchGates = {};
            expect(titles(), ['移动端预算评审', '研发周会']);
            expect(find.textContaining('预算', findRichText: true), findsWidgets);
          }, shot: 'union');
          await step('仅转写内容命中', '标题没有关键词时仍能通过内容查到会议', () async {
            await query('费用');
            expect(titles(), ['研发周会']);
          });
          await step('复现截图中的m搜索404', '两条标题结果正常展示，无资源不存在错误块，仅提示内容搜索暂不可用', () async {
            repo.searchError = const ApiException(kind: ApiErrorKind.notFound, statusCode: 404);
            await query('m');
            expect(titles(), [
              'Meeting Transcript Review – Insufficient Content',
              'Meeting Report – Transcript Lacking Substantive Content',
            ]);
            expect(find.text(l.errorNotFound), findsNothing);
            expect(find.byIcon(Icons.error_outline), findsNothing);
            expect(find.text(l.meetingsSearchPartialWarning), findsOneWidget);
            expect(find.text(l.commonRetry), findsOneWidget);
          }, shot: '404-with-title');
          await step('失败降级结果仍可打开', '内容搜索失败时标题结果仍能导航到正确会议ID', () async {
            await t.tap(find.text('Meeting Transcript Review – Insufficient Content'));
            await t.pumpAndSettle();
            expect(find.text('meeting-id:english-1'), findsOneWidget);
            router.pop();
            await t.pumpAndSettle();
          });
          await step('m搜索恢复后不再提示失败', '两条英文标题匹配正常展示，重试后移除提示和重试按钮', () async {
            repo.searchError = null;
            await t.tap(find.text(l.commonRetry));
            await t.pumpAndSettle();
            expect(titles(), [
              'Meeting Transcript Review – Insufficient Content',
              'Meeting Report – Transcript Lacking Substantive Content',
            ]);
            expect(find.text(l.meetingsSearchPartialWarning), findsNothing);
            expect(find.text(l.commonRetry), findsNothing);
            expect(find.byIcon(Icons.error_outline), findsNothing);
          }, shot: 'm-success');
          await step('内容搜索503保留本地结果', '轻量内容搜索提示和重试入口可见，已匹配标题仍可操作', () async {
            repo.searchError = const ApiException(kind: ApiErrorKind.unavailable);
            await query('预算');
            expect(titles(), ['移动端预算评审']);
            expect(find.text(l.commonRetry), findsOneWidget);
            expect(find.text(l.meetingsSearchPartialWarning), findsOneWidget);
            expect(find.byIcon(Icons.error_outline), findsNothing);
          }, shot: 'error-with-title');
          await step('搜索重试恢复', '重试后移除错误并恢复合并结果', () async {
            repo.searchError = null;
            await t.tap(find.text(l.commonRetry));
            await t.pumpAndSettle();
            expect(titles(), ['移动端预算评审', '研发周会']);
            expect(find.text(l.commonRetry), findsNothing);
            expect(find.text(l.meetingsSearchPartialWarning), findsNothing);
          });
          await step('无标题命中时的搜索失败', '显示错误和重试入口，不误报无结果', () async {
            repo.searchError = const ApiException(kind: ApiErrorKind.unavailable);
            await query('费用');
            expect(titles(), isEmpty);
            expect(find.text(l.commonRetry), findsOneWidget);
            expect(find.text(l.meetingsSearchEmpty), findsNothing);
          }, shot: 'error');
          await step('无匹配空态', '搜索成功但无匹配时显示空态', () async {
            repo.searchError = null;
            await query('不存在的会议');
            expect(titles(), isEmpty);
            expect(find.text(l.meetingsSearchEmpty), findsOneWidget);
          }, shot: 'empty');
          await step('长标题匹配', '长标题能部分匹配，窄屏布局没有溢出异常', () async {
            await query('点击区域');
            expect(titles(), [repo.items.firstWhere((m) => m.id == 'long').title]);
          }, shot: 'long-title');
          await step('打开搜索结果', '搜索结果点击后解析到正确会议ID', () async {
            await t.tap(find.text(repo.items.firstWhere((m) => m.id == 'long').title));
            await t.pumpAndSettle();
            expect(find.text('meeting-id:long'), findsOneWidget);
            router.pop();
            await t.pumpAndSettle();
            expect(find.byType(MeetingsListPage), findsOneWidget);
          });
          await step('清除搜索', '恢复原始历史记录列表', () async {
            await t.tap(find.byTooltip(l.meetingsSearchClear));
            await t.pumpAndSettle();
            expect(titles(), containsAll(['移动端预算评审', 'Design Review', '研发周会']));
            expect(t.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
          });
        } finally {
          await t.pumpWidget(const SizedBox.shrink());
          router.dispose();
          c.dispose();
          await t.pump();
        }
      }
    }
    await t.binding.setSurfaceSize(null);
    File('${output.path}/execution-finished.json').writeAsStringSync(
      jsonEncode({'elapsedMs': DateTime.now().millisecondsSinceEpoch - start, 'limitMs': 1800000}),
    );
  });
}
