'use client';

import { useCallback, useEffect, useRef, useState } from 'react';

export function useAudioDevices(enabled: boolean) {
  const [devices, setDevices] = useState<MediaDeviceInfo[]>([]);
  const [error, setError] = useState(false);
  const generation = useRef(0);
  const refresh = useCallback(async () => {
    const current = ++generation.current;
    try {
      if (!navigator.mediaDevices?.enumerateDevices) throw new Error('unsupported');
      const result = await navigator.mediaDevices.enumerateDevices();
      if (current === generation.current) { setDevices(result.filter(d => d.deviceId && (d.kind === 'audioinput' || d.kind === 'audiooutput'))); setError(false); }
    } catch { if (current === generation.current) setError(true); }
  }, []);
  useEffect(() => {
    if (!enabled) return;
    void refresh();
    navigator.mediaDevices?.addEventListener('devicechange', refresh);
    return () => { ++generation.current; navigator.mediaDevices?.removeEventListener('devicechange', refresh); };
  }, [enabled, refresh]);
  return { devices, error, refresh };
}
