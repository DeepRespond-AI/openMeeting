import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/session_controller.dart';
import '../../../../core/theme/context_extensions.dart';
import '../../../auth/presentation/widgets/phone_auth_form.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

/// Step 3: phone sign-in / registration. Moves on automatically after signing in.
class AccountStep extends ConsumerWidget {
  const AccountStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    return StepScaffold(
      leading: const StepIcon(Icons.person_outline),
      title: l10n.onboardingAccountTitle,
      description: l10n.onboardingAccountBody,
      child: user == null
          ? PhoneAuthForm(onSignedIn: (_) => ref.read(onboardingControllerProvider.notifier).next())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.check_circle, color: context.colors.success),
                  title: Text(l10n.onboardingSignedInAs(user.name)),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
                    child: Text(l10n.onboardingSwitchAccount),
                  ),
                ),
              ],
            ),
    );
  }
}
