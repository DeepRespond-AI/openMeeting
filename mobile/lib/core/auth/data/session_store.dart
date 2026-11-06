import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../api/models/auth_models.dart';

part 'session_store.g.dart';

/// A persisted login: token + cached user + the server it belongs to.
class StoredSession {
  const StoredSession({required this.token, required this.user, required this.serverUrl});

  final String token;
  final User user;

  /// Base URL the token was issued by. A different current URL invalidates the session.
  final String serverUrl;
}

/// Secure persistence of the session token, cached user and the per-install client id.
///
/// The token is cached in memory after [read]/[save] so the auth interceptor can attach
/// it without hitting the keychain on every request.
class SessionStore {
  SessionStore(this._storage, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  // Storage keys (internal, not tunables).
  static const _kToken = 'session.token';
  static const _kUser = 'session.user';
  static const _kServerUrl = 'session.serverUrl';
  static const _kClientId = 'client.id';

  bool _loaded = false;
  String? _token;
  String? _clientId;

  /// The in-memory token (null before [read] or when signed out).
  String? get cachedToken => _token;

  /// The current token, loading it from secure storage on first use.
  Future<String?> currentToken() async {
    if (!_loaded) await read();
    return _token;
  }

  Future<StoredSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _kToken),
      _storage.read(key: _kUser),
      _storage.read(key: _kServerUrl),
    ]);
    _loaded = true;
    final [token, userJson, serverUrl] = values;
    if (token == null || token.isEmpty || userJson == null || serverUrl == null) {
      _token = null;
      return null;
    }
    try {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _token = token;
      return StoredSession(token: token, user: user, serverUrl: serverUrl);
    } on Object {
      // Corrupt entry (e.g. model change) — treat as signed out.
      await clear();
      return null;
    }
  }

  Future<void> save(StoredSession session) async {
    _token = session.token;
    _loaded = true;
    await Future.wait([
      _storage.write(key: _kToken, value: session.token),
      _storage.write(key: _kUser, value: jsonEncode(session.user.toJson())),
      _storage.write(key: _kServerUrl, value: session.serverUrl),
    ]);
  }

  /// Updates only the cached user (after `/auth/me`).
  Future<void> saveUser(User user) => _storage.write(key: _kUser, value: jsonEncode(user.toJson()));

  Future<void> clear() async {
    _token = null;
    _loaded = true;
    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kUser),
      _storage.delete(key: _kServerUrl),
    ]);
  }

  /// Stable per-install client id (uuid v4), generated on first use. Survives logout.
  Future<String> clientId() async {
    final cached = _clientId;
    if (cached != null) return cached;
    var id = await _storage.read(key: _kClientId);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await _storage.write(key: _kClientId, value: id);
    }
    return _clientId = id;
  }
}

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) => const FlutterSecureStorage();

@Riverpod(keepAlive: true)
SessionStore sessionStore(Ref ref) => SessionStore(ref.watch(secureStorageProvider));
