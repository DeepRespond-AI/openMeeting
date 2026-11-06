import 'package:meeting/core/api/api_exception.dart';
import 'package:meeting/core/api/models/auth_models.dart';
import 'package:meeting/core/auth/domain/auth_repository.dart';

const testUser = User(id: 'u1', phone: '13800138000', name: '张三');

/// In-memory [AuthRepository] recording calls.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user = testUser, this.token = 'ms_test_token'});

  User user;
  final String token;
  final List<String> calls = [];
  String? lastPhone;
  String? loggedOutToken;

  /// Last password sent with login / register / reset / change.
  String? lastPassword;

  /// Last `old_password` sent with a password change.
  String? lastOldPassword;

  /// When set, login/register throw it.
  ApiException? failWith;

  @override
  Future<AuthConfig> fetchAuthConfig({String? serverUrl}) async {
    calls.add('config');
    return const AuthConfig(
      registrationOpen: true,
      smsReady: true,
      codeLength: 6,
      resendIntervalSec: 60,
      serverVersion: 'test',
    );
  }

  @override
  Future<SendCodeResult> sendCode({required String phone, required AuthPurpose purpose}) async {
    calls.add('sendCode:${purpose.wire}');
    lastPhone = phone;
    return const SendCodeResult(
      sent: true,
      resendAfterSec: 60,
      expiresInSec: 300,
      devCode: '123456',
    );
  }

  @override
  Future<AuthResult> login({required String phone, required String code}) async {
    calls.add('login');
    lastPhone = phone;
    if (failWith case final e?) throw e;
    return AuthResult(token: token, user: user);
  }

  @override
  Future<AuthResult> loginWithPassword({required String phone, required String password}) async {
    calls.add('loginWithPassword');
    lastPhone = phone;
    lastPassword = password;
    if (failWith case final e?) throw e;
    return AuthResult(token: token, user: user);
  }

  @override
  Future<AuthResult> register({
    required String phone,
    required String code,
    required String name,
    required String password,
  }) async {
    calls.add('register');
    lastPhone = phone;
    lastPassword = password;
    if (failWith case final e?) throw e;
    user = user.copyWith(name: name, hasPassword: true);
    return AuthResult(token: token, user: user);
  }

  @override
  Future<AuthResult> resetPassword({
    required String phone,
    required String code,
    required String password,
  }) async {
    calls.add('resetPassword');
    lastPhone = phone;
    lastPassword = password;
    if (failWith case final e?) throw e;
    user = user.copyWith(hasPassword: true);
    return AuthResult(token: token, user: user);
  }

  @override
  Future<void> logout({required String token}) async {
    calls.add('logout');
    loggedOutToken = token;
  }

  @override
  Future<User> me() async {
    calls.add('me');
    return user;
  }

  @override
  Future<User> updateName(String name) async {
    calls.add('updateName');
    return user = user.copyWith(name: name);
  }

  @override
  Future<User> changePassword({String? oldPassword, required String password}) async {
    calls.add('changePassword');
    lastOldPassword = oldPassword;
    lastPassword = password;
    if (failWith case final e?) throw e;
    return user = user.copyWith(hasPassword: true);
  }
}
