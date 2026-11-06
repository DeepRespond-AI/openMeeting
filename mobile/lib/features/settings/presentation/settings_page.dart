import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception_l10n.dart';
import '../../../core/config/app_config_provider.dart';
import '../../../core/theme/context_extensions.dart';
import 'account_controller.dart';
import 'widgets/about_section.dart';
import 'widgets/account_section.dart';
import 'widgets/preferences_section.dart';

/// Settings: 账号 / 服务器 / 偏好 / 关于.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Account action failures (rename) → SnackBar.
    ref.listen(accountControllerProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(describeError(error, context.l10n)),
            duration: ref.read(appConfigProvider).ui.snackBarDuration,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navSettings)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
            child: ListView(
              padding: context.spacing.page,
              children: const [
                AccountSection(),
                PreferencesSection(),
                AboutSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
