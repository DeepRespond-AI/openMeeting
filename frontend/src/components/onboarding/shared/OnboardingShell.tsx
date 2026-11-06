'use client';

import React from 'react';
import { Mic, Server, ShieldCheck, Sparkles } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { LanguageSwitcher } from '@/components/brand/LanguageSwitcher';

interface OnboardingShellProps {
  children: React.ReactNode;
  /** Show the compact language toggle in the top-right corner of the content panel. */
  showLanguageToggle?: boolean;
  /** Optional element in the top bar, left of the language toggle (e.g. "Step 2 of 3"). */
  topBarStart?: React.ReactNode;
  className?: string;
}

/** Brand hero panel shown on the left of every onboarding step (wide windows only). */
function BrandHero() {
  const t = useT();
  const values = [
    { icon: Mic, text: t('onboarding.container.values.record') },
    { icon: Server, text: t('onboarding.container.values.server') },
    { icon: Sparkles, text: t('onboarding.container.values.summary') },
  ];

  return (
    <aside className="relative hidden w-[40%] max-w-md shrink-0 flex-col justify-between overflow-hidden bg-brand-gradient p-10 text-white md:flex">
      {/* Decorative rings */}
      <div aria-hidden className="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full border border-white/15" />
      <div aria-hidden className="pointer-events-none absolute -bottom-32 -left-20 h-80 w-80 rounded-full bg-white/10 blur-2xl" />

      <div className="relative flex items-center gap-3">
        <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-white shadow-elevated">
          <BrandLogo size={30} />
        </div>
        <div className="min-w-0 leading-tight">
          <div className="truncate text-lg font-semibold">{t('common.appName')}</div>
          <div className="truncate text-xs text-white/75">{t('common.appTagline')}</div>
        </div>
      </div>

      <div className="relative space-y-6">
        <div className="space-y-3">
          <h2 className="text-2xl font-semibold leading-snug">{t('onboarding.container.heroHeadline')}</h2>
          <p className="text-sm leading-relaxed text-white/80">{t('onboarding.container.heroSubtitle')}</p>
        </div>
        <ul className="space-y-3">
          {values.map(({ icon: Icon, text }) => (
            <li key={text} className="flex items-start gap-3">
              <span className="mt-0.5 flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-white/15">
                <Icon className="h-4 w-4" />
              </span>
              <span className="text-sm leading-relaxed text-white/90">{text}</span>
            </li>
          ))}
        </ul>
      </div>

      <div className="relative flex items-center gap-2 text-xs text-white/75">
        <ShieldCheck className="h-4 w-4" />
        {t('onboarding.container.privacyNote')}
      </div>
    </aside>
  );
}

/** Full-window onboarding frame: brand hero on the left, step content on the right. */
export function OnboardingShell({ children, showLanguageToggle = true, topBarStart, className }: OnboardingShellProps) {
  return (
    <div className="fixed inset-0 z-50 flex overflow-hidden bg-background">
      <BrandHero />

      <main className="flex min-w-0 flex-1 flex-col">
        {/* Top bar */}
        <div className="flex h-14 shrink-0 items-center justify-between gap-3 px-6">
          <div className="flex min-w-0 items-center gap-3">
            {/* Brand mark for narrow windows where the hero panel is hidden */}
            <BrandLogo size={24} showName className="text-sm md:hidden" />
            {topBarStart}
          </div>
          {showLanguageToggle && <LanguageSwitcher variant="toggle" />}
        </div>

        {/* Step content */}
        <div className="custom-scrollbar min-h-0 flex-1 overflow-x-hidden overflow-y-auto px-6 pb-8 [color-scheme:dark]">
          <div className={cn('mx-auto flex min-h-full w-full max-w-lg flex-col justify-center py-4', className)}>
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}
