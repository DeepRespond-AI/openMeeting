import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_exception_l10n.dart';
import '../../../../core/api/models/auth_models.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../core/config/app_config_provider.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../../core/utils/password.dart';
import '../../../../core/widgets/password_field.dart';
import '../../../../core/widgets/text_limit.dart';
import '../phone_auth_controller.dart';
import 'notice_banner.dart';

/// Reusable phone auth form (login page and onboarding): sign in with the password or an SMS
/// code, sign up (code + name + password), or reset a forgotten password.
///
/// Signing in updates the global session; the caller reacts to that (router redirect or
/// onboarding step). [onSignedIn] is an optional extra hook.
class PhoneAuthForm extends ConsumerStatefulWidget {
  const PhoneAuthForm({super.key, this.onSignedIn});

  final ValueChanged<User>? onSignedIn;

  @override
  ConsumerState<PhoneAuthForm> createState() => _PhoneAuthFormState();
}

class _PhoneAuthFormState extends ConsumerState<PhoneAuthForm> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = ref.read(phoneAuthControllerProvider);
    _phone.text = s.phone;
    _code.text = s.code;
    _name.text = s.name;
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  PhoneAuthController get _controller => ref.read(phoneAuthControllerProvider.notifier);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final user = await _controller.submit();
    if (user != null) widget.onSignedIn?.call(user);
  }

  void _fillDevCode(String code) {
    _code.text = code;
    _controller.setCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(phoneAuthControllerProvider);
    final authConfig = ref.watch(authConfigProvider);
    final codeLength = ref.watch(authCodeLengthProvider);
    final nameMaxLength = ref.watch(appConfigProvider.select((c) => c.auth.nameMaxLength));

    final passwordRules = ref.watch(passwordRulesProvider);

    // Flow switches clear the code and passwords; keep the text fields in sync.
    void clearSecrets() {
      _code.clear();
      _password.clear();
      _confirm.clear();
    }

    ref.listen(
      phoneAuthControllerProvider.select((s) => (s.mode, s.method)),
      (_, _) => clearSecrets(),
    );
    ref.listen(phoneAuthControllerProvider.select((s) => s.password), (_, next) {
      if (next.isEmpty && _password.text.isNotEmpty) clearSecrets();
    });

    final config = authConfig.value;
    final registerClosed =
        state.mode == PhoneAuthMode.register && config != null && !config.registrationOpen;
    final enabled = !state.busy && !registerClosed;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.mode == PhoneAuthMode.reset) ...[
            Text(l10n.authResetTitle, style: context.textTheme.titleMedium),
            SizedBox(height: context.spacing.xxs),
            Text(
              l10n.authResetHint,
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.mutedForeground),
            ),
          ] else ...[
            SegmentedButton<PhoneAuthMode>(
              segments: [
                ButtonSegment(value: PhoneAuthMode.login, label: Text(l10n.authTabLogin)),
                ButtonSegment(value: PhoneAuthMode.register, label: Text(l10n.authTabRegister)),
              ],
              selected: {state.mode},
              showSelectedIcon: false,
              onSelectionChanged: state.busy ? null : (s) => _controller.setMode(s.first),
            ),
            if (state.mode == PhoneAuthMode.login) ...[
              context.spacing.gapSm,
              Row(
                children: [
                  for (final method in LoginMethod.values)
                    TextButton(
                      onPressed: state.busy ? null : () => _controller.setMethod(method),
                      style: TextButton.styleFrom(
                        foregroundColor: state.method == method
                            ? context.colors.primary
                            : context.colors.mutedForeground,
                        textStyle: state.method == method
                            ? context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)
                            : context.textTheme.labelLarge,
                      ),
                      child: Text(switch (method) {
                        LoginMethod.password => l10n.authMethodPassword,
                        LoginMethod.code => l10n.authMethodCode,
                      }),
                    ),
                ],
              ),
            ],
          ],
          context.spacing.gapMd,
          if (authConfig.hasError && config == null) ...[
            NoticeBanner.error(
              message: l10n.authConfigLoadFailed(describeError(authConfig.error!, l10n)),
              actionLabel: l10n.commonRetry,
              onAction: () => ref.invalidate(authConfigProvider),
            ),
            context.spacing.gapMd,
          ],
          if (registerClosed) ...[
            NoticeBanner.warning(message: l10n.authRegistrationClosed),
            context.spacing.gapMd,
          ],
          if (state.needsCode && config != null && !config.smsReady) ...[
            NoticeBanner.warning(message: l10n.authSmsNotReady),
            context.spacing.gapMd,
          ],
          TextField(
            controller: _phone,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumberNational],
            onChanged: _controller.setPhone,
            decoration: InputDecoration(
              labelText: l10n.authPhoneLabel,
              hintText: l10n.authPhoneHint,
              prefixText: l10n.authPhonePrefix,
              errorText: state.issues.contains(PhoneAuthIssue.phoneInvalid)
                  ? l10n.authPhoneInvalid
                  : null,
            ),
          ),
          if (state.needsCode) ...[
            context.spacing.gapMd,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textInputAction: state.needsPassword || state.mode == PhoneAuthMode.register
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: codeLength,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: _controller.setCode,
                    onSubmitted: state.needsPassword || state.mode == PhoneAuthMode.register
                        ? null
                        : (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.authCodeLabel,
                      hintText: l10n.authCodeHint(codeLength),
                      counterText: '',
                      errorText: state.issues.contains(PhoneAuthIssue.codeInvalid)
                          ? l10n.authCodeInvalid(codeLength)
                          : null,
                    ),
                  ),
                ),
                context.spacing.gapSm,
                SizedBox(
                  height: context.sizes.buttonHeight,
                  child: OutlinedButton(
                    onPressed: enabled && state.canSendCode ? _controller.sendCode : null,
                    child: Text(_sendLabel(l10n, state)),
                  ),
                ),
              ],
            ),
            if (state.devCode case final devCode?) ...[
              context.spacing.gapXs,
              InkWell(
                onTap: () => _fillDevCode(devCode),
                borderRadius: context.radius.smAll,
                child: Padding(
                  padding: EdgeInsets.all(context.spacing.xxs),
                  child: Text(
                    l10n.authDevCodeHint(devCode),
                    style: context.textTheme.bodySmall?.copyWith(color: context.colors.primary),
                  ),
                ),
              ),
            ] else if (state.codeSent && state.countdown > 0) ...[
              context.spacing.gapXs,
              Text(
                l10n.authCodeSent,
                style: context.textTheme.bodySmall?.copyWith(color: context.colors.success),
              ),
            ],
          ],
          if (state.mode == PhoneAuthMode.register) ...[
            context.spacing.gapMd,
            TextField(
              controller: _name,
              enabled: enabled,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              maxLength: nameMaxLength,
              maxLengthEnforcement: MaxLengthEnforcement.none,
              inputFormatters: [CodePointLengthFormatter(nameMaxLength)],
              buildCounter: codePointCounter(_name, nameMaxLength),
              onChanged: _controller.setName,
              decoration: InputDecoration(
                labelText: l10n.authNameLabel,
                hintText: l10n.authNameHint,
                errorText: switch (state.issues) {
                  final i when i.contains(PhoneAuthIssue.nameRequired) => l10n.authNameRequired,
                  final i when i.contains(PhoneAuthIssue.nameTooLong) => l10n.authNameTooLong(
                    nameMaxLength,
                  ),
                  _ => null,
                },
              ),
            ),
          ],
          if (state.needsPassword) ...[
            context.spacing.gapMd,
            PasswordField(
              controller: _password,
              enabled: enabled,
              newPassword: state.mode.choosesPassword,
              maxLength: passwordRules.maxLength,
              label: state.mode == PhoneAuthMode.reset
                  ? l10n.authNewPasswordLabel
                  : l10n.authPasswordLabel,
              hint: state.mode.choosesPassword
                  ? l10n.authPasswordHint(passwordRules.minLength, passwordRules.maxLength)
                  : null,
              errorText: _passwordError(l10n, state.issues, passwordRules),
              textInputAction: state.mode.choosesPassword
                  ? TextInputAction.next
                  : TextInputAction.done,
              onChanged: _controller.setPassword,
              onSubmitted: state.mode.choosesPassword ? null : (_) => _submit(),
            ),
            if (state.mode == PhoneAuthMode.login)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: state.busy ? null : () => _controller.setMode(PhoneAuthMode.reset),
                  child: Text(l10n.authForgotPassword),
                ),
              ),
          ],
          if (state.mode.choosesPassword) ...[
            context.spacing.gapMd,
            PasswordField(
              controller: _confirm,
              enabled: enabled,
              newPassword: true,
              maxLength: passwordRules.maxLength,
              label: l10n.authConfirmPasswordLabel,
              hint: l10n.authConfirmPasswordHint,
              errorText: state.issues.contains(PhoneAuthIssue.passwordMismatch)
                  ? l10n.authPasswordMismatch
                  : null,
              textInputAction: TextInputAction.done,
              onChanged: _controller.setConfirm,
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (state.error case final error?) ...[
            context.spacing.gapSm,
            Text(
              error.describe(l10n),
              style: context.textTheme.bodySmall?.copyWith(color: context.colors.destructive),
            ),
          ],
          context.spacing.gapLg,
          SizedBox(
            height: context.sizes.buttonHeight,
            child: FilledButton(
              onPressed: enabled ? _submit : null,
              child: state.submitting
                  ? SizedBox.square(
                      dimension: context.sizes.iconMd,
                      child: CircularProgressIndicator(color: context.colors.onPrimary),
                    )
                  : Text(switch (state.mode) {
                      PhoneAuthMode.login => l10n.authLoginButton,
                      PhoneAuthMode.register => l10n.authRegisterButton,
                      PhoneAuthMode.reset => l10n.authResetButton,
                    }),
            ),
          ),
          if (state.mode == PhoneAuthMode.reset)
            TextButton(
              onPressed: state.busy ? null : () => _controller.setMode(PhoneAuthMode.login),
              child: Text(l10n.authBackToLogin),
            ),
        ],
      ),
    );
  }

  static String? _passwordError(
    AppLocalizations l10n,
    Set<PhoneAuthIssue> issues,
    PasswordRules rules,
  ) {
    if (issues.contains(PhoneAuthIssue.passwordRequired)) return l10n.authPasswordRequired;
    if (issues.contains(PhoneAuthIssue.passwordLength)) {
      return l10n.authPasswordLength(rules.minLength, rules.maxLength);
    }
    if (issues.contains(PhoneAuthIssue.passwordSpaces)) return l10n.authPasswordSpaces;
    if (issues.contains(PhoneAuthIssue.passwordLetterDigit)) return l10n.authPasswordLetterDigit;
    return null;
  }

  String _sendLabel(AppLocalizations l10n, PhoneAuthState state) {
    if (state.sending) return l10n.authSending;
    if (state.countdown > 0) return l10n.authResendIn(state.countdown);
    return state.codeSent ? l10n.authResendCode : l10n.authSendCode;
  }
}
