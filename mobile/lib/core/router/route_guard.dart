import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import 'app_routes.dart';

/// Session status as seen by the router.
enum SessionStatus { loading, unconfigured, signedOut, signedIn, expired }

SessionStatus sessionStatusOf(AsyncValue<AuthState> session) => switch (session.value) {
  null => session.hasError ? SessionStatus.signedOut : SessionStatus.loading,
  AuthUnconfigured() => SessionStatus.unconfigured,
  AuthSignedOut() => SessionStatus.signedOut,
  AuthSignedIn() => SessionStatus.signedIn,
  AuthExpired() => SessionStatus.expired,
};

bool _isAt(String location, String route) => location == route || location.startsWith('$route/');

/// Pure redirect rule used by go_router (unit-tested in `test/core/router/route_guard_test.dart`).
///
/// 0. A forced update is pending ([updateRequired]) → /update, before anything else (also
///    blocks the login screen). Leaving it again follows the rules below.
/// 1. Session still loading → splash.
/// 2. Onboarding not completed → /onboarding (onboarding handles server URL + login itself,
///    so /login is also allowed).
/// 3. Onboarding completed but not signed in (unconfigured / signedOut / expired) → /login.
/// 4. Signed in on splash / login / onboarding → /meetings.
///
/// Returns `null` to stay on [location].
String? guardRedirect({
  required String location,
  required SessionStatus session,
  required bool onboardingCompleted,
  bool updateRequired = false,
  bool roomEnded = false,
}) {
  final atForceUpdate = _isAt(location, AppRoutes.forceUpdate);
  if (updateRequired) return atForceUpdate ? null : AppRoutes.forceUpdate;

  final atSplash = location == AppRoutes.splash;
  final atOnboarding = _isAt(location, AppRoutes.onboarding);
  final atLogin = _isAt(location, AppRoutes.login);

  if (session == SessionStatus.loading) {
    return atSplash ? null : AppRoutes.splash;
  }
  if (atForceUpdate && !onboardingCompleted) return AppRoutes.onboarding;
  if (!onboardingCompleted) {
    return (atOnboarding || atLogin) ? null : AppRoutes.onboarding;
  }
  if (session != SessionStatus.signedIn) {
    return atLogin ? null : AppRoutes.login;
  }
  if (atSplash || atLogin || atOnboarding || atForceUpdate) return AppRoutes.meetings;
  if (roomEnded && _isAt(location, AppRoutes.liveRoom)) return AppRoutes.meetings;
  return null;
}
