import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/client_models.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/heartbeat/client_repository.dart';
import 'package:meeting/core/heartbeat/heartbeat_controller.dart';
import 'package:meeting/core/heartbeat/recording_status.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_config.dart';

class FakeClientRepository implements ClientRepository {
  final List<({bool recording, String? meetingId})> beats = [];
  ApiException? failWith;

  @override
  Future<HeartbeatResult> heartbeat({required bool recording, String? meetingId}) async {
    beats.add((recording: recording, meetingId: meetingId));
    if (failWith case final e?) throw e;
    return const HeartbeatResult(serverVersion: '1.0.0');
  }

  @override
  Future<Capabilities> capabilities() async => const Capabilities(
    serverVersion: '1.0.0',
    stt: SttStatus(engine: 'faster-whisper', model: 'large-v3', ready: true),
    llm: LlmStatus(ready: false),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('beats while signed in, reports recording and fills capabilities', () async {
    final client = FakeClientRepository();
    final c = await createTestContainer(
      config: loadConfigWithServer('http://server.test'),
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        clientRepositoryProvider.overrideWithValue(client),
      ],
    );
    final sub = c.listen(heartbeatControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(sessionControllerProvider.future);
    expect(c.read(heartbeatControllerProvider).active, isFalse);

    await c.read(sessionControllerProvider.notifier).login('13800138000', '123456');
    await pumpEventQueue();
    expect(c.read(heartbeatControllerProvider).active, isTrue);
    expect(client.beats, isNotEmpty);
    expect(c.read(capabilitiesProvider)?.stt.ready, isTrue);
    expect(c.read(heartbeatControllerProvider).connected, isTrue);

    client.beats.clear();
    c.read(recordingStatusControllerProvider.notifier).set(recording: true, meetingId: 'meeting-1');
    await pumpEventQueue();
    expect(client.beats.last, (recording: true, meetingId: 'meeting-1'));

    // Network errors are recorded but never sign out.
    client.failWith = const ApiException(kind: ApiErrorKind.network);
    await c.read(heartbeatControllerProvider.notifier).beatNow();
    expect(c.read(heartbeatControllerProvider).lastError?.kind, ApiErrorKind.network);
    expect(c.read(isSignedInProvider), isTrue);

    await c.read(sessionControllerProvider.notifier).logout();
    await pumpEventQueue();
    expect(c.read(heartbeatControllerProvider).active, isFalse);
    expect(c.read(capabilitiesProvider), isNull);
  });
}
