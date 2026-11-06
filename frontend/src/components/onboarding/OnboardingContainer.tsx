'use client';

import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { ProgressIndicator } from './shared/ProgressIndicator';
import { OnboardingShell } from './shared/OnboardingShell';
import { useOnboarding } from '@/contexts/OnboardingContext';
import type { OnboardingContainerProps } from '@/types/onboarding';

export function OnboardingContainer({
  title,
  description,
  children,
  step,
  totalSteps = 5,
  stepOffset = 0,
  hideProgress = false,
  className,
  showNavigation = false,
  onNext,
  onPrevious,
  canGoNext = true,
  canGoPrevious = true,
}: OnboardingContainerProps) {
  const t = useT();
  const { goToStep, goPrevious, goNext } = useOnboarding();

  const handlePrevious = () => {
    if (onPrevious) {
      onPrevious();
    } else {
      goPrevious();
    }
  };

  const handleNext = () => {
    if (onNext) {
      onNext();
    } else {
      goNext();
    }
  };

  const handleStepClick = (s: number) => {
    goToStep(s + stepOffset);
  };

  const prevEnabled = canGoPrevious && step !== 1;
  const nextEnabled = canGoNext && step !== totalSteps;
  const navButtonClass =
    'flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border bg-card text-muted-foreground shadow-card transition-colors';

  return (
    <OnboardingShell
      className={className}
      topBarStart={
        step && hideProgress ? (
          <span className="truncate text-xs text-muted-foreground">
            {t('onboarding.container.stepOf', { current: step, total: totalSteps })}
          </span>
        ) : undefined
      }
    >
      {/* Progress Indicator with Navigation */}
      {step && !hideProgress && (
        <div className="mb-8 flex shrink-0 items-center justify-center gap-3">
          {showNavigation && (
            <button
              type="button"
              onClick={handlePrevious}
              disabled={!prevEnabled}
              aria-label={t('common.actions.back')}
              className={cn(
                navButtonClass,
                prevEnabled ? 'hover:bg-accent hover:text-accent-foreground' : 'invisible',
              )}
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
          )}

          <ProgressIndicator current={step} total={totalSteps} onStepClick={handleStepClick} />

          {showNavigation && (
            <button
              type="button"
              onClick={handleNext}
              disabled={!nextEnabled}
              aria-label={t('common.actions.next')}
              className={cn(
                navButtonClass,
                nextEnabled ? 'hover:bg-accent hover:text-accent-foreground' : 'invisible',
              )}
            >
              <ChevronRight className="h-4 w-4" />
            </button>
          )}
        </div>
      )}

      {/* Header */}
      <div className="mb-6 shrink-0 space-y-2">
        <h1 className="animate-fade-in-up text-2xl font-semibold text-foreground">{title}</h1>
        {description && (
          <p className="animate-fade-in-up delay-75 text-sm leading-relaxed text-muted-foreground">{description}</p>
        )}
      </div>

      {/* Content */}
      <div className="space-y-6">{children}</div>
    </OnboardingShell>
  );
}
