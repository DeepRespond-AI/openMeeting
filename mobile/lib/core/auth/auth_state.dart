import 'package:freezed_annotation/freezed_annotation.dart';

import '../api/models/auth_models.dart';

part 'auth_state.freezed.dart';

/// Session state (DEVELOPMENT.md §2). Handle with an exhaustive `switch`:
///
/// ```dart
/// switch (authState) {
///   AuthUnconfigured() => ...,  // no server URL
///   AuthSignedOut() => ...,
///   AuthSignedIn(:final user) => ...,
///   AuthExpired() => ...,       // server rejected the session (401) — show login
/// }
/// ```
@freezed
sealed class AuthState with _$AuthState {
  /// No server URL configured.
  const factory AuthState.unconfigured() = AuthUnconfigured;

  const factory AuthState.signedOut() = AuthSignedOut;

  const factory AuthState.signedIn(User user) = AuthSignedIn;

  /// The server answered 401 for an authenticated request; the token was cleared.
  const factory AuthState.expired() = AuthExpired;
}
