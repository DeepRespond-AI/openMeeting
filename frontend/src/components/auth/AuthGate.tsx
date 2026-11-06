'use client';

import React, { useEffect, useRef } from 'react';
import { Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import { useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { LoginScreen } from './LoginScreen';

/**
 * Shows the main app only with a verified account; otherwise the full-screen
 * phone login. A session lost to a 401 (status carries an error) also shows
 * a "session expired" toast; a manual sign-out does not.
 */
export function AuthGate({ children }: { children: React.ReactNode }) {
  const t = useT();
  const { loggedIn, isLoading, status } = useServer();
  const wasLoggedIn = useRef<boolean | null>(null);

  useEffect(() => {
    if (isLoading) return;
    if (wasLoggedIn.current === true && !loggedIn && status?.error) {
      toast.warning(t('auth.toast.sessionExpired'), { id: 'session-expired' });
    }
    wasLoggedIn.current = loggedIn;
  }, [isLoading, loggedIn, status?.error, t]);

  if (isLoading) {
    return (
      <div className="flex h-screen flex-col items-center justify-center gap-4 bg-background">
        <BrandLogo size={56} />
        <Loader2 className="h-5 w-5 animate-spin text-muted-foreground" aria-label={t('common.status.loading')} />
      </div>
    );
  }
  if (!loggedIn) return <LoginScreen />;
  return <>{children}</>;
}
