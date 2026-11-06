import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/client_models.dart';
import 'package:meeting/core/api/models/summary_models.dart';
import 'package:meeting/core/heartbeat/heartbeat_controller.dart';
import 'package:meeting/features/summary/data/summary_repository_impl.dart';
import 'package:meeting/features/summary/domain/summary_document.dart';
import 'package:meeting/features/summary/domain/summary_repository.dart';
import 'package:meeting/features/summary/domain/summary_state.dart';
import 'package:meeting/features/summary/presentation/summary_controller.dart';

import '../../helpers/test_config.dart';

const _pid = '2026-10-07T03:59:35.123456789Z';

SummaryResponse _res(SummaryStatus status, {String? start = _pid, Object? data, String? error}) =>
    SummaryResponse(status: status, meetingId: 'm1', start: start, data: data, error: error);

class FakeSummaryRepository implements SummaryRepository {
  /// Responses of successive `get` calls (the last one repeats).
  final Queue<SummaryResponse> responses = Queue();
  final List<String> calls = [];
  String? lastPrompt;
  String? saved;
  ApiException? saveError;

  @override
  Future<ProcessStarted> start(String meetingId, {String? customPrompt}) async {
    calls.add('start');
    lastPrompt = customPrompt;
    return const ProcessStarted(message: 'Summary generation started', processId: _pid);
  }

  @override
  Future<SummaryResponse> get(String meetingId) async {
    calls.add('get');
    return responses.length > 1 ? responses.removeFirst() : responses.first;
  }

  @override
  Future<void> cancel(String meetingId) async => calls.add('cancel');

  @override
  Future<void> saveMarkdown(String meetingId, String markdown) async {
    calls.add('save');
    if (saveError case final e?) throw e;
    saved = markdown;
  }
}

void main() {
  late FakeSummaryRepository repo;
  late ProviderContainer c;
  final provider = summaryControllerProvider('m1');

  Future<void> setUpContainer({int maxPolls = 10, Duration sleep = Duration.zero}) async {
    final base = loadConfigFile('dev');
    c = await createTestContainer(
      config: base.copyWith(polling: base.polling.copyWith(summaryMaxPolls: maxPolls)),
      overrides: [
        summaryRepositoryProvider.overrideWithValue(repo),
        summaryPollSleeperProvider.overrideWithValue((_) => Future<void>.delayed(sleep)),
      ],
    );
    final sub = c.listen(provider, (_, _) {});
    addTearDown(sub.close);
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  setUp(() => repo = FakeSummaryRepository());

  test('restores an existing summary', () async {
    repo.responses.add(_res(SummaryStatus.completed, data: {'markdown': '## 要点'}));
    await setUpContainer();
    expect(
      await c.read(provider.future),
      const SummaryState.ready(summary: SummaryDocument(content: '## 要点')),
    );
  });

  test('idle → empty', () async {
    repo.responses.add(_res(SummaryStatus.idle, start: null));
    await setUpContainer();
    expect(await c.read(provider.future), const SummaryState.empty());
    expect(c.read(provider).value!.canAutoStart, isTrue);
  });

  test('pending → processing → completed', () async {
    repo.responses.addAll([
      _res(SummaryStatus.idle, start: null), // build
      _res(SummaryStatus.pending),
      _res(SummaryStatus.processing),
      _res(SummaryStatus.completed, data: {'markdown': '# 总结'}),
    ]);
    await setUpContainer();
    await c.read(provider.future);

    final states = <SummaryState>[];
    c.listen(provider, (_, next) {
      if (next.value case final v?) states.add(v);
    });
    await c.read(provider.notifier).generate(customPrompt: '背景');

    expect(repo.lastPrompt, '背景');
    expect(states.first, isA<SummaryGenerating>());
    expect((states[1] as SummaryGenerating).processId, _pid);
    expect(
      c.read(provider).value,
      const SummaryState.ready(summary: SummaryDocument(content: '# 总结'), fresh: true),
    );
    expect(repo.calls.where((x) => x == 'get').length, 4);
  });

  test('responses of another run (different start) are ignored', () async {
    repo.responses.addAll([
      _res(SummaryStatus.idle, start: null),
      _res(SummaryStatus.completed, start: 'older-run', data: {'markdown': 'OLD'}),
      _res(SummaryStatus.failed, start: 'older-run', error: 'x'),
      _res(SummaryStatus.completed, data: {'markdown': 'NEW'}),
    ]);
    await setUpContainer();
    await c.read(provider.future);
    await c.read(provider.notifier).generate();
    expect(
      c.read(provider).value,
      const SummaryState.ready(summary: SummaryDocument(content: 'NEW'), fresh: true),
    );
  });

  test('failure keeps the summary the server restored', () async {
    repo.responses.addAll([
      _res(SummaryStatus.completed, data: {'markdown': 'OLD'}),
      _res(SummaryStatus.failed, error: 'LLM 超时', data: {'markdown': 'OLD'}),
    ]);
    await setUpContainer();
    await c.read(provider.future);
    await c.read(provider.notifier).generate();
    final state = c.read(provider).value! as SummaryFailed;
    expect(state.reason, SummaryFailure.generation);
    expect(state.message, 'LLM 超时');
    expect(state.previous, const SummaryDocument(content: 'OLD'));
  });

  test('completed without visible content → emptyResult', () async {
    repo.responses.addAll([
      _res(SummaryStatus.idle, start: null),
      _res(SummaryStatus.completed, data: {'markdown': '   '}),
    ]);
    await setUpContainer();
    await c.read(provider.future);
    await c.read(provider.notifier).generate();
    expect((c.read(provider).value! as SummaryFailed).reason, SummaryFailure.emptyResult);
  });

  test('gives up after summaryMaxPolls', () async {
    repo.responses.addAll([_res(SummaryStatus.idle, start: null), _res(SummaryStatus.processing)]);
    await setUpContainer(maxPolls: 3);
    await c.read(provider.future);
    await c.read(provider.notifier).generate();
    expect((c.read(provider).value! as SummaryFailed).reason, SummaryFailure.timeout);
    expect(repo.calls.where((x) => x == 'get').length, 1 + 3);
  });

  test('stop cancels on the server and restores the previous summary', () async {
    repo.responses.addAll([
      _res(SummaryStatus.processing, data: {'markdown': 'OLD'}), // build: resumes polling
      _res(SummaryStatus.processing),
    ]);
    await setUpContainer(maxPolls: 1000, sleep: const Duration(milliseconds: 2));
    final initial = await c.read(provider.future);
    expect(initial, isA<SummaryGenerating>());
    await settle();

    await c.read(provider.notifier).stop();
    expect(repo.calls, contains('cancel'));
    expect(
      c.read(provider).value,
      const SummaryState.ready(summary: SummaryDocument(content: 'OLD')),
    );

    final polls = repo.calls.where((x) => x == 'get').length;
    await settle();
    expect(repo.calls.where((x) => x == 'get').length, polls, reason: 'polling stopped');
  });

  test('LLM not ready → no request', () async {
    repo.responses.add(_res(SummaryStatus.idle, start: null));
    await setUpContainer();
    await c.read(provider.future);
    c
        .read(capabilitiesProvider.notifier)
        .set(
          const Capabilities(
            serverVersion: '1',
            stt: SttStatus(ready: true),
            llm: LlmStatus(ready: false, error: '未配置'),
          ),
        );
    await c.read(provider.notifier).generate();
    final state = c.read(provider).value! as SummaryFailed;
    expect(state.reason, SummaryFailure.llmNotReady);
    expect(repo.calls, isNot(contains('start')));
  });

  test('save sends markdown and shows it; errors are rethrown', () async {
    repo.responses.add(_res(SummaryStatus.completed, data: {'markdown': 'A'}));
    await setUpContainer();
    await c.read(provider.future);
    await c.read(provider.notifier).save('B');
    expect(repo.saved, 'B');
    expect(
      c.read(provider).value,
      const SummaryState.ready(summary: SummaryDocument(content: 'B')),
    );

    repo.saveError = const ApiException(kind: ApiErrorKind.badRequest, message: '总结内容为空');
    await expectLater(c.read(provider.notifier).save(''), throwsA(isA<ApiException>()));
    expect(
      c.read(provider).value,
      const SummaryState.ready(summary: SummaryDocument(content: 'B')),
    );
  });

  test('the render format comes from the summary data', () async {
    repo.responses.add(
      _res(SummaryStatus.completed, data: {'markdown': '<h2>要点</h2>', 'format': 'html'}),
    );
    await setUpContainer();
    expect(
      await c.read(provider.future),
      const SummaryState.ready(
        summary: SummaryDocument(content: '<h2>要点</h2>', format: SummaryFormat.html),
      ),
    );
  });

  test('regenerating keeps the previous summary with its format', () async {
    repo.responses.addAll([
      _res(
        SummaryStatus.completed,
        data: {'markdown': 'Budget <mark>ok</mark>', 'format': 'mixed'},
      ),
      _res(SummaryStatus.processing),
    ]);
    await setUpContainer(maxPolls: 1);
    await c.read(provider.future);
    await c.read(provider.notifier).generate();
    final state = c.read(provider).value! as SummaryFailed;
    expect(state.reason, SummaryFailure.timeout);
    expect(state.previous?.format, SummaryFormat.mixed);
  });
}
