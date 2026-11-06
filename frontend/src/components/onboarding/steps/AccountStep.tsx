'use client';

import React, { useState } from 'react';
import { ArrowRight, CheckCircle2, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';
import { OnboardingContainer } from '../OnboardingContainer';
import { useOnboarding } from '@/contexts/OnboardingContext';
import { useServer } from '@/contexts/ServerContext';
import { usePlatform } from '@/hooks/usePlatform';
import { PhoneAuth } from '@/components/auth/PhoneAuth';
import { UserAvatar } from '@/components/auth/UserAvatar';
import { maskPhone } from '@/lib/phone';
import { errorMessage } from '@/lib/server';

/**
 * Onboarding step 2: sign in (or sign up) with a mobile number.
 * On macOS the permissions step follows; elsewhere this finishes onboarding.
 */
export function AccountStep() {
  const t = useT();
  const { goNext, completeOnboarding } = useOnboarding();
  const { loggedIn, user, logout } = useServer();
  const isMac = usePlatform() === 'macos';
  const [busy, setBusy] = useState(false);

  const advance = async () => {
    if (isMac) {
      goNext();
      return;
    }
    setBusy(true);
    try {
      await completeOnboarding();
      await new Promise((resolve) => setTimeout(resolve, 100));
      window.location.reload();
    } catch (err) {
      toast.error(errorMessage(err));
      setBusy(false);
    }
  };

  const useAnother = async () => {
    setBusy(true);
    try {
      await logout();
    } catch (err) {
      toast.error(t('auth.toast.logoutFailed'), { description: errorMessage(err) });
    } finally {
      setBusy(false);
    }
  };

  return (
    <OnboardingContainer
      title={t('onboarding.account.title')}
      description={t('onboarding.account.description')}
      step={2}
      totalSteps={isMac ? 3 : 2}
    >
      {loggedIn && user ? (
        <div className="space-y-5">
          <div className="flex items-center gap-4 rounded-xl border border-border bg-card p-5 shadow-card">
            <UserAvatar name={user.name} size="lg" />
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-1.5 text-sm font-medium text-success">
                <CheckCircle2 className="h-4 w-4" />
                {t('onboarding.account.signedInHint')}
              </div>
              <div className="truncate text-lg font-semibold text-foreground" title={user.name}>
                {t('onboarding.account.signedInAs', { name: user.name })}
              </div>
              <div className="text-sm text-muted-foreground">{maskPhone(user.phone)}</div>
            </div>
          </div>
          <div className="space-y-2">
            <Button onClick={advance} disabled={busy} className="h-11 w-full rounded-lg">
              {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              {isMac ? t('common.actions.continue') : t('onboarding.account.finish')}
              {!busy && <ArrowRight className="h-4 w-4" />}
            </Button>
            <Button variant="ghost" onClick={useAnother} disabled={busy} className="w-full rounded-lg">
              {t('onboarding.account.useAnother')}
            </Button>
          </div>
        </div>
      ) : (
        <PhoneAuth showHeading={false} onSuccess={() => void advance()} />
      )}
    </OnboardingContainer>
  );
}
