'use client';

import React from 'react';
import { Check } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useT, type TranslationKey } from '@/i18n';

interface ProgressIndicatorProps {
  current: number;
  total: number;
  onStepClick?: (step: number) => void;
}

// Labels for the onboarding steps, in order (Permissions is macOS only).
const STEP_LABELS: TranslationKey[] = [
  'onboarding.progress.welcome',
  'onboarding.progress.account',
  'onboarding.progress.permissions',
];

export function ProgressIndicator({ current, total, onStepClick }: ProgressIndicatorProps) {
  const t = useT();
  const visibleSteps = Array.from({ length: total }, (_, i) => i + 1);

  return (
    <ol className="flex items-center justify-center gap-2">
      {visibleSteps.map((step, index) => {
        const isActive = step === current;
        const isCompleted = step < current;
        const isClickable = isCompleted && !!onStepClick;
        const labelKey = STEP_LABELS[step - 1];

        return (
          <React.Fragment key={step}>
            <li>
              <button
                type="button"
                onClick={() => isClickable && onStepClick?.(step)}
                disabled={!isClickable}
                aria-current={isActive ? 'step' : undefined}
                className={cn(
                  'flex items-center gap-2 rounded-full transition-colors',
                  isClickable ? 'cursor-pointer hover:opacity-80' : 'cursor-default',
                )}
              >
                <span
                  className={cn(
                    'flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-semibold transition-colors',
                    isCompleted && 'bg-primary text-primary-foreground',
                    isActive && 'bg-primary text-primary-foreground ring-4 ring-primary/15',
                    !isCompleted && !isActive && 'bg-muted text-muted-foreground',
                  )}
                >
                  {isCompleted ? <Check className="h-3.5 w-3.5" /> : step}
                </span>
                {labelKey && (
                  <span
                    className={cn(
                      'whitespace-nowrap text-xs font-medium',
                      isActive ? 'text-foreground' : 'text-muted-foreground',
                    )}
                  >
                    {t(labelKey)}
                  </span>
                )}
              </button>
            </li>

            {/* Connector Line */}
            {index < visibleSteps.length - 1 && (
              <li aria-hidden className={cn('h-px w-8 transition-colors', isCompleted ? 'bg-primary' : 'bg-border')} />
            )}
          </React.Fragment>
        );
      })}
    </ol>
  );
}
