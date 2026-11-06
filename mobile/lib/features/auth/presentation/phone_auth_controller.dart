import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/models/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/config/settings_controller.dart';
import '../../../core/utils/password.dart';
import '../../../core/utils/phone.dart';
import '../domain/phone_auth_state.dart';

export '../domain/phone_auth_state.dart';

part 'phone_auth_controller.g.dart';

/// One tick of the resend countdown.
const Duration _tick = Duration(seconds: 1);

/// SMS-code length to use: server value (`GET /auth/config`), else the app config default.
@riverpod
int authCodeLength(Ref ref) =>
    ref.watch(authConfigProvider).value?.codeLength ??
    ref.watch(appConfigProvider).auth.defaultCodeLength;

/// Validation rules for the phone auth form (phone pattern, code length, name length, password).
@riverpod
PhoneAuthValidator phoneAuthValidator(Ref ref) => PhoneAuthValidator(
  phoneRules: ref.watch(phoneRulesProvider),
  codeLength: ref.watch(authCodeLengthProvider),
  nameMaxLength: ref.watch(appConfigProvider).auth.nameMaxLength,
  passwordRules: ref.watch(passwordRulesProvider),
);

/// Drives [PhoneAuthForm]: login (password or SMS code) / register tabs, forgot-password
/// flow, SMS code with resend countdown, submit.
///
/// Signing in goes through [SessionController]; on success the session state changes and
/// the router (or the onboarding flow) moves on by itself.
@riverpod
class PhoneAuthController extends _$PhoneAuthController {
  Timer? _timer;

  @override
  PhoneAuthState build() {
    // A different server = a different user base: start over.
    ref.watch(effectiveServerUrlProvider);
    // Keep the server auth config loaded while the form exists (code length, resend interval).
    ref.listen(authConfigProvider, (_, _) {});
    ref.onDispose(() => _timer?.cancel());
    return const PhoneAuthState();
  }

  PhoneAuthValidator get _validator => ref.read(phoneAuthValidatorProvider);

  void setMode(PhoneAuthMode mode) {
    if (mode == state.mode || state.busy) return;
    // Codes are bound to their purpose: a code sent for login is useless for registration.
    state = _cleared().copyWith(mode: mode);
  }

  void setMethod(LoginMethod method) {
    if (method == state.method || state.busy) return;
    state = _cleared().copyWith(method: method);
  }

  /// Drops the code, passwords and messages (switching flows); keeps phone and name.
  PhoneAuthState _cleared() => state.copyWith(
    code: '',
    password: '',
    confirm: '',
    codeSent: false,
    devCode: null,
    error: null,
    issues: const {},
  );

  void setPassword(String value) => state = state.copyWith(
    password: value,
    error: null,
    issues: state.issues.difference({...passwordIssues, PhoneAuthIssue.passwordMismatch}),
  );

  void setConfirm(String value) => state = state.copyWith(
    confirm: value,
    error: null,
    issues: _without(PhoneAuthIssue.passwordMismatch),
  );

  void setPhone(String value) => state = state.copyWith(
    phone: value,
    error: null,
    issues: _without(PhoneAuthIssue.phoneInvalid),
  );

  void setCode(String value) => state = state.copyWith(
    code: value,
    error: null,
    issues: _without(PhoneAuthIssue.codeInvalid),
  );

  void setName(String value) => state = state.copyWith(
    name: value,
    error: null,
    issues: state.issues.difference(const {
      PhoneAuthIssue.nameRequired,
      PhoneAuthIssue.nameTooLong,
    }),
  );

  Set<PhoneAuthIssue> _without(PhoneAuthIssue issue) => state.issues.difference({issue});

  /// Requests an SMS code. Returns true when it was sent.
  Future<bool> sendCode() async {
    if (!state.canSendCode) return false;
    final issues = _validator.forSendCode(state);
    if (issues.isNotEmpty) {
      state = state.copyWith(issues: issues);
      return false;
    }
    state = state.copyWith(sending: true, error: null, issues: const {});
    try {
      final result = await ref
          .read(sessionControllerProvider.notifier)
          .sendCode(state.phone, state.mode.purpose);
      if (!ref.mounted) return false;
      final showDevCode = ref.read(appConfigProvider).features.showDevCode;
      state = state.copyWith(
        sending: false,
        codeSent: true,
        devCode: showDevCode ? result.devCode : null,
      );
      _startCountdown(_resendSeconds(result));
      return true;
    } on Object catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(sending: false, error: ApiException.from(e));
      return false;
    }
  }

  int _resendSeconds(SendCodeResult result) {
    if (result.resendAfterSec > 0) return result.resendAfterSec;
    return ref.read(authConfigProvider).value?.resendIntervalSec ??
        ref.read(appConfigProvider).auth.defaultResendIntervalSec;
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    state = state.copyWith(countdown: seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(_tick, (timer) {
      if (!ref.mounted) return timer.cancel();
      final next = state.countdown - 1;
      state = state.copyWith(countdown: next < 0 ? 0 : next);
      if (next <= 0) timer.cancel();
    });
  }

  /// Logs in (password or code), registers, or resets the password and signs in — by
  /// [PhoneAuthState.mode]. Returns the user on success, null when validation failed or the
  /// server refused (the error is in the state).
  Future<User?> submit() async {
    if (state.busy) return null;
    final issues = _validator.forSubmit(state);
    if (issues.isNotEmpty) {
      state = state.copyWith(issues: issues);
      return null;
    }
    state = state.copyWith(submitting: true, error: null, issues: const {});
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      final s = state;
      final user = switch (s.mode) {
        PhoneAuthMode.login => switch (s.method) {
          LoginMethod.password => await session.loginWithPassword(s.phone, s.password),
          LoginMethod.code => await session.login(s.phone, s.code),
        },
        PhoneAuthMode.register => await session.register(s.phone, s.code, s.name, s.password),
        PhoneAuthMode.reset => await session.resetPassword(s.phone, s.code, s.password),
      };
      if (ref.mounted) {
        _timer?.cancel();
        state = state.copyWith(
          submitting: false,
          countdown: 0,
          devCode: null,
          password: '',
          confirm: '',
        );
      }
      return user;
    } on Object catch (e) {
      if (ref.mounted) state = state.copyWith(submitting: false, error: ApiException.from(e));
      return null;
    }
  }
}
