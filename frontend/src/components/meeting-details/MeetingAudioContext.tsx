"use client";

import { createContext, useCallback, useContext, useMemo, useRef, useState, type ReactNode } from 'react';

interface MeetingAudioContextValue {
  /** True once the recording is loaded and can be seeked. */
  ready: boolean;
  currentTime: number;
  duration: number | null;
  isPlaying: boolean;
  /** Seek to `seconds` and start playback. No-op while the recording is unavailable. */
  playFrom: (seconds: number) => void;
  /** Used by the player to attach its <audio> element. */
  registerAudio: (el: HTMLAudioElement | null) => void;
  setReady: (ready: boolean) => void;
  setCurrentTime: (seconds: number) => void;
  setDuration: (seconds: number | null) => void;
  setIsPlaying: (playing: boolean) => void;
}

const MeetingAudioContext = createContext<MeetingAudioContextValue | null>(null);

/** Shares playback state between the recording player and the transcript (click-to-seek, active row). */
export function MeetingAudioProvider({ children }: { children: ReactNode }) {
  const audioRef = useRef<HTMLAudioElement | null>(null);
  const [ready, setReady] = useState(false);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState<number | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);

  const registerAudio = useCallback((el: HTMLAudioElement | null) => {
    audioRef.current = el;
    if (!el) {
      setReady(false);
      setIsPlaying(false);
    }
  }, []);

  const playFrom = useCallback((seconds: number) => {
    const el = audioRef.current;
    if (!el) return;
    el.currentTime = Math.max(0, seconds);
    setCurrentTime(el.currentTime);
    void el.play().catch((error) => console.warn('[MeetingAudio] play() rejected:', error));
  }, []);

  const value = useMemo<MeetingAudioContextValue>(() => ({
    ready, currentTime, duration, isPlaying,
    playFrom, registerAudio, setReady, setCurrentTime, setDuration, setIsPlaying,
  }), [ready, currentTime, duration, isPlaying, playFrom, registerAudio]);

  return <MeetingAudioContext.Provider value={value}>{children}</MeetingAudioContext.Provider>;
}

/** Playback state; returns null outside a provider so components degrade to static rendering. */
export function useMeetingAudio(): MeetingAudioContextValue | null {
  return useContext(MeetingAudioContext);
}
