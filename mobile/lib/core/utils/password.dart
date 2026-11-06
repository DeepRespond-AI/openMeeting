import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/session_controller.dart';
import '../config/app_config_provider.dart';

part 'password.g.dart';

/// Why a new password is rejected (mirrors the server rules, server/API.md §1.0).
enum PasswordProblem { length, spaces, letterDigit }

/// Password rules: length limits from `GET /auth/config` (else `AppConfig.auth` defaults);
/// letters + digits, no leading/trailing spaces. The server stays authoritative.
class PasswordRules {
  const PasswordRules({required this.minLength, required this.maxLength});

  final int minLength;
  final int maxLength;

  static final RegExp _letter = RegExp('[A-Za-z]');
  static final RegExp _digit = RegExp(r'\d');

  PasswordProblem? check(String password) {
    if (password.length < minLength || password.length > maxLength) return PasswordProblem.length;
    if (password != password.trim()) return PasswordProblem.spaces;
    if (!_letter.hasMatch(password) || !_digit.hasMatch(password)) {
      return PasswordProblem.letterDigit;
    }
    return null;
  }
}

@riverpod
PasswordRules passwordRules(Ref ref) {
  final server = ref.watch(authConfigProvider).value;
  final defaults = ref.watch(appConfigProvider).auth;
  return PasswordRules(
    minLength: server?.passwordMinLength ?? defaults.defaultPasswordMinLength,
    maxLength: server?.passwordMaxLength ?? defaults.defaultPasswordMaxLength,
  );
}
