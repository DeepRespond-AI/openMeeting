'use client';

import { useRef, useState } from 'react';
import { Check, ChevronUp, Headphones, Loader2, Mic, Settings, Volume2, VolumeX } from 'lucide-react';
import { toast } from 'sonner';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { DropdownMenu, DropdownMenuCheckboxItem, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { useT } from '@/i18n';
import { useAudioDevices } from '@/hooks/useAudioDevices';
import { getMediaClient } from '@/services/live-meeting';
import { AudioDeviceError, microphoneErrorMessage, supportsSpeakerSelection } from '@/services/live-meeting/media/audioDevices';
import { cn } from '@/lib/utils';
import { useRoom } from './RoomProvider';
import AudioDiagnostics from './AudioDiagnostics';
import MicrophoneIndicator from './MicrophoneIndicator';

export default function AudioControls() {
  const t = useT();
  const { self, audioLevels, audioConnected, audioPreferences, setAudioPreferences, connectAudio, disconnectAudio, toggleMic, mediaState, mediaAvailable } = useRoom();
  const { devices, error: devicesError, refresh } = useAudioDevices(true);
  const [joinOpen, setJoinOpen] = useState(!audioConnected);
  const [testOpen, setTestOpen] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [connectionTab, setConnectionTab] = useState<'computer' | 'phone'>('computer');
  const [busy, setBusy] = useState(false);
  const pending = useRef(false);
  const [error, setError] = useState('');
  const microphoneId = mediaState.microphoneDeviceId ?? audioPreferences.microphoneId;
  const speakerId = mediaState.speakerDeviceId ?? audioPreferences.speakerId;
  if (!self) return null;

  const label = (device: MediaDeviceInfo, index: number) => device.label || t(device.kind === 'audioinput' ? 'liveMeeting.room.audio.microphoneNumber' : 'liveMeeting.room.audio.speakerNumber', { number: index + 1 });
  const choices = (kind: 'audioinput' | 'audiooutput') => devices.filter(device => device.kind === kind && device.deviceId !== 'default');
  const run = async (action: () => Promise<void>) => {
    if (pending.current) return;
    pending.current = true;
    setBusy(true); setError('');
    try { await action(); }
    catch (e) {
      const message = e instanceof Error ? e.message : t('liveMeeting.room.errors.generic');
      setError(message); toast.error(message);
    } finally { pending.current = false; setBusy(false); }
  };
  const selectDevice = async (kind: 'audioinput' | 'audiooutput', id: string) => {
    await run(async () => {
      const media = getMediaClient();
      try {
        if (kind === 'audioinput') {
          if (!media.setMicrophoneDevice) throw new AudioDeviceError('sdkReloadRequired');
          await media.setMicrophoneDevice(id);
          setAudioPreferences({ microphoneId: id });
        } else {
          if (!media.setSpeakerDevice) throw new Error('unsupported');
          await media.setSpeakerDevice(id);
          setAudioPreferences({ speakerId: id });
        }
      } catch (cause) {
        const key = kind === 'audioinput' ? microphoneErrorMessage(cause) : 'outputFailed';
        console.warn('[meeting-audio] Device switch failed', { kind, reason: key, cause });
        throw new Error(t(`liveMeeting.room.audio.${key}`));
      }
      await refresh();
    });
  };
  const authorize = () => run(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });
      stream.getTracks().forEach(track => track.stop());
      await refresh();
    } catch { throw new Error(t('liveMeeting.room.audio.permissionDenied')); }
  });
  const deviceSelect = (kind: 'audioinput' | 'audiooutput') => {
    const selected = kind === 'audioinput' ? microphoneId : speakerId;
    const available = choices(kind);
    const missing = selected !== 'default' && !available.some(device => device.deviceId === selected);
    return <label className="flex items-center gap-3 text-sm">
      <span className="w-16 shrink-0">{t(kind === 'audioinput' ? 'liveMeeting.room.audio.microphone' : 'liveMeeting.room.audio.speaker')}</span>
      <select value={selected} disabled={busy || (kind === 'audioinput' && !mediaAvailable) || (kind === 'audiooutput' && !supportsSpeakerSelection())}
        onChange={event => void selectDevice(kind, event.target.value)} className="min-w-0 flex-1 rounded-md border border-border bg-background px-2 py-2 text-foreground disabled:opacity-50">
        <option value="default">{t('liveMeeting.room.audio.systemDefault')}</option>
        {missing && <option value={selected} disabled>{t('liveMeeting.room.audio.deviceMissing')}</option>}
        {available.map((device, index) => <option key={device.deviceId} value={device.deviceId}>{label(device, index)}</option>)}
      </select>
    </label>;
  };
  const openTest = () => { setJoinOpen(false); setSettingsOpen(false); setError(''); setTestOpen(true); void refresh(); };
  const muted = !audioConnected || !self.micOn || !!self.mutedByHost;
  return <>
    <div className="flex items-center gap-0.5">
      <button type="button" onClick={() => audioConnected ? toggleMic() : setJoinOpen(true)} aria-pressed={!muted}
        aria-label={t(!audioConnected ? 'liveMeeting.room.audio.connect' : muted ? 'liveMeeting.room.toolbar.micOff' : 'liveMeeting.room.toolbar.mic')}
        className={cn('relative flex h-11 w-11 shrink-0 flex-col items-center justify-center gap-0.5 rounded-full text-white transition-colors sm:h-12 sm:w-12', muted ? 'bg-[#DC3B3B] hover:bg-[#C23232]' : 'bg-white/10 hover:bg-white/20')}>
        <MicrophoneIndicator muted={muted} level={audioLevels[self.id]} iconClassName="h-[18px] w-[18px]" mutedIconClassName="text-white" />
        <span className="text-[9px] leading-none text-white/80">{t(!audioConnected ? 'liveMeeting.room.audio.connect' : self.micOn ? 'liveMeeting.room.toolbar.mic' : 'liveMeeting.room.toolbar.micOff')}</span>
      </button>
      <DropdownMenu onOpenChange={open => { if (open) void refresh(); }}>
        <DropdownMenuTrigger asChild><button type="button" aria-label={t('liveMeeting.room.audio.menu')} className="flex h-10 w-5 items-center justify-center rounded-md text-white/80 hover:bg-white/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"><ChevronUp className="h-3.5 w-3.5" /></button></DropdownMenuTrigger>
        <DropdownMenuContent side="top" align="start" sideOffset={14} className="w-[min(420px,calc(100vw-2rem))] p-2">
          {(['audiooutput', 'audioinput'] as const).map(kind => <div key={kind}>
            <DropdownMenuLabel className="text-xs font-normal text-muted-foreground">{t(kind === 'audioinput' ? 'liveMeeting.room.audio.selectMicrophone' : 'liveMeeting.room.audio.selectSpeaker')}</DropdownMenuLabel>
            {[{ deviceId: 'default', label: t('liveMeeting.room.audio.systemDefault') }, ...choices(kind).map((device, index) => ({ deviceId: device.deviceId, label: label(device, index) }))].map(device => {
              const selected = (kind === 'audioinput' ? microphoneId : speakerId) === device.deviceId;
              return <DropdownMenuItem key={device.deviceId} disabled={busy || (kind === 'audioinput' && !mediaAvailable) || (kind === 'audiooutput' && device.deviceId !== 'default' && !supportsSpeakerSelection())}
                onSelect={() => void selectDevice(kind, device.deviceId)} className="min-h-9 justify-between gap-3">
                <span className="truncate">{device.label}</span>{selected && <Check className="h-4 w-4 shrink-0 text-primary" />}
              </DropdownMenuItem>;
            })}
            <DropdownMenuSeparator />
          </div>)}
          {(!devices.length || devices.some(device => !device.label)) && <DropdownMenuItem disabled={busy} onSelect={() => void authorize()}>{t('liveMeeting.room.audio.authorize')}</DropdownMenuItem>}
          {devicesError && <p role="alert" className="px-2 py-1 text-xs text-destructive">{t('liveMeeting.room.audio.devicesFailed')}</p>}
          <DropdownMenuItem disabled={busy} onSelect={() => audioConnected ? void run(disconnectAudio) : setJoinOpen(true)}>
            {audioConnected ? <VolumeX /> : <Headphones />}{t(audioConnected ? 'liveMeeting.room.audio.disconnect' : 'liveMeeting.room.audio.connect')}
          </DropdownMenuItem>
          <DropdownMenuCheckboxItem checked={audioPreferences.unmuteSound} onCheckedChange={value => setAudioPreferences({ unmuteSound: value })}>{t('liveMeeting.room.audio.unmuteSound')}</DropdownMenuCheckboxItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem onSelect={openTest}><Volume2 />{t('liveMeeting.room.audio.test')}</DropdownMenuItem>
          <DropdownMenuItem onSelect={() => { setError(''); setSettingsOpen(true); void refresh(); }}><Settings />{t('liveMeeting.room.audio.settings')}</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </div>

    <Dialog open={joinOpen} onOpenChange={setJoinOpen}>
      <DialogContent className="max-h-[85vh] w-[92vw] max-w-[500px] overflow-y-auto rounded-xl">
        <DialogTitle className="text-center text-base">{t('liveMeeting.room.audio.connectionTitle')}</DialogTitle>
        <DialogDescription className="sr-only">{t('liveMeeting.room.audio.connectionDescription')}</DialogDescription>
        <div role="tablist" aria-label={t('liveMeeting.room.audio.connectionTitle')} className="flex rounded-lg bg-muted p-1">
          {(['computer', 'phone'] as const).map(tab => <button key={tab} type="button" role="tab" aria-selected={connectionTab === tab} aria-controls={`audio-panel-${tab}`} id={`audio-tab-${tab}`} onClick={() => setConnectionTab(tab)} className={cn('flex-1 rounded-md py-1.5 text-sm', connectionTab === tab && 'bg-background shadow-sm')}>{t(`liveMeeting.room.audio.${tab}`)}</button>)}
        </div>
        <div role="tabpanel" id={`audio-panel-${connectionTab}`} aria-labelledby={`audio-tab-${connectionTab}`} className="space-y-5 py-3">
          <p className="text-sm leading-6 text-muted-foreground">{t(connectionTab === 'computer' ? 'liveMeeting.room.audio.computerDescription' : 'liveMeeting.room.audio.phoneUnavailable')}</p>
          {connectionTab === 'computer' && <div className="flex flex-col items-center gap-3">
            <button type="button" disabled={busy || !mediaAvailable} onClick={() => void run(async () => { await connectAudio(); setJoinOpen(false); })} className="flex h-10 w-52 items-center justify-center gap-2 rounded-lg bg-primary text-sm text-primary-foreground disabled:opacity-50">{busy && <Loader2 className="h-4 w-4 animate-spin" />}{t('liveMeeting.room.audio.useComputer')}</button>
            {!mediaAvailable && <p role="status" className="text-xs text-muted-foreground">{t('liveMeeting.room.rtc.connecting')}</p>}
            <button type="button" onClick={openTest} className="text-sm text-primary hover:underline">{t('liveMeeting.room.audio.test')}</button>
          </div>}
        </div>
        {error && <p role="alert" className="text-sm text-destructive">{error}</p>}
        <label className="flex items-center gap-2 text-xs"><input type="checkbox" checked={audioPreferences.autoJoin} onChange={event => setAudioPreferences({ autoJoin: event.target.checked })} />{t('liveMeeting.room.audio.autoJoin')}</label>
      </DialogContent>
    </Dialog>

    <Dialog open={settingsOpen} onOpenChange={setSettingsOpen}>
      <DialogContent className="max-h-[85vh] w-[92vw] max-w-[520px] overflow-y-auto rounded-xl">
        <DialogTitle>{t('liveMeeting.room.audio.settings')}</DialogTitle>
        <DialogDescription>{t('liveMeeting.room.audio.settingsDescription')}</DialogDescription>
        <div className="space-y-5 py-3">
          {deviceSelect('audiooutput')}{deviceSelect('audioinput')}
          {!supportsSpeakerSelection() && <p className="text-xs text-muted-foreground">{t('liveMeeting.room.audio.speakerUnsupported')}</p>}
          <button type="button" disabled={busy} onClick={() => void authorize()} className="text-sm text-primary hover:underline">{t('liveMeeting.room.audio.authorize')}</button>
          <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={audioPreferences.autoJoin} onChange={event => setAudioPreferences({ autoJoin: event.target.checked })} />{t('liveMeeting.room.audio.autoJoin')}</label>
          <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={audioPreferences.unmuteSound} onChange={event => setAudioPreferences({ unmuteSound: event.target.checked })} />{t('liveMeeting.room.audio.unmuteSound')}</label>
          {error && <p role="alert" className="text-sm text-destructive">{error}</p>}
        </div>
        <button type="button" onClick={openTest} className="flex h-10 items-center justify-center gap-2 rounded-lg bg-primary px-4 text-sm text-primary-foreground"><Mic className="h-4 w-4" />{t('liveMeeting.room.audio.test')}</button>
      </DialogContent>
    </Dialog>
    <AudioDiagnostics open={testOpen} onOpenChange={open => { setTestOpen(open); if (!open && !audioConnected) setJoinOpen(true); }} microphoneId={microphoneId} speakerId={speakerId} renderDevices={deviceSelect} onDevicesReady={refresh} />
  </>;
}
