'use client';

import { useEffect, useRef, useState } from 'react';
import { CheckCircle2, Mic, RotateCcw, Volume2 } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { useT } from '@/i18n';
import { AudioLevelMonitor, rmsToLevel } from '@/services/live-meeting/media/audioLevels';
import { createSpeakerTest, routeAudio } from '@/services/live-meeting/media/audioDevices';
import { cn } from '@/lib/utils';

export function SignalMeter({ level, label }: { level: number; label: string }) {
  const value = Math.round(Math.min(1, Math.max(0, level)) * 100);
  return <div role="meter" aria-label={label} aria-valuemin={0} aria-valuemax={100} aria-valuenow={value} className="flex flex-1 gap-1.5">
    {Array.from({ length: 10 }, (_, index) => <span key={index} className={cn('h-3 flex-1 rounded-sm transition-colors', value > index * 10 ? 'bg-primary' : 'bg-muted')} />)}
  </div>;
}

export default function AudioDiagnostics({ open, onOpenChange, microphoneId, speakerId, renderDevices, onDevicesReady }: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  microphoneId: string;
  speakerId: string;
  renderDevices: (kind: 'audioinput' | 'audiooutput') => React.ReactNode;
  onDevicesReady: () => Promise<void>;
}) {
  const t = useT();
  const [step, setStep] = useState<'speaker' | 'microphone' | 'done'>('speaker');
  const [attempt, setAttempt] = useState(0);
  const [level, setLevel] = useState(0);
  const [detected, setDetected] = useState(false);
  const [error, setError] = useState<'' | 'inputFailed' | 'outputFailed' | 'permissionDenied'>('');
  const [hint, setHint] = useState<'noSpeaker' | 'noMicrophone' | null>(null);
  const [starting, setStarting] = useState(false);
  const generation = useRef(0);

  useEffect(() => { if (!open) { setStep('speaker'); setError(''); setHint(null); setLevel(0); setDetected(false); } }, [open]);
  useEffect(() => {
    if (!open || step === 'done') return;
    const current = ++generation.current;
    let disposed = false;
    let stream: MediaStream | undefined;
    let stopPlayback: (() => void) | undefined;
    let timer: ReturnType<typeof setInterval> | undefined;
    const monitor = new AudioLevelMonitor();
    setLevel(0); setDetected(false); setError(''); setStarting(true);
    void (async () => {
      if (step === 'speaker') {
        const test = createSpeakerTest();
        stopPlayback = test.dispose;
        await routeAudio(test.audio, speakerId);
        if (disposed) return;
        await test.audio.play();
        if (disposed) { test.dispose(); return; }
        // Show the generated test signal only while playback is advancing.
        let previousTime = -1;
        timer = setInterval(() => {
          const time = test.audio.currentTime;
          const advancing = !test.audio.paused && time !== previousTime;
          previousTime = time;
          const beat = time % 0.5;
          setLevel(advancing ? rmsToLevel(0.14 * Math.min(1, beat / 0.02) * Math.max(0, 1 - beat / 0.42)) : 0);
        }, 100);
      } else {
        if (!navigator.mediaDevices?.getUserMedia) throw new Error('unsupported');
        stream = await navigator.mediaDevices.getUserMedia({ audio: { ...(microphoneId !== 'default' ? { deviceId: { exact: microphoneId } } : {}), echoCancellation: true, noiseSuppression: true }, video: false });
        if (disposed) { stream.getTracks().forEach(track => track.stop()); return; }
        void onDevicesReady();
        const track = stream.getAudioTracks()[0];
        if (!track) throw new Error('missingMicrophone');
        track.addEventListener('ended', () => { if (!disposed) { setError('inputFailed'); setLevel(0); } }, { once: true });
        monitor.start(() => [{ key: 'test', username: null, kind: 'audio', local: true, track }], levels => {
          if (disposed) return;
          setLevel(levels.test ?? 0);
          if ((levels.test ?? 0) > 0.05) setDetected(true);
        });
      }
      if (!disposed) setStarting(false);
    })().catch(error => {
      if (!disposed && current === generation.current) {
        setStarting(false);
        setError(step === 'speaker' ? 'outputFailed' : error?.name === 'NotAllowedError' ? 'permissionDenied' : 'inputFailed');
        setLevel(0);
      }
      stopPlayback?.(); stream?.getTracks().forEach(track => track.stop());
    });
    return () => {
      disposed = true; ++generation.current;
      if (timer) clearInterval(timer);
      monitor.stop(); stopPlayback?.(); stream?.getTracks().forEach(track => track.stop());
    };
  }, [open, step, microphoneId, speakerId, attempt, onDevicesReady]);

  const primary = 'h-10 flex-1 rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground disabled:opacity-50 hover:bg-primary/90';
  const secondary = 'h-10 flex-1 rounded-lg border border-border px-4 text-sm hover:bg-muted';
  return <Dialog open={open} onOpenChange={onOpenChange}>
    <DialogContent className="max-h-[85vh] w-[92vw] max-w-[520px] overflow-y-auto rounded-xl">
      <DialogTitle>{t(`liveMeeting.room.audio.${step === 'speaker' ? 'speakerTesting' : step === 'microphone' ? 'microphoneTesting' : 'testComplete'}`)}</DialogTitle>
      <DialogDescription>{t(`liveMeeting.room.audio.${step === 'speaker' ? 'speakerPrompt' : step === 'microphone' ? 'microphonePrompt' : 'testCompleteDesc'}`)}</DialogDescription>
      {step !== 'done' ? <>
        <div className="space-y-5 py-3">
          {renderDevices(step === 'speaker' ? 'audiooutput' : 'audioinput')}
          <div className="flex items-center gap-3 text-sm">
            {step === 'speaker' ? <Volume2 className="h-4 w-4 text-primary" /> : <Mic className="h-4 w-4 text-primary" />}
            <span className="shrink-0 text-muted-foreground">{t(`liveMeeting.room.audio.${step === 'speaker' ? 'outputLevel' : 'inputLevel'}`)}</span>
            <SignalMeter level={level} label={t(`liveMeeting.room.audio.${step === 'speaker' ? 'outputLevel' : 'inputLevel'}`)} />
          </div>
          {error && <p role="alert" className="text-sm text-destructive">{t(`liveMeeting.room.audio.${error}`)}</p>}
          {hint && <p role="status" className="text-sm text-muted-foreground">{t(`liveMeeting.room.audio.${hint}`)}</p>}
          {starting && <p role="status" className="text-sm text-muted-foreground">{t('liveMeeting.room.audio.starting')}</p>}
        </div>
        <div className="flex gap-3">
          <button type="button" className={secondary} onClick={() => { setHint(step === 'speaker' ? 'noSpeaker' : 'noMicrophone'); setAttempt(value => value + 1); }}>
            {t('liveMeeting.room.audio.retryTest')}
          </button>
          <button type="button" className={primary} disabled={starting || !!error || (step === 'microphone' && !detected)} onClick={() => { setHint(null); setStep(step === 'speaker' ? 'microphone' : 'done'); }}>
            {t(`liveMeeting.room.audio.${step === 'speaker' ? 'heard' : 'micWorks'}`)}
          </button>
        </div>
        <p className="text-xs text-muted-foreground">{t('liveMeeting.room.audio.testPrivacy')}</p>
      </> : <>
        <CheckCircle2 className="mx-auto my-4 h-12 w-12 text-success" />
        <div className="flex gap-3">
          <button type="button" className={secondary} onClick={() => setStep('speaker')}><RotateCcw className="mr-2 inline h-4 w-4" />{t('liveMeeting.room.audio.testAgain')}</button>
          <button type="button" className={primary} onClick={() => onOpenChange(false)}>{t('liveMeeting.room.audio.done')}</button>
        </div>
      </>}
    </DialogContent>
  </Dialog>;
}
