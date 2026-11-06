import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meeting/core/auth/auth_state.dart';
import 'package:meeting/core/router/app_routes.dart';
import 'package:meeting/core/router/route_guard.dart';

import '../../helpers/fake_auth_repository.dart';

String? _go(
  String location,
  SessionStatus session, {
  bool onboarded = true,
  bool updateRequired = false,
}) => guardRedirect(
  location: location,
  session: session,
  onboardingCompleted: onboarded,
  updateRequired: updateRequired,
);

void main() {
  test('a forced update blocks every route, login included', () {
    for (final s in SessionStatus.values) {
      for (final location in [
        AppRoutes.meetings,
        AppRoutes.login,
        AppRoutes.splash,
        AppRoutes.settings,
      ]) {
        expect(_go(location, s, updateRequired: true), AppRoutes.forceUpdate);
        expect(_go(location, s, onboarded: false, updateRequired: true), AppRoutes.forceUpdate);
      }
      expect(_go(AppRoutes.forceUpdate, s, updateRequired: true), isNull);
    }
  });

  test('leaving the update page once nothing is required', () {
    expect(_go(AppRoutes.forceUpdate, SessionStatus.signedIn), AppRoutes.meetings);
    expect(_go(AppRoutes.forceUpdate, SessionStatus.signedOut), AppRoutes.login);
    expect(
      _go(AppRoutes.forceUpdate, SessionStatus.signedIn, onboarded: false),
      AppRoutes.onboarding,
    );
    expect(_go(AppRoutes.forceUpdate, SessionStatus.loading), AppRoutes.splash);
  });

  test('loading → splash', () {
    expect(_go(AppRoutes.meetings, SessionStatus.loading), AppRoutes.splash);
    expect(_go(AppRoutes.splash, SessionStatus.loading), isNull);
  });

  test('not onboarded → onboarding (login allowed)', () {
    for (final s in [SessionStatus.unconfigured, SessionStatus.signedOut, SessionStatus.signedIn]) {
      expect(_go(AppRoutes.meetings, s, onboarded: false), AppRoutes.onboarding);
      expect(_go(AppRoutes.splash, s, onboarded: false), AppRoutes.onboarding);
      expect(_go(AppRoutes.onboarding, s, onboarded: false), isNull);
      expect(_go(AppRoutes.login, s, onboarded: false), isNull);
    }
  });

  test('onboarded but unconfigured / signedOut / expired → login', () {
    for (final s in [SessionStatus.unconfigured, SessionStatus.signedOut, SessionStatus.expired]) {
      expect(_go(AppRoutes.meetings, s), AppRoutes.login);
      expect(_go(AppRoutes.meetingDetail('m1'), s), AppRoutes.login);
      expect(_go(AppRoutes.settings, s), AppRoutes.login);
      expect(_go(AppRoutes.splash, s), AppRoutes.login);
      expect(_go(AppRoutes.login, s), isNull);
      expect(_go(AppRoutes.onboarding, s), AppRoutes.login);
    }
  });

  test('signedIn on splash/login/onboarding → meetings; elsewhere stays', () {
    expect(_go(AppRoutes.splash, SessionStatus.signedIn), AppRoutes.meetings);
    expect(_go(AppRoutes.login, SessionStatus.signedIn), AppRoutes.meetings);
    expect(_go(AppRoutes.onboarding, SessionStatus.signedIn), AppRoutes.meetings);
    expect(_go(AppRoutes.meetings, SessionStatus.signedIn), isNull);
    expect(_go(AppRoutes.meetingDetail('m1'), SessionStatus.signedIn), isNull);
    expect(_go(AppRoutes.recording, SessionStatus.signedIn), isNull);
    expect(_go(AppRoutes.import, SessionStatus.signedIn), isNull);
    expect(_go(AppRoutes.settings, SessionStatus.signedIn), isNull);
  });

  test('sessionStatusOf maps AsyncValue<AuthState>', () {
    expect(sessionStatusOf(const AsyncLoading()), SessionStatus.loading);
    expect(
      sessionStatusOf(AsyncError<AuthState>(Exception(), StackTrace.empty)),
      SessionStatus.signedOut,
    );
    expect(sessionStatusOf(const AsyncData(AuthState.unconfigured())), SessionStatus.unconfigured);
    expect(sessionStatusOf(const AsyncData(AuthState.signedOut())), SessionStatus.signedOut);
    expect(sessionStatusOf(const AsyncData(AuthState.signedIn(testUser))), SessionStatus.signedIn);
    expect(sessionStatusOf(const AsyncData(AuthState.expired())), SessionStatus.expired);
  });

  test('meetingDetail encodes the id', () {
    expect(AppRoutes.meetingDetail('meeting-1'), '/meetings/meeting-1');
    expect(AppRoutes.meetingDetail('a/b'), '/meetings/a%2Fb');
  });
}
