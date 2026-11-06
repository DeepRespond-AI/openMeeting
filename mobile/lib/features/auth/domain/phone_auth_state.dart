import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/models/auth_models.dart';
import '../../../core/utils/password.dart';
import '../../../core/utils/phone.dart';

part 'phone_auth_state.freezed.dart';

/// Flow of the phone auth form ([reset] = "forgot password"). Maps to the `purpose` of
/// `POST /auth/sms/send`.
enum PhoneAuthMode {
  login(AuthPurpose.login),
  register(AuthPurpose.register),
  reset(AuthPurpose.resetPassword);

  const PhoneAuthMode(this.purpose);

  final AuthPurpose purpose;

  /// Registration and reset choose a new password (rules + confirmation).
  bool get choosesPassword => this != login;
}

/// How [PhoneAuthMode.login] authenticates.
enum LoginMethod { password, code }

/// Client-side validation problems (shown under the matching field).
enum PhoneAuthIssue {
  phoneInvalid,
  codeInvalid,
  nameRequired,
  nameTooLong,
  passwordRequired,
  passwordLength,
  passwordSpaces,
  passwordLetterDigit,
  passwordMismatch,
}

/// Issue for a password rule violation.
PhoneAuthIssue issueOf(PasswordProblem problem) => switch (problem) {
  PasswordProblem.length => PhoneAuthIssue.passwordLength,
  PasswordProblem.spaces => PhoneAuthIssue.passwordSpaces,
  PasswordProblem.letterDigit => PhoneAuthIssue.passwordLetterDigit,
};

/// Issues that belong to the password field.
const Set<PhoneAuthIssue> passwordIssues = {
  PhoneAuthIssue.passwordRequired,
  PhoneAuthIssue.passwordLength,
  PhoneAuthIssue.passwordSpaces,
  PhoneAuthIssue.passwordLetterDigit,
};

/// State of [PhoneAuthController] (the reusable phone login/registration form).
@freezed
abstract class PhoneAuthState with _$PhoneAuthState {
  const factory PhoneAuthState({
    @Default(PhoneAuthMode.login) PhoneAuthMode mode,
    @Default(LoginMethod.password) LoginMethod method,
    @Default('') String phone,
    @Default('') String code,
    @Default('') String name,
    @Default('') String password,

    /// Repeated new password (register / reset).
    @Default('') String confirm,

    /// `POST /auth/sms/send` in flight.
    @Default(false) bool sending,

    /// Seconds until a new code may be requested (0 = may send).
    @Default(0) int countdown,

    /// A code was sent for the current mode/phone.
    @Default(false) bool codeSent,

    /// Login/register request in flight.
    @Default(false) bool submitting,
    @Default(<PhoneAuthIssue>{}) Set<PhoneAuthIssue> issues,

    /// Last server/network error (shown via `describeError`, server `detail` verbatim).
    ApiException? error,

    /// `dev_code` of the last send response; only kept when `AppConfig.features.showDevCode`.
    String? devCode,
  }) = _PhoneAuthState;

  const PhoneAuthState._();

  bool get busy => sending || submitting;

  bool get canSendCode => countdown == 0 && !busy;

  /// The current flow needs an SMS code.
  bool get needsCode => mode != PhoneAuthMode.login || method == LoginMethod.code;

  /// The current flow needs a password.
  bool get needsPassword => mode != PhoneAuthMode.login || method == LoginMethod.password;
}

/// Pure validation rules of the phone auth form.
class PhoneAuthValidator {
  const PhoneAuthValidator({
    required this.phoneRules,
    required this.codeLength,
    required this.nameMaxLength,
    required this.passwordRules,
  });

  final PhoneRules phoneRules;

  /// From `GET /auth/config` (`AppConfig.auth.defaultCodeLength` until it loaded).
  final int codeLength;

  /// `AppConfig.auth.nameMaxLength`.
  final int nameMaxLength;

  final PasswordRules passwordRules;

  static final RegExp _digits = RegExp(r'^\d+$');

  /// Problems preventing `sms/send`.
  Set<PhoneAuthIssue> forSendCode(PhoneAuthState s) => {
    if (!phoneRules.isValid(s.phone)) PhoneAuthIssue.phoneInvalid,
  };

  /// Problems preventing login / register / reset.
  Set<PhoneAuthIssue> forSubmit(PhoneAuthState s) {
    final code = s.code.trim();
    final name = s.name.trim();
    final passwordProblem = s.mode.choosesPassword ? passwordRules.check(s.password) : null;
    return {
      ...forSendCode(s),
      if (s.needsCode && (code.length != codeLength || !_digits.hasMatch(code)))
        PhoneAuthIssue.codeInvalid,
      if (s.mode == PhoneAuthMode.register && name.isEmpty) PhoneAuthIssue.nameRequired,
      if (s.mode == PhoneAuthMode.register && name.runes.length > nameMaxLength)
        PhoneAuthIssue.nameTooLong,
      if (s.needsPassword && s.password.isEmpty)
        PhoneAuthIssue.passwordRequired
      else if (passwordProblem != null)
        issueOf(passwordProblem),
      if (s.mode.choosesPassword && s.password.isNotEmpty && s.confirm != s.password)
        PhoneAuthIssue.passwordMismatch,
    };
  }
}
