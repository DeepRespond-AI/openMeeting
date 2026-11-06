import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/models/auth_models.dart';
import '../config/settings_controller.dart';
import '../utils/phone.dart';
import 'auth_state.dart';
import 'data/auth_repository_impl.dart';
import 'data/session_store.dart';
import 'domain/auth_repository.dart';

export 'auth_state.dart';

part 'session_controller.g.dart';

/// The global session (DEVELOPMENT.md §2).
///
/// - `build` restores the stored session for the built-in server URL (a session issued by
///   another server, e.g. one entered in an older build, is discarded).
/// - Auth actions throw [ApiException] and leave the state untouched on failure; callers
///   (login page controllers) show the error.
/// - [expire] is called by the dio 401 interceptor; the router redirects to /login and
///   `App` shows the "session expired" SnackBar.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SessionStore get _store => ref.read(sessionStoreProvider);
  PhoneRules get _phone => ref.read(phoneRulesProvider);

  @override
  Future<AuthState> build() async {
    final serverUrl = ref.watch(effectiveServerUrlProvider);
    final store = ref.watch(sessionStoreProvider);
    if (serverUrl.isEmpty) return const AuthState.unconfigured();
    final stored = await store.read();
    if (stored == null) return const AuthState.signedOut();
    if (stored.serverUrl != serverUrl) {
      await store.clear();
      return const AuthState.signedOut();
    }
    return AuthState.signedIn(stored.user);
  }

  /// Fetches `GET /auth/config` of the configured server.
  Future<AuthConfig> fetchAuthConfig() => _repo.fetchAuthConfig();

  /// Sends an SMS code. [phone] may be un-normalized.
  Future<SendCodeResult> sendCode(String phone, AuthPurpose purpose) =>
      _repo.sendCode(phone: _phone.normalize(phone), purpose: purpose);

  Future<User> login(String phone, String code) async {
    final result = await _repo.login(phone: _phone.normalize(phone), code: code.trim());
    return _signIn(result);
  }

  /// Password login. Passwords are sent exactly as typed (never trimmed).
  Future<User> loginWithPassword(String phone, String password) async {
    final result = await _repo.loginWithPassword(
      phone: _phone.normalize(phone),
      password: password,
    );
    return _signIn(result);
  }

  Future<User> register(String phone, String code, String name, String password) async {
    final result = await _repo.register(
      phone: _phone.normalize(phone),
      code: code.trim(),
      name: name.trim(),
      password: password,
    );
    return _signIn(result);
  }

  /// Forgot password: sets a new password with an SMS code and signs in (the server signs
  /// out every other device).
  Future<User> resetPassword(String phone, String code, String password) async {
    final result = await _repo.resetPassword(
      phone: _phone.normalize(phone),
      code: code.trim(),
      password: password,
    );
    return _signIn(result);
  }

  Future<User> _signIn(AuthResult result) async {
    await _store.save(
      StoredSession(
        token: result.token,
        user: result.user,
        serverUrl: ref.read(effectiveServerUrlProvider),
      ),
    );
    state = AsyncData(AuthState.signedIn(result.user));
    return result.user;
  }

  /// Signs out locally right away, then revokes the token on the server (best effort).
  Future<void> logout() async {
    final token = _store.cachedToken;
    await _store.clear();
    state = AsyncData(_signedOutState());
    if (token != null) {
      try {
        await _repo.logout(token: token);
      } on Object {
        // Best effort: the local session is already gone.
      }
    }
  }

  /// Marks the session as expired (401 on an authenticated request). No-op unless signed in.
  Future<void> expire() async {
    if (state.value is! AuthSignedIn) return;
    state = const AsyncData(AuthState.expired());
    await _store.clear();
  }

  /// Re-reads the current user from the server (`GET /auth/me`).
  Future<User?> refreshMe() async {
    if (state.value is! AuthSignedIn) return null;
    final user = await _repo.me();
    return _replaceUser(user);
  }

  /// `PATCH /auth/me {"name"}`.
  Future<User> updateName(String name) async {
    final user = await _repo.updateName(name.trim());
    return _replaceUser(user);
  }

  /// `PUT /auth/me/password`: first password ([oldPassword] null) or change. The server
  /// signs out the user's other devices.
  Future<User> changePassword({String? oldPassword, required String password}) async {
    final user = await _repo.changePassword(oldPassword: oldPassword, password: password);
    return _replaceUser(user);
  }

  Future<User> _replaceUser(User user) async {
    if (state.value is AuthSignedIn) {
      state = AsyncData(AuthState.signedIn(user));
      await _store.saveUser(user);
    }
    return user;
  }

  AuthState _signedOutState() => ref.read(effectiveServerUrlProvider).isEmpty
      ? const AuthState.unconfigured()
      : const AuthState.signedOut();
}

/// True while a user is signed in (narrow provider for widgets/heartbeat).
@Riverpod(keepAlive: true)
bool isSignedIn(Ref ref) =>
    ref.watch(sessionControllerProvider.select((s) => s.value is AuthSignedIn));

/// The signed-in user or null.
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) => switch (ref.watch(sessionControllerProvider).value) {
  AuthSignedIn(:final user) => user,
  _ => null,
};

/// `GET /auth/config` of the configured server (server-provided auth parameters:
/// code length, resend interval, registration/SMS state). Auto-disposed; `ref.invalidate` to re-check.
@riverpod
Future<AuthConfig> authConfig(Ref ref) {
  ref.watch(effectiveServerUrlProvider);
  return ref.watch(authRepositoryProvider).fetchAuthConfig();
}
