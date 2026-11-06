'use client';

/**
 * DeepRespond IM client lifecycle (contexts layer).
 *
 * The engine window holds the connection; this provider owns the UI-window
 * client (`createDRTauriClient`) and the ticket login: `im_get_ticket` (Rust)
 * → OpenMeeting server §1.11 → `loginWithTicket`. Data hooks come from
 * `@deeprespond/im-web-react` (wrapped in DRProvider here); this context only
 * exposes lifecycle status. In a plain browser (no Tauri) it degrades to
 * `unavailable` and renders children without the IM provider.
 */
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import { invoke } from '@tauri-apps/api/core';
import { createDRTauriClient, type DRTauriClient } from '@deeprespond/im-tauri';
import { DRProvider } from '@deeprespond/im-web-react';
import { useServer } from '@/contexts/ServerContext';

export type ImStatus = /** No Tauri runtime (browser dev) — IM UI is inert. */ 'unavailable'
  | /** Fetching the ticket / creating the client / logging in. */ 'connecting'
  | /** Client logged in, hooks usable. */ 'ready'
  | /** Ticket or login failed — retry via relogin(). */ 'error';

interface ImLifecycle {
  client: DRTauriClient | null;
  status: ImStatus;
  errorText: string | null;
  relogin: () => void;
}

const ImLifecycleContext = createContext<ImLifecycle>({
  client: null,
  status: 'connecting',
  errorText: null,
  relogin: () => {},
});

interface ImTicketResponse {
  ticket: string;
  apiUrl: string;
  appKey: string;
}

function isTauri(): boolean {
  return typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window;
}

export function ImProvider({ children }: { children: ReactNode }) {
  const {user,loggedIn}=useServer();
  const [client, setClient] = useState<DRTauriClient | null>(null);
  const [status, setStatus] = useState<ImStatus>('connecting');
  const [errorText, setErrorText] = useState<string | null>(null);
  const [nonce, setNonce] = useState(0);

  useEffect(() => {
    if (!isTauri() || !loggedIn || !user) {
      setStatus('unavailable');
      setClient(null);
      return;
    }
    let disposed = false;
    let owned: DRTauriClient | null=null;
    void (async () => {
      setStatus('connecting');
      setErrorText(null);
      try {
        const ticket = await invoke<ImTicketResponse>('im_get_ticket');
        if (disposed) return;
        const im = createDRTauriClient({ appKey: ticket.appKey });
        owned=im;
        if(im.auth.currentUser && im.auth.currentUser.username!==user.id)await im.auth.logout();
        if (!im.auth.currentUser) {
          await im.auth.loginWithTicket({ ticket: ticket.ticket });
        }
        if (disposed) return;
        setClient(im);
        setStatus('ready');
      } catch (err) {
        if (disposed) return;
        setErrorText(err instanceof Error ? err.message : String(err));
        setStatus('error');
      }
    })();
    return () => {
      disposed = true;
      void owned?.destroy();
    };
  }, [nonce,loggedIn,user?.id]);

  const relogin = useCallback(() => setNonce((n) => n + 1), []);

  const value = useMemo<ImLifecycle>(() => ({ client: status === 'ready' ? client : null, status, errorText, relogin }), [client, status, errorText, relogin]);

  return (
    <ImLifecycleContext.Provider value={value}>
      {/* Keep the tree stable while authentication hydrates or reconnects.
          Adding/removing this provider remounts the active meeting and races
          its previous leave request against the replacement join. */}
      <DRProvider client={client ?? undefined}>{children}</DRProvider>
    </ImLifecycleContext.Provider>
  );
}

/** IM lifecycle status (data hooks live in `@deeprespond/im-web-react`). */
export function useIm(): ImLifecycle {
  return useContext(ImLifecycleContext);
}
