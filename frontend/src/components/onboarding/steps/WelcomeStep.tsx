'use client';

import React from 'react';
import { ArrowRight, Languages } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { LanguageSwitcher } from '@/components/brand/LanguageSwitcher';
import { OnboardingShell } from '../shared/OnboardingShell';
import { useOnboarding } from '@/contexts/OnboardingContext';

export function WelcomeStep() {
  const t = useT();
  const { goNext } = useOnboarding();

  return (
    // The full language picker lives in the page body here, so no corner toggle.
    <OnboardingShell showLanguageToggle={false}>
      <div className="flex flex-col gap-8">
        {/* Brand + intro */}
        <div className="space-y-5">
          <BrandLogo size={56} showName showTagline className="gap-3 text-lg" />
          <div className="space-y-2">
            <h1 className="animate-fade-in-up text-2xl font-semibold text-foreground">
              {t('onboarding.welcome.title', { appName: t('common.appName') })}
            </h1>
            <p className="animate-fade-in-up delay-75 text-sm leading-relaxed text-muted-foreground">
              {t('onboarding.welcome.description')}
            </p>
          </div>
        </div>

        {/* Language picker */}
        <div className="space-y-4 rounded-xl border border-border bg-card p-5 shadow-card">
          <div className="flex items-start gap-3">
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-accent text-primary">
              <Languages className="h-4 w-4" />
            </span>
            <div className="min-w-0">
              <div className="text-base font-semibold text-foreground">{t('onboarding.welcome.languageTitle')}</div>
              <div className="text-xs text-muted-foreground">{t('onboarding.welcome.languageHint')}</div>
            </div>
          </div>
          <LanguageSwitcher variant="segmented" className="w-full [&>button]:flex-1" />
        </div>

        {/* CTA */}
        <div className="space-y-3">
          <Button onClick={goNext} className="h-11 w-full rounded-lg">
            {t('onboarding.welcome.start')}
            <ArrowRight className="h-4 w-4" />
          </Button>
          <p className="text-center text-xs text-muted-foreground">{t('onboarding.welcome.duration')}</p>
        </div>
      </div>
    </OnboardingShell>
  );
}
