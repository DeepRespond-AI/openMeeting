'use client';

import { useCallback, useEffect, useState, type ReactNode } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { MonitorUp } from 'lucide-react';
import { toast } from 'sonner';
import { useT } from '@/i18n';
import { JOIN_INTENT_KEY } from './JoinDialog';
import { RoomProvider, useRoom } from './room/RoomProvider';
import RoomScreen from './room/RoomScreen';
import { MeetingEntryProvider, useMeetingEntry } from './MeetingEntry';

function SessionView({ code, close }: { code: string; close: () => void }) {
  const { phase, room, connectionState, entryStatus } = useRoom();
  const { beginEntry, finishEntry } = useMeetingEntry();
  const pathname = usePathname();
  const search = useSearchParams();
  const router = useRouter();
  const t = useT();
  const inRoom = pathname === '/room';
  const terminal = phase === 'ended' || phase === 'error';

  useEffect(() => {
    if (phase === 'joining' || (phase === 'joined' && entryStatus === 'loading')) beginEntry();
    else finishEntry();
  }, [phase, entryStatus, inRoom, search, beginEntry, finishEntry]);

  useEffect(() => {
    if (phase === 'ended') {
      close();
      if (inRoom) router.replace('/');
    } else if (!inRoom && terminal) close();
  }, [phase, inRoom, terminal, close, router]);
  useEffect(() => {
    const requested = search.get('code');
    if (!inRoom || !requested || requested === code) return;
    sessionStorage.removeItem(JOIN_INTENT_KEY);
    toast.info(t('liveMeeting.room.session.conflict'));
    router.replace(`/room?code=${encodeURIComponent(code)}`);
  }, [inRoom, search, code, router, t]);

  return <>
    {!inRoom && !terminal && <button type="button" data-testid="return-meeting" onClick={() => router.push(`/room?code=${encodeURIComponent(code)}`)}
      className="fixed bottom-4 left-20 right-4 z-40 flex min-w-0 items-center gap-3 rounded-xl border border-primary/40 bg-card px-4 py-3 text-left shadow-elevated sm:left-auto sm:max-w-md">
      <MonitorUp className="h-5 w-5 shrink-0 text-primary" />
      <span className="min-w-0 flex-1"><span className="block truncate text-sm font-semibold" title={room?.title}>{room?.title ?? code}</span>
        <span role="status" className="block text-xs text-muted-foreground">{t(`liveMeeting.room.session.${phase === 'joining' ? 'joining' : phase === 'waiting' ? 'waiting' : connectionState === 'reconnecting' ? 'reconnecting' : 'ongoing'}`)}</span></span>
      <span className="shrink-0 text-sm text-primary">{t('liveMeeting.room.session.return')}</span>
    </button>}
    {/* Keep media elements mounted so audio and the share session survive navigation. */}
    <div hidden={!inRoom} aria-hidden={!inRoom} data-testid="persistent-meeting" className={inRoom ? 'fixed inset-0 z-30' : 'hidden'}>
      <RoomScreen />
    </div>
  </>;
}

/** One authenticated session survives client-side navigation until explicit exit. */
export default function MeetingSession({ children }: { children: ReactNode }) {
  return <MeetingEntryProvider><PersistentMeetingSession>{children}</PersistentMeetingSession></MeetingEntryProvider>;
}

function PersistentMeetingSession({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const search = useSearchParams();
  const [code, setCode] = useState<string | null>(null);
  const [dismissed, setDismissed] = useState(false);
  const { beginEntry, finishEntry } = useMeetingEntry();
  const close = useCallback(() => { finishEntry(); setDismissed(true); setCode(null); }, [finishEntry]);
  useEffect(() => {
    if (pathname !== '/room') { setDismissed(false); return; }
    if (code !== null || dismissed) return;
    let requested = search.get('code');
    if (!requested) {
      try { requested = JSON.parse(sessionStorage.getItem(JOIN_INTENT_KEY) || 'null')?.code; } catch { /* invalid intent */ }
    }
    beginEntry();
    setCode(requested || '');
  }, [pathname, search, code, dismissed, beginEntry]);
  return <div className="h-dvh min-h-0">
    <div style={{ height: code !== null && pathname !== '/room' ? 'calc(100dvh - 80px)' : '100dvh' }}>{children}</div>
    {code !== null && <RoomProvider key={code} code={code} onClose={close} visible={pathname === '/room'}><SessionView code={code} close={close} /></RoomProvider>}
  </div>;
}
