'use client';

import { useEffect, useRef, useState } from 'react';
import { AudioLevelMonitor, type AudioLevels } from '@/services/live-meeting/media/audioLevels';
import type { MediaTrack } from '@/services/live-meeting/media/types';

export function useAudioLevels(tracks: MediaTrack[], enabled: boolean): AudioLevels {
  const current = useRef(tracks);
  current.current = tracks;
  const [levels, setLevels] = useState<AudioLevels>({});
  useEffect(() => {
    setLevels({});
    if (!enabled) return;
    const monitor = new AudioLevelMonitor();
    monitor.start(() => current.current, setLevels);
    return () => monitor.stop();
  }, [enabled]);
  return enabled ? levels : {};
}
