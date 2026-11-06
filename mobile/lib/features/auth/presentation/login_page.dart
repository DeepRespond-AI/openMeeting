import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/session_controller.dart';
import '../../../core/config/settings_controller.dart';
import '../../../core/theme/context_extensions.dart';
import '../../../core/widgets/brand_logo.dart';
import 'widgets/notice_banner.dart';
import 'widgets/phone_auth_form.dart';

/// Sign-in page shown by the router when signed out / expired after onboarding.
/// Branded header and [PhoneAuthForm]. The server is fixed by the build and never shown.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider).value;
    final serverUrl = ref.watch(effectiveServerUrlProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.xl,
              vertical: context.spacing.xxl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrandLogo(height: context.sizes.logoLg, withTagline: true),
                  SizedBox(height: context.spacing.xxl),
                  if (session is AuthExpired) ...[
                    NoticeBanner.warning(message: l10n.authSessionExpired),
                    context.spacing.gapMd,
                  ],
                  if (serverUrl.isEmpty)
                    NoticeBanner(message: l10n.authServerRequired)
                  else
                    const PhoneAuthForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
