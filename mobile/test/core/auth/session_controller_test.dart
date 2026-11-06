import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_client.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/data/session_store.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/features/meetings/data/meetings_repository_impl.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_config.dart';

const _server = 'http://server.test';

Future<(ProviderContainer, FakeAuthRepository)> _setup({
  String server = _server,
  Map<String, String> secure = const {},
}) async {
  final repo = FakeAuthRepository();
  final container = await createTestContainer(
    config: server.isEmpty ? loadConfigWithoutServer() : loadConfigWithServer(server),
    secure: secure,
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  return (container, repo);
}

Future<AuthState> _state(ProviderContainer c) => c.read(sessionControllerProvider.future);

void main() {
  test('unconfigured when no server URL is set', () async {
    final (c, _) = await _setup(server: '');
    expect(await _state(c), const AuthState.unconfigured());
  });

  test('signedOut when a server is configured but no session is stored', () async {
    final (c, _) = await _setup();
    expect(await _state(c), const AuthState.signedOut());
  });

  test('login → signedIn, token persisted, phone normalized', () async {
    final (c, repo) = await _setup();
    await _state(c);
    final user = await c
        .read(sessionControllerProvider.notifier)
        .login('+86 138-0013-8000', ' 123456 ');
    expect(user, testUser);
    expect(repo.lastPhone, '13800138000');
    expect(c.read(sessionControllerProvider).value, const AuthState.signedIn(testUser));
    expect(c.read(isSignedInProvider), isTrue);
    expect(c.read(currentUserProvider), testUser);
    expect(await c.read(sessionStoreProvider).currentToken(), 'ms_test_token');
  });

  test('failed login leaves the state unchanged', () async {
    final (c, repo) = await _setup();
    await _state(c);
    repo.failWith = const ApiException(
      kind: ApiErrorKind.badRequest,
      statusCode: 400,
      message: '验证码错误',
    );
    await expectLater(
      c.read(sessionControllerProvider.notifier).login('13800138000', '000000'),
      throwsA(isA<ApiException>()),
    );
    expect(c.read(sessionControllerProvider).value, const AuthState.signedOut());
  });

  test('register signs in with the given name', () async {
    final (c, repo) = await _setup();
    await _state(c);
    final user = await c
        .read(sessionControllerProvider.notifier)
        .register('13800138000', '123456', ' 李四 ', ' Pass1234 ');
    expect(user.name, '李四');
    expect(repo.calls, contains('register'));
    expect(repo.lastPassword, ' Pass1234 ', reason: 'passwords are never trimmed');
    expect(c.read(isSignedInProvider), isTrue);
  });

  test('password login, reset and change', () async {
    final (c, repo) = await _setup();
    await _state(c);
    final session = c.read(sessionControllerProvider.notifier);
    await session.loginWithPassword('+86 138 0013 8000', 'Pass1234');
    expect(repo.lastPhone, '13800138000');
    expect(repo.calls, contains('loginWithPassword'));
    expect(c.read(isSignedInProvider), isTrue);

    final changed = await session.changePassword(oldPassword: 'Pass1234', password: 'New12345');
    expect(changed.hasPassword, isTrue);
    expect(repo.lastOldPassword, 'Pass1234');
    expect(c.read(currentUserProvider)?.hasPassword, isTrue);

    await session.logout();
    await session.resetPassword('13800138000', ' 123456 ', 'Reset123');
    expect(repo.calls, contains('resetPassword'));
    expect(c.read(isSignedInProvider), isTrue);
  });

  test('restores a stored session for the same server', () async {
    final (c, repo) = await _setup();
    await _state(c);
    await c.read(sessionControllerProvider.notifier).login('13800138000', '123456');

    // A fresh container (app restart) sharing the mocked storage.
    final c2 = await createTestContainer(
      config: loadConfigWithServer(_server),
      secure: await _dumpSecure(c),
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    expect(await _state(c2), const AuthState.signedIn(testUser));
  });

  test('a session issued by another server (older builds) is discarded', () async {
    final (c, _) = await _setup();
    await _state(c);
    await c
        .read(sessionStoreProvider)
        .save(
          const StoredSession(token: 'ms_other', user: testUser, serverUrl: 'http://other.test'),
        );
    c.invalidate(sessionControllerProvider);
    expect(await _state(c), const AuthState.signedOut());
    expect(await c.read(sessionStoreProvider).currentToken(), isNull);
  });

  test('expire → expired and token cleared; no-op when not signed in', () async {
    final (c, _) = await _setup();
    await _state(c);
    final notifier = c.read(sessionControllerProvider.notifier);
    await notifier.expire();
    expect(c.read(sessionControllerProvider).value, const AuthState.signedOut());

    await notifier.login('13800138000', '123456');
    await notifier.expire();
    expect(c.read(sessionControllerProvider).value, const AuthState.expired());
    expect(await c.read(sessionStoreProvider).currentToken(), isNull);
  });

  test('a 401 on an authenticated request expires the session', () async {
    final (c, _) = await _setup();
    await _state(c);
    await c.read(sessionControllerProvider.notifier).login('13800138000', '123456');

    final adapter = StubAdapter(401, {'detail': '登录凭证无效，请重新登录'});
    c.read(apiClientProvider).httpClientAdapter = adapter;
    await expectLater(
      c.read(meetingsRepositoryProvider).listMeetings(),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
    );
    expect(adapter.requests.single.headers[AuthHeader.name], 'Bearer ms_test_token');
    await pumpEventQueue();
    expect(c.read(sessionControllerProvider).value, const AuthState.expired());
  });

  test('logout → signedOut and the token is revoked on the server', () async {
    final (c, repo) = await _setup();
    await _state(c);
    final notifier = c.read(sessionControllerProvider.notifier);
    await notifier.login('13800138000', '123456');
    await notifier.logout();
    expect(c.read(sessionControllerProvider).value, const AuthState.signedOut());
    expect(repo.loggedOutToken, 'ms_test_token');
    expect(await c.read(sessionStoreProvider).currentToken(), isNull);
  });

  test('updateName / refreshMe replace the signed-in user', () async {
    final (c, _) = await _setup();
    await _state(c);
    final notifier = c.read(sessionControllerProvider.notifier);
    await notifier.login('13800138000', '123456');
    await notifier.updateName('王五');
    expect(c.read(currentUserProvider)?.name, '王五');
    final me = await notifier.refreshMe();
    expect(me?.name, '王五');
  });

  test('sendCode normalizes the phone and passes the purpose', () async {
    final (c, repo) = await _setup();
    await _state(c);
    final result = await c
        .read(sessionControllerProvider.notifier)
        .sendCode('8613800138000', AuthPurpose.register);
    expect(result.devCode, '123456');
    expect(repo.lastPhone, '13800138000');
    expect(repo.calls, contains('sendCode:register'));
  });
}

/// Copies the mocked secure storage content of [c] (token, user, server URL).
Future<Map<String, String>> _dumpSecure(ProviderContainer c) async {
  final storage = c.read(secureStorageProvider);
  return storage.readAll();
}
