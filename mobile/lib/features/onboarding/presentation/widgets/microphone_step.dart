import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/context_extensions.dart';
import '../onboarding_controller.dart';
import 'step_scaffold.dart';

/// Step 4: explains and requests the microphone permission (may be skipped).
class MicrophoneStep extends ConsumerStatefulWidget {
  const MicrophoneStep({super.key});

  @override
  ConsumerState<MicrophoneStep> createState() => _MicrophoneStepState();
}

class _MicrophoneStepState extends ConsumerState<MicrophoneStep> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back from the system settings: re-read the permission.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.read(microphonePermissionControllerProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = ref.watch(microphonePermissionControllerProvider);
    final controller = ref.read(microphonePermissionControllerProvider.notifier);

    final Widget action = switch (status.value) {
      null => const Center(child: CircularProgressIndicator()),
      MicPermission.granted => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.check_circle, color: context.colors.success),
        title: Text(l10n.onboardingMicGranted),
      ),
      MicPermission.denied => SizedBox(
        height: context.sizes.buttonHeight,
        child: OutlinedButton.icon(
          onPressed: controller.request,
          icon: const Icon(Icons.mic_none),
          label: Text(l10n.onboardingMicAllow),
        ),
      ),
      MicPermission.permanentlyDenied || MicPermission.restricted => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingMicDenied,
            style: context.textTheme.bodySmall?.copyWith(color: context.colors.warning),
          ),
          context.spacing.gapSm,
          SizedBox(
            height: context.sizes.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: controller.openSystemSettings,
              icon: const Icon(Icons.settings_outlined),
              label: Text(l10n.onboardingMicOpenSettings),
            ),
          ),
        ],
      ),
    };

    return StepScaffold(
      leading: const StepIcon(Icons.mic_none),
      title: l10n.onboardingMicTitle,
      description: l10n.onboardingMicBody,
      child: action,
    );
  }
}
