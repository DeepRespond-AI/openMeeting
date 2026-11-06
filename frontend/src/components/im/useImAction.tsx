'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import { useT } from '@/i18n';

/** Keep failures in the panel that initiated them; reject overlapping writes. */
export function useImAction() {
  const t = useT(),
    mounted = useRef(true),
    lock = useRef(false);
  const [pending, setPending] = useState(false),
    [error, setError] = useState('');
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  const run = useCallback(
    async (task: () => Promise<unknown>) => {
      if (lock.current) return false;
      lock.current = true;
      setPending(true);
      setError('');
      try {
        await task();
        return true;
      } catch (e) {
        if (mounted.current)
          setError(e instanceof Error ? e.message : t('im.workbench.failed'));
        return false;
      } finally {
        lock.current = false;
        if (mounted.current) setPending(false);
      }
    },
    [t],
  );
  return { pending, error, run, setError };
}

export const inputClass =
  'w-full min-w-0 rounded-lg border border-white/15 bg-white/5 px-3 py-2 text-sm disabled:opacity-50';
export const buttonClass =
  'rounded-lg border border-white/15 bg-white/5 px-3 py-1.5 text-xs hover:bg-white/10 disabled:opacity-40';
export function ActionError({ error }: { error: string }) {
  return error ? (
    <p role="alert" className="break-words text-sm text-red-400">
      {error}
    </p>
  ) : null;
}
