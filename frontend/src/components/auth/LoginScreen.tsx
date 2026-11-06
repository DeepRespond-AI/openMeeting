'use client';

import React from 'react';
import { WifiOff } from 'lucide-react';
import { useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { OnboardingShell } from '@/components/onboarding/shared/OnboardingShell';
import { PhoneAuth } from './PhoneAuth';

/**
 * Full-screen phone login shown when onboarding is done but no session exists
 * (never signed in, signed out, or the session expired). The server is built in.
 */
export function LoginScreen() {
  const t = useT();
  const { status } = useServer();
  const unreachable = !!status && !status.connected;

  return (
    <OnboardingShell>
      <div className="space-y-5">
        <PhoneAuth />
        {unreachable && (
          <p role="status" className="flex items-center justify-center gap-1.5 text-center text-xs text-destructive">
            <WifiOff className="h-3.5 w-3.5 shrink-0" />
            {t('auth.loginScreen.unreachable')}
          </p>
        )}
      </div>
    </OnboardingShell>
  );
}
