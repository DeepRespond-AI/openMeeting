import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/meeting_models.dart';
import 'package:meeting/core/data/meetings_changed.dart';
import 'package:meeting/features/meetings/data/meetings_repository_impl.dart';
import 'package:meeting/features/meetings/presentation/meeting_detail_controller.dart';
import 'package:meeting/features/meetings/presentation/meetings_list_controller.dart';

import '../../helpers/test_config.dart';
import 'fake_meetings_repository.dart';

void main() {
  late FakeMeetingsRepository repo;

  Future<ProviderContainer> container({int debounceMs = 0}) async {
    final base = loadConfigFile('dev');
    return createTestContainer(
      config: base.copyWith(
        pagination: base.pagination.copyWith(
          meetingSearchDebounceMs: debounceMs,
          transcriptPageSize: 3,
        ),
      ),
      overrides: [meetingsRepositoryProvider.overrideWithValue(repo)],
    );
  }

  setUp(() => repo = FakeMeetingsRepository());

  group('MeetingsListController', () {
    test('loads and refreshes the meeting list', () async {
      final c = await container();
      final sub = c.listen(meetingsListControllerProvider, (_, _) {});
      addTearDown(sub.close);

      expect(await c.read(meetingsListControllerProvider.future), repo.items);

      repo.items = const [
        MeetingSummary(id: 'm2', title: '新会议'),
        MeetingSummary(id: 'm1', title: '周会'),
      ];
      await c.read(meetingsListControllerProvider.notifier).refresh();
      expect(c.read(meetingsListControllerProvider).value, repo.items);
      expect(repo.listCalls, 2);
    });

    test('reloads when another feature creates a meeting (meetingsChanged)', () async {
      final c = await container();
      final sub = c.listen(meetingsListControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(meetingsListControllerProvider.future);

      repo.items = const [MeetingSummary(id: 'm9', title: '刚录完的会议')];
      c.read(meetingsChangedProvider.notifier).bump();
      expect(await c.read(meetingsListControllerProvider.future), repo.items);
      expect(repo.listCalls, 2);
    });

    test('errors surface as AsyncError', () async {
      repo.error = const ApiException(kind: ApiErrorKind.network);
      final c = await container();
      final sub = c.listen(meetingsListControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await c.read(meetingsListControllerProvider.notifier).refresh();
      expect(c.read(meetingsListControllerProvider).error, isA<ApiException>());
    });

    test('optimistic delete removes the item immediately', () async {
      repo.items = const [
        MeetingSummary(id: 'a', title: 'A'),
        MeetingSummary(id: 'b', title: 'B'),
        MeetingSummary(id: 'c', title: 'C'),
      ];
      final c = await container();
      final sub = c.listen(meetingsListControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(meetingsListControllerProvider.future);

      final pending = c.read(meetingsListControllerProvider.notifier).deleteMeeting('b');
      // Removed before the server answered.
      expect(c.read(meetingsListControllerProvider).value!.map((m) => m.id), ['a', 'c']);
      await pending;
      expect(repo.deleted, ['b']);
      expect(c.read(meetingsListControllerProvider).value!.map((m) => m.id), ['a', 'c']);
    });

    test('failed delete rolls back to the original position and rethrows', () async {
      repo.items = const [
        MeetingSummary(id: 'a', title: 'A'),
        MeetingSummary(id: 'b', title: 'B'),
        MeetingSummary(id: 'c', title: 'C'),
      ];
      repo.deleteError = const ApiException(kind: ApiErrorKind.server, statusCode: 500);
      final c = await container();
      final sub = c.listen(meetingsListControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await c.read(meetingsListControllerProvider.future);

      await expectLater(
        c.read(meetingsListControllerProvider.notifier).deleteMeeting('b'),
        throwsA(isA<ApiException>()),
      );
      expect(c.read(meetingsListControllerProvider).value!.map((m) => m.id), ['a', 'b', 'c']);
    });

    test('rename in the detail page updates the list title', () async {
      final c = await container();
      final list = c.listen(meetingsListControllerProvider, (_, _) {});
      final detail = c.listen(meetingDetailControllerProvider('m1'), (_, _) {});
      addTearDown(list.close);
      addTearDown(detail.close);
      await c.read(meetingsListControllerProvider.future);
      await c.read(meetingDetailControllerProvider('m1').future);

      await c.read(meetingDetailControllerProvider('m1').notifier).rename('新标题');
      expect(c.read(meetingsListControllerProvider).value!.single.title, '新标题');
    });

    test('failed rename rolls back the title', () async {
      final c = await container();
      final detail = c.listen(meetingDetailControllerProvider('m1'), (_, _) {});
      addTearDown(detail.close);
      await c.read(meetingDetailControllerProvider('m1').future);
      repo.error = const ApiException(kind: ApiErrorKind.network);

      await expectLater(
        c.read(meetingDetailControllerProvider('m1').notifier).rename('X'),
        throwsA(isA<ApiException>()),
      );
      expect(c.read(meetingDetailControllerProvider('m1')).value!.title, 'T');
    });
  });

  group('MeetingSearchController', () {
    const hit = TranscriptSearchResult(id: 'm1', title: '周会', matchContext: '...预算...');

    test('debounced search shows results with match context', () async {
      repo.searchResults = {
        '预算': [hit],
      };
      final c = await container();
      final sub = c.listen(meetingSearchControllerProvider, (_, _) {});
      addTearDown(sub.close);

      c.read(meetingSearchControllerProvider.notifier).setQuery('  预算 ');
      expect(c.read(meetingSearchControllerProvider).results.isLoading, isTrue);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final state = c.read(meetingSearchControllerProvider);
      expect(state.query, '预算');
      expect(state.results.value, [hit]);

      c.read(meetingSearchControllerProvider.notifier).clear();
      expect(c.read(meetingSearchControllerProvider).isActive, isFalse);
    });

    test('only the last query within the debounce window is sent', () async {
      final c = await container(debounceMs: 50);
      final sub = c.listen(meetingSearchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final notifier = c.read(meetingSearchControllerProvider.notifier);
      notifier
        ..setQuery('a')
        ..setQuery('ab')
        ..setQuery('abc');
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(repo.searches, ['abc']);
    });

    test('responses for an outdated query are dropped', () async {
      final slow = Completer<void>();
      repo
        ..searchGates = {'old': slow}
        ..searchResults = {
          'old': [hit],
          'new': const [],
        };
      final c = await container();
      final sub = c.listen(meetingSearchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final notifier = c.read(meetingSearchControllerProvider.notifier)..setQuery('old');
      await Future<void>.delayed(Duration.zero);
      notifier.setQuery('new');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      slow.complete();
      await Future<void>.delayed(Duration.zero);
      final state = c.read(meetingSearchControllerProvider);
      expect(state.query, 'new');
      expect(state.results.value, isEmpty);
    });

    test('clearing and retyping the same query drops the earlier in-flight response', () async {
      final slow = Completer<void>();
      repo.searchGates = {'预算': slow};
      repo.searchResults = {
        '预算': [hit],
      };
      final c = await container();
      final sub = c.listen(meetingSearchControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final notifier = c.read(meetingSearchControllerProvider.notifier)..setQuery('预算');
      await Future<void>.delayed(Duration.zero);
      notifier.clear();
      repo.searchGates = {};
      repo.searchResults = {'预算': []};
      notifier.setQuery('预算');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      repo.searchResults = {
        '预算': [hit],
      };
      slow.complete();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(meetingSearchControllerProvider).results.value, isEmpty);
    });

    test(
      'failed transcript search can retry and clears the previous error while loading',
      () async {
        repo.searchError = const ApiException(kind: ApiErrorKind.unavailable);
        final c = await container();
        final sub = c.listen(meetingSearchControllerProvider, (_, _) {});
        addTearDown(sub.close);
        final notifier = c.read(meetingSearchControllerProvider.notifier)..setQuery('预算');
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(c.read(meetingSearchControllerProvider).results.hasError, isTrue);
        repo.searchError = null;
        repo.searchResults = {
          '预算': [hit],
        };
        final pending = notifier.retry();
        expect(c.read(meetingSearchControllerProvider).results.isLoading, isTrue);
        expect(c.read(meetingSearchControllerProvider).results.hasError, isFalse);
        await pending;
        expect(c.read(meetingSearchControllerProvider).results.value, [hit]);
      },
    );
  });

  group('TranscriptsController', () {
    test('loads pages of transcriptPageSize until has_more is false', () async {
      repo.transcripts = makeTranscripts(7);
      final c = await container();
      final provider = transcriptsControllerProvider('m1');
      final sub = c.listen(provider, (_, _) {});
      addTearDown(sub.close);

      var state = await c.read(provider.future);
      expect(state.items.length, 3);
      expect(state.totalCount, 7);
      expect(state.hasMore, isTrue);

      await c.read(provider.notifier).loadMore();
      await c.read(provider.notifier).loadMore();
      state = c.read(provider).value!;
      expect(state.items.map((t) => t.id), [for (var i = 0; i < 7; i++) 't$i']);
      expect(state.hasMore, isFalse);
      expect(repo.pages, [(3, 0), (3, 3), (3, 6)]);

      await c.read(provider.notifier).loadMore(); // no-op
      expect(repo.pages.length, 3);
    });
  });
}
