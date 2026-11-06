'use client';

import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { usePathname } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import { useT } from '@/i18n';

const MeetingEntryContext = createContext<{
  beginEntry: () => void;
  finishEntry: () => void;
} | null>(null);

export function useMeetingEntry() {
  const value = useContext(MeetingEntryContext);
  if (!value) throw new Error('useMeetingEntry must be used within MeetingEntryProvider');
  return value;
}

/** Keep one loading screen mounted from the entry action through room readiness. */
export function MeetingEntryProvider({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const t = useT();
  const [pending, setPending] = useState(pathname === '/room');
  const beginEntry = useCallback(() => setPending(true), []);
  const finishEntry = useCallback(() => setPending(false), []);
  const value = useMemo(() => ({ beginEntry, finishEntry }), [beginEntry, finishEntry]);

  return <MeetingEntryContext.Provider value={value}>
    {children}
    {pending && <div role="status" aria-live="polite" data-testid="meeting-entry-loading"
      className="fixed inset-0 z-[100] flex flex-col items-center justify-center gap-3 bg-[#0B0D13] p-6 text-center">
      <Loader2 className="h-8 w-8 animate-spin text-primary" />
      <p className="text-base font-medium text-foreground">{t('home.quick.preparing')}</p>
      <p className="max-w-sm text-sm text-muted-foreground">{t('home.quick.preparingDesc')}</p>
    </div>}
  </MeetingEntryContext.Provider>;
}
