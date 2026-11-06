'use client';

import { useCallback, useEffect, useState } from 'react';

/** Whole seconds left until `endAt` (ms epoch), never negative. */
export function secondsLeft(endAt: number | null, now: number = Date.now()): number {
  if (endAt === null) return 0;
  return Math.max(0, Math.ceil((endAt - now) / 1000));
}

/**
 * A resend countdown (e.g. "Resend in 59s"). Based on an end timestamp so it
 * stays accurate when timers are throttled in a background window.
 */
export function useCountdown(tickMs = 250) {
  const [endAt, setEndAt] = useState<number | null>(null);
  const [remaining, setRemaining] = useState(0);

  useEffect(() => {
    if (endAt === null) {
      setRemaining(0);
      return;
    }
    const update = () => {
      const left = secondsLeft(endAt);
      setRemaining(left);
      if (left === 0) setEndAt(null);
    };
    update();
    const id = setInterval(update, tickMs);
    return () => clearInterval(id);
  }, [endAt, tickMs]);

  const start = useCallback((seconds: number) => {
    const safe = Number.isFinite(seconds) && seconds > 0 ? seconds : 0;
    if (safe === 0) {
      setEndAt(null);
      return;
    }
    setRemaining(Math.ceil(safe));
    setEndAt(Date.now() + safe * 1000);
  }, []);

  const reset = useCallback(() => setEndAt(null), []);

  return { remaining, running: remaining > 0, start, reset };
}
