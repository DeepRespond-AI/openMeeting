import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/context_extensions.dart';
import 'onboarding_controller.dart';
import 'widgets/account_step.dart';
import 'widgets/microphone_step.dart';
import 'widgets/welcome_step.dart';

/// First-run flow (3 steps with a progress indicator):
/// welcome + language → phone sign-in → microphone permission. The server is built in.
/// Finishing calls `completeOnboarding()`; the router then shows the meetings list.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    final Widget body = switch (state.step) {
      OnboardingStep.welcome => const WelcomeStep(),
      OnboardingStep.account => const AccountStep(),
      OnboardingStep.microphone => const MicrophoneStep(),
    };

    return PopScope(
      canPop: state.isFirst,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.sizes.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProgressHeader(state: state, onBack: controller.back),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: kThemeAnimationDuration,
                      child: KeyedSubtree(key: ValueKey(state.step), child: body),
                    ),
                  ),
                  Padding(
                    padding: context.spacing.page,
                    child: _BottomAction(state: state),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state, required this.onBack});

  final OnboardingState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(context.spacing.xs, context.spacing.xs, context.spacing.md, 0),
      child: Row(
        children: [
          SizedBox.square(
            dimension: context.sizes.touchTarget,
            child: state.isFirst
                ? null
                : IconButton(
                    onPressed: state.finishing ? null : onBack,
                    tooltip: context.l10n.commonBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
          ),
          context.spacing.gapXs,
          Expanded(
            child: ClipRRect(
              borderRadius: context.radius.pillAll,
              child: LinearProgressIndicator(
                value: state.position / OnboardingState.stepCount,
                backgroundColor: context.colors.muted,
              ),
            ),
          ),
          context.spacing.gapSm,
          Text(
            context.l10n.onboardingStepProgress(state.position, OnboardingState.stepCount),
            style: context.textTheme.labelMedium?.copyWith(color: context.colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

/// Primary action of the current step.
class _BottomAction extends ConsumerWidget {
  const _BottomAction({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final canAdvance = ref.watch(onboardingCanAdvanceProvider);

    switch (state.step) {
      case OnboardingStep.welcome:
        return _primary(context, l10n.onboardingGetStarted, controller.next);
      case OnboardingStep.account:
        return _primary(context, l10n.commonNext, canAdvance ? controller.next : null);
      case OnboardingStep.microphone:
        final granted =
            ref.watch(microphonePermissionControllerProvider).value == MicPermission.granted;
        return _primary(
          context,
          granted ? l10n.commonDone : l10n.onboardingMicSkip,
          state.finishing ? null : controller.next,
        );
    }
  }

  Widget _primary(BuildContext context, String label, VoidCallback? onPressed) => SizedBox(
    height: context.sizes.buttonHeight,
    child: FilledButton(onPressed: onPressed, child: Text(label)),
  );
}
