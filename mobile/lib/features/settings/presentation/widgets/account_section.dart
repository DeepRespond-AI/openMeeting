import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception_l10n.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config_provider.dart';
import '../../../../core/im/avatar_controller.dart';
import '../../../../core/im/widgets/user_identity.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/utils/password.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/text_limit.dart';
import '../account_controller.dart';
import '../settings_providers.dart';
import 'settings_section.dart';

/// 账号: editable IM avatar and name, masked phone, login password (set / change),
/// logout (disabled while recording).
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final phone = ref.watch(maskedPhoneProvider);
    final locked = ref.watch(settingsLockedProvider);
    final avatar = ref.watch(avatarControllerProvider);
    final busy = ref.watch(accountControllerProvider).isLoading || avatar.busy;
    if (user == null) return const SizedBox.shrink();

    final maxMegabytes = (ref.watch(appConfigProvider).live.avatarMaxBytes / (1024 * 1024)).floor();
    return SettingsSection(
      title: l10n.settingsAccountSection,
      children: [
        ListTile(
          leading: InkWell(
            onTap: busy ? null : () => ref.read(avatarControllerProvider.notifier).pickAndSave(),
            child: ImUserAvatar(username: user.id, fallbackName: user.name),
          ),
          title: Text(user.name),
          subtitle: phone == null ? null : Text(phone),
          trailing: IconButton(
            tooltip: l10n.settingsEditName,
            onPressed: busy ? null : () => _rename(context, ref, user.name),
            icon: const Icon(Icons.edit_outlined),
          ),
        ),
        ListTile(
          key: const ValueKey('change-avatar'),
          enabled: !busy,
          leading: const Icon(Icons.add_a_photo_outlined),
          title: Text(switch (avatar.phase) {
            AvatarPhase.picking => l10n.settingsAvatarPicking,
            AvatarPhase.uploading => l10n.settingsAvatarUploading,
            AvatarPhase.saving => l10n.settingsAvatarSaving,
            AvatarPhase.saved => l10n.settingsAvatarSaved,
            AvatarPhase.idle => l10n.settingsChangeAvatar,
          }),
          subtitle: Text(
            avatar.failure == null
                ? l10n.settingsAvatarHint(maxMegabytes)
                : switch (avatar.failure!) {
                    AvatarFailure.type => l10n.settingsAvatarType,
                    AvatarFailure.size => l10n.settingsAvatarSize(maxMegabytes),
                    AvatarFailure.pick => l10n.settingsAvatarPickFailed,
                    AvatarFailure.upload => l10n.settingsAvatarUploadFailed,
                    AvatarFailure.save => l10n.settingsAvatarSaveFailed,
                  },
            style: avatar.failure == null ? null : TextStyle(color: context.colors.destructive),
          ),
          trailing: avatar.busy
              ? SizedBox.square(
                  dimension: context.sizes.iconLg,
                  child: CircularProgressIndicator(
                    value: avatar.phase == AvatarPhase.uploading ? avatar.progress : null,
                  ),
                )
              : const Icon(Icons.chevron_right),
          onTap: () => ref.read(avatarControllerProvider.notifier).pickAndSave(),
        ),
        ListTile(
          enabled: !busy,
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.settingsPassword),
          subtitle: Text(
            user.hasPassword ? l10n.settingsPasswordIsSet : l10n.settingsPasswordNotSet,
          ),
          trailing: Text(
            user.hasPassword ? l10n.settingsChangePassword : l10n.settingsSetPassword,
            style: context.textTheme.labelLarge?.copyWith(color: context.colors.primary),
          ),
          onTap: () => _password(context, ref, hasPassword: user.hasPassword),
        ),
        ListTile(
          enabled: !locked && !busy,
          leading: Icon(Icons.logout, color: locked ? null : context.colors.destructive),
          title: Text(
            l10n.settingsLogout,
            style: TextStyle(color: locked ? null : context.colors.destructive),
          ),
          subtitle: locked ? Text(l10n.settingsLockedWhileRecording) : null,
          onTap: () => _logout(context, ref),
        ),
      ],
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, String current) async {
    final maxLength = ref.read(appConfigProvider).auth.nameMaxLength;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current, maxLength: maxLength),
    );
    if (name == null || name.trim() == current) return;
    await ref.read(accountControllerProvider.notifier).rename(name);
  }

  Future<void> _password(BuildContext context, WidgetRef ref, {required bool hasPassword}) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final duration = ref.read(appConfigProvider).ui.snackBarDuration;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PasswordDialog(hasPassword: hasPassword),
    );
    if (saved ?? false) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(hasPassword ? l10n.settingsPasswordChanged : l10n.settingsPasswordSaved),
          duration: duration,
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsLogoutConfirmTitle),
        content: Text(l10n.settingsLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: dialogContext.colors.destructive),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsLogout),
          ),
        ],
      ),
    );
    if (ok ?? false) await ref.read(accountControllerProvider.notifier).logout();
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial, required this.maxLength});

  final String initial;
  final int maxLength;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (_text.text.trim().isEmpty || _text.text.trim().runes.length > widget.maxLength) return;
    Navigator.of(context).pop(_text.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.settingsEditName),
      content: ValueListenableBuilder(
        valueListenable: _text,
        builder: (context, value, _) => TextField(
          controller: _text,
          autofocus: true,
          maxLength: widget.maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.none,
          inputFormatters: [CodePointLengthFormatter(widget.maxLength)],
          buildCounter: codePointCounter(_text, widget.maxLength),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l10n.authNameLabel,
            errorText: value.text.trim().isEmpty
                ? l10n.authNameRequired
                : value.text.trim().runes.length > widget.maxLength
                ? l10n.authNameTooLong(widget.maxLength)
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l10n.commonSave)),
      ],
    );
  }
}

/// Set (first time) or change the login password; pops `true` once saved.
class _PasswordDialog extends ConsumerStatefulWidget {
  const _PasswordDialog({required this.hasPassword});

  final bool hasPassword;

  @override
  ConsumerState<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<_PasswordDialog> {
  final _old = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _oldError;
  String? _passwordError;
  String? _confirmError;
  String? _serverError;
  bool _saving = false;

  @override
  void dispose() {
    _old.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = context.l10n;
    final rules = ref.read(passwordRulesProvider);
    final problem = rules.check(_password.text);
    setState(() {
      _serverError = null;
      _oldError = widget.hasPassword && _old.text.isEmpty ? l10n.settingsOldPasswordRequired : null;
      _passwordError = switch (problem) {
        PasswordProblem.length => l10n.authPasswordLength(rules.minLength, rules.maxLength),
        PasswordProblem.spaces => l10n.authPasswordSpaces,
        PasswordProblem.letterDigit => l10n.authPasswordLetterDigit,
        null => null,
      };
      _confirmError = problem == null && _confirm.text != _password.text
          ? l10n.authPasswordMismatch
          : null;
    });
    if (_oldError != null || _passwordError != null || _confirmError != null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(accountControllerProvider.notifier)
          .changePassword(
            oldPassword: widget.hasPassword ? _old.text : null,
            password: _password.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = l10n.settingsPasswordFailed(describeError(e, l10n));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rules = ref.watch(passwordRulesProvider);
    return AlertDialog(
      title: Text(widget.hasPassword ? l10n.settingsChangePassword : l10n.settingsSetPassword),
      content: SingleChildScrollView(
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.hasPassword ? l10n.settingsChangePasswordHint : l10n.settingsSetPasswordHint,
                style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
              ),
              if (widget.hasPassword) ...[
                context.spacing.gapMd,
                PasswordField(
                  controller: _old,
                  enabled: !_saving,
                  autofocus: true,
                  maxLength: rules.maxLength,
                  label: l10n.settingsOldPassword,
                  errorText: _oldError,
                  textInputAction: TextInputAction.next,
                ),
              ],
              context.spacing.gapMd,
              PasswordField(
                controller: _password,
                enabled: !_saving,
                autofocus: !widget.hasPassword,
                newPassword: true,
                maxLength: rules.maxLength,
                label: l10n.authNewPasswordLabel,
                hint: l10n.authPasswordHint(rules.minLength, rules.maxLength),
                errorText: _passwordError,
                textInputAction: TextInputAction.next,
              ),
              context.spacing.gapMd,
              PasswordField(
                controller: _confirm,
                enabled: !_saving,
                newPassword: true,
                maxLength: rules.maxLength,
                label: l10n.authConfirmPasswordLabel,
                hint: l10n.authConfirmPasswordHint,
                errorText: _confirmError,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
              ),
              if (_serverError case final error?) ...[
                context.spacing.gapSm,
                Text(
                  error,
                  style: context.textTheme.bodySmall?.copyWith(color: context.colors.destructive),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.commonSave)),
      ],
    );
  }
}
