import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api/models/auth_models.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/heartbeat/recording_status.dart';

part 'account_controller.g.dart';

/// Account actions of the settings page (rename, password, logout). State = the last action:
/// loading while it runs, error when it failed (the page shows it in a SnackBar).
@riverpod
class AccountController extends _$AccountController {
  @override
  FutureOr<void> build() {}

  /// `PATCH /auth/me`. Returns the updated user, or null on failure (error in state).
  Future<User?> rename(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    state = const AsyncLoading();
    try {
      final user = await ref.read(sessionControllerProvider.notifier).updateName(trimmed);
      if (ref.mounted) state = const AsyncData(null);
      return user;
    } on Object catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return null;
    }
  }

  /// `PUT /auth/me/password`: first password ([oldPassword] null) or change. Errors are
  /// rethrown for the password dialog (shown inline there, not as a page SnackBar).
  Future<User> changePassword({String? oldPassword, required String password}) async {
    state = const AsyncLoading();
    try {
      return await ref
          .read(sessionControllerProvider.notifier)
          .changePassword(oldPassword: oldPassword, password: password);
    } finally {
      if (ref.mounted) state = const AsyncData(null);
    }
  }

  /// Signs out. Refused (returns false) while a recording is running.
  Future<bool> logout() async {
    if (ref.read(recordingStatusControllerProvider).recording) return false;
    state = const AsyncLoading();
    await ref.read(sessionControllerProvider.notifier).logout();
    if (ref.mounted) state = const AsyncData(null);
    return true;
  }
}
