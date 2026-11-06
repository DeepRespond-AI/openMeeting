import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/data/auth_repository_impl.dart';
import 'package:meeting/core/auth/session_controller.dart';
import 'package:meeting/core/config/app_config.dart';
import 'package:meeting/features/auth/presentation/phone_auth_controller.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_config.dart';

const _server = 'http://server.test';

/// Configurable fake: send failures, resend interval, auth config.
class _Repo extends FakeAuthRepository {
  ApiException? sendFailure;
  int resendAfterSec = 60;
  AuthConfig config = const AuthConfig(
    registrationOpen: true,
    smsReady: true,
    codeLength: 6,
    resendIntervalSec: 45,
    serverVersion: 'test',
  );

  @override
  Future<AuthConfig> fetchAuthConfig({String? serverUrl}) async => config;

  @override
  Future<SendCodeResult> sendCode({required String phone, required AuthPurpose purpose}) async {
    if (sendFailure case final e?) throw e;
    await super.sendCode(phone: phone, purpose: purpose);
    return SendCodeResult(
      sent: true,
      resendAfterSec: resendAfterSec,
      expiresInSec: 300,
      devCode: '123456',
    );
  }
}

Future<(ProviderContainer, _Repo)> _setup({AppConfig? config}) async {
  final repo = _Repo();
  final c = await createTestContainer(
    config: config ?? loadConfigWithServer(_server),
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  // Keep the auto-disposed controller (and the auth config it listens to) alive.
  c.listen(phoneAuthControllerProvider, (_, _) {});
  await c.read(sessionControllerProvider.future);
  await c.read(authConfigProvider.future);
  return (c, repo);
}

PhoneAuthController _ctrl(ProviderContainer c) => c.read(phoneAuthControllerProvider.notifier);
PhoneAuthState _state(ProviderContainer c) => c.read(phoneAuthControllerProvider);

void main() {
  group('validation', () {
    test('invalid phone blocks sending', () async {
      final (c, repo) = await _setup();
      _ctrl(c).setPhone('12345');
      expect(await _ctrl(c).sendCode(), isFalse);
      expect(_state(c).issues, {PhoneAuthIssue.phoneInvalid});
      expect(repo.calls, isNot(contains('sendCode:login')));
      // Editing the field clears its issue.
      _ctrl(c).setPhone('138');
      expect(_state(c).issues, isEmpty);
    });

    test('code length comes from the server auth config', () async {
      final (c, _) = await _setup();
      expect(c.read(authCodeLengthProvider), 6);
      _ctrl(c)
        ..setMethod(LoginMethod.code)
        ..setPhone('13800138000')
        ..setCode('12345');
      expect(await _ctrl(c).submit(), isNull);
      expect(_state(c).issues, {PhoneAuthIssue.codeInvalid});
    });

    test('register needs a name within AppConfig.auth.nameMaxLength', () async {
      final (c, _) = await _setup();
      final max = loadConfigFile('dev').auth.nameMaxLength;
      _ctrl(c)
        ..setMode(PhoneAuthMode.register)
        ..setPhone('13800138000')
        ..setCode('123456')
        ..setPassword('Pass1234')
        ..setConfirm('Pass1234');
      expect(await _ctrl(c).submit(), isNull);
      expect(_state(c).issues, {PhoneAuthIssue.nameRequired});
      _ctrl(c).setName('x' * (max + 1));
      expect(await _ctrl(c).submit(), isNull);
      expect(_state(c).issues, {PhoneAuthIssue.nameTooLong});
    });

    test('password login needs a password but no code', () async {
      final (c, _) = await _setup();
      expect(_state(c).method, LoginMethod.password);
      _ctrl(c).setPhone('13800138000');
      expect(await _ctrl(c).submit(), isNull);
      expect(_state(c).issues, {PhoneAuthIssue.passwordRequired});
      // Login does not apply the new-password rules (the server checks the password).
      _ctrl(c).setPassword('x');
      expect(_state(c).issues, isEmpty);
    });

    test('new passwords follow the server rules and must be confirmed', () async {
      final (c, repo) = await _setup();
      repo.config = repo.config.copyWith(passwordMinLength: 10, passwordMaxLength: 20);
      c.invalidate(authConfigProvider);
      await c.read(authConfigProvider.future);
      _ctrl(c)
        ..setMode(PhoneAuthMode.reset)
        ..setPhone('13800138000')
        ..setCode('123456');
      Future<Set<PhoneAuthIssue>> issuesFor(String password, String confirm) async {
        _ctrl(c)
          ..setPassword(password)
          ..setConfirm(confirm);
        await _ctrl(c).submit();
        return _state(c).issues;
      }

      expect(await issuesFor('Pass1234', 'Pass1234'), {PhoneAuthIssue.passwordLength});
      expect(await issuesFor(' Pass12345', ' Pass12345'), {PhoneAuthIssue.passwordSpaces});
      expect(await issuesFor('onlyletters', 'onlyletters'), {PhoneAuthIssue.passwordLetterDigit});
      expect(await issuesFor('Pass123456', 'Pass12345x'), {PhoneAuthIssue.passwordMismatch});
    });
  });

  test('send code: dev code shown (dev config), countdown runs down to zero', () {
    fakeAsync((async) {
      late ProviderContainer c;
      late _Repo repo;
      _setup().then((v) => (c, repo) = v);
      async.flushMicrotasks();

      _ctrl(c).setPhone('+86 138 0013 8000');
      _ctrl(c).sendCode();
      async.flushMicrotasks();
      expect(repo.lastPhone, '13800138000');
      expect(repo.calls, contains('sendCode:login'));
      expect(_state(c).codeSent, isTrue);
      expect(_state(c).devCode, '123456');
      expect(_state(c).countdown, 60);
      expect(_state(c).canSendCode, isFalse);

      async.elapse(const Duration(seconds: 1));
      expect(_state(c).countdown, 59);
      async.elapse(const Duration(seconds: 59));
      expect(_state(c).countdown, 0);
      expect(_state(c).canSendCode, isTrue);
    });
  });

  test('countdown falls back to authConfig.resendIntervalSec', () {
    fakeAsync((async) {
      late ProviderContainer c;
      late _Repo repo;
      _setup().then((v) => (c, repo) = v);
      async.flushMicrotasks();
      repo.resendAfterSec = 0;
      _ctrl(c).setPhone('13800138000');
      _ctrl(c).sendCode();
      async.flushMicrotasks();
      expect(_state(c).countdown, 45);
      async.elapse(const Duration(seconds: 45));
      expect(_state(c).countdown, 0);
    });
  });

  test('dev code hidden when AppConfig.features.showDevCode is false', () async {
    final prod = loadConfigFile('prod');
    final (c, _) = await _setup(config: prod.copyWith.features(showDevCode: false));
    _ctrl(c).setPhone('13800138000');
    expect(await _ctrl(c).sendCode(), isTrue);
    expect(_state(c).devCode, isNull);
  });

  test('send error is kept with the server detail; no countdown', () async {
    final (c, repo) = await _setup();
    repo.sendFailure = const ApiException(
      kind: ApiErrorKind.notFound,
      statusCode: 404,
      message: '该手机号未注册',
    );
    _ctrl(c).setPhone('13800138000');
    expect(await _ctrl(c).sendCode(), isFalse);
    expect(_state(c).sending, isFalse);
    expect(_state(c).countdown, 0);
    expect(_state(c).error?.message, '该手机号未注册');
  });

  test('SMS-code login success signs the session in', () async {
    final (c, repo) = await _setup();
    _ctrl(c)
      ..setMethod(LoginMethod.code)
      ..setPhone('13800138000')
      ..setCode('123456');
    final user = await _ctrl(c).submit();
    expect(user, testUser);
    expect(repo.calls, contains('login'));
    expect(c.read(sessionControllerProvider).value, const AuthState.signedIn(testUser));
    expect(_state(c).submitting, isFalse);
  });

  test('password login success signs in and clears the password', () async {
    final (c, repo) = await _setup();
    _ctrl(c)
      ..setPhone('13800138000')
      ..setPassword('Pass1234');
    expect(await _ctrl(c).submit(), testUser);
    expect(repo.calls, contains('loginWithPassword'));
    expect(repo.calls, isNot(contains('login')));
    expect(repo.lastPassword, 'Pass1234');
    expect(c.read(isSignedInProvider), isTrue);
    expect(_state(c).password, isEmpty);
  });

  test('register success signs in with the entered name and password', () async {
    final (c, repo) = await _setup();
    _ctrl(c)
      ..setMode(PhoneAuthMode.register)
      ..setPhone('13800138000')
      ..setCode('123456')
      ..setName(' 李四 ')
      ..setPassword('Pass1234')
      ..setConfirm('Pass1234');
    final user = await _ctrl(c).submit();
    expect(user?.name, '李四');
    expect(user?.hasPassword, isTrue);
    expect(repo.calls, contains('register'));
    expect(repo.lastPassword, 'Pass1234');
    expect(c.read(isSignedInProvider), isTrue);
  });

  test('forgot password: reset code, new password, signed in', () async {
    final (c, repo) = await _setup();
    _ctrl(c)
      ..setMode(PhoneAuthMode.reset)
      ..setPhone('13800138000');
    expect(await _ctrl(c).sendCode(), isTrue);
    expect(repo.calls, contains('sendCode:reset_password'));
    _ctrl(c)
      ..setCode('123456')
      ..setPassword('Reset1234')
      ..setConfirm('Reset1234');
    expect(await _ctrl(c).submit(), isNotNull);
    expect(repo.calls, contains('resetPassword'));
    expect(c.read(isSignedInProvider), isTrue);
  });

  test('wrong code (400) shows the server detail and stays signed out', () async {
    final (c, repo) = await _setup();
    repo.failWith = const ApiException(
      kind: ApiErrorKind.badRequest,
      statusCode: 400,
      message: '验证码错误，还可尝试 4 次',
    );
    _ctrl(c)
      ..setMethod(LoginMethod.code)
      ..setPhone('13800138000')
      ..setCode('000000');
    expect(await _ctrl(c).submit(), isNull);
    expect(_state(c).error?.message, '验证码错误，还可尝试 4 次');
    expect(c.read(isSignedInProvider), isFalse);
  });

  test('switching mode clears the code and passwords (codes are bound to their purpose)', () async {
    final (c, _) = await _setup();
    _ctrl(c)
      ..setPhone('13800138000')
      ..setCode('123456')
      ..setPassword('Pass1234')
      ..setMode(PhoneAuthMode.register);
    expect(_state(c).code, isEmpty);
    expect(_state(c).password, isEmpty);
    expect(_state(c).phone, '13800138000');
    expect(_state(c).mode, PhoneAuthMode.register);
  });
}
