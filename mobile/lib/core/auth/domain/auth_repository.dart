import '../../api/models/auth_models.dart';

/// Phone authentication (server/API.md §1.0). Implementations throw [ApiException].
///
/// Phone numbers passed in are already normalized (11 digits) by the caller.
abstract interface class AuthRepository {
  /// `GET /auth/config` of the configured server.
  Future<AuthConfig> fetchAuthConfig();

  Future<SendCodeResult> sendCode({required String phone, required AuthPurpose purpose});

  /// SMS-code login.
  Future<AuthResult> login({required String phone, required String code});

  Future<AuthResult> loginWithPassword({required String phone, required String password});

  Future<AuthResult> register({
    required String phone,
    required String code,
    required String name,
    required String password,
  });

  /// Forgot password: new [password] with a `reset_password` SMS [code]; signs in.
  Future<AuthResult> resetPassword({
    required String phone,
    required String code,
    required String password,
  });

  /// Revokes [token] on the server (best effort; callers ignore failures).
  Future<void> logout({required String token});

  Future<User> me();

  Future<User> updateName(String name);

  /// Sets the first password ([oldPassword] null) or changes it.
  Future<User> changePassword({String? oldPassword, required String password});
}
