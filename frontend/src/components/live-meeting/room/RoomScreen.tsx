'use client';
import { meetingUi } from '@/config/meeting-ui';
import ImInvite from './ImInvite';

/**
 * Full-screen immersive room (V2 design): header, adaptive video grid, bottom
 * capsule toolbar, right slide-out panel, and the joining / waiting-room /
 * error overlays. Rendered without the app NavRail (see layout.tsx).
 */
import { useState } from 'react';
import { AlertCircle, ArrowLeft } from 'lucide-react';
import { useT } from '@/i18n';
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog';
import { useRoom } from './RoomProvider';
import RoomHeader from './RoomHeader';
import VideoGrid from './VideoGrid';
import Toolbar from './Toolbar';
import SidePanel from './SidePanel';
import RecordingBanner from './RecordingBanner';

function FullCenter({ children }: { children: React.ReactNode }) {
  return (
    <div className="absolute inset-0 z-40 flex flex-col items-center justify-center gap-3 bg-[#0B0D13] text-sm text-muted-foreground">
      {children}
    </div>
  );
}

function WaitingOverlay() {
  const t = useT();
  const { self, room, leave } = useRoom();
  return (
    <div className="absolute inset-0 z-50 flex flex-col items-center justify-center bg-[#0B0D13]/[0.98] backdrop-blur-md">
      <div className="relative mb-7">
        <span className="absolute inset-0 animate-ping rounded-full bg-[#3B82F6]/40" aria-hidden="true" />
        <span
          className="relative flex h-20 w-20 select-none items-center justify-center rounded-full bg-brand-gradient text-2xl font-bold text-white shadow-[0_12px_36px_rgba(59,130,246,0.4)]"
        >
          {(self?.name ?? 'Me').charAt(0)}
        </span>
      </div>
      <h2 className="text-lg font-semibold text-white">{t('liveMeeting.room.waitingRoom.overlayTitle')}</h2>
      <p className="mt-2 animate-pulse text-sm text-white/50">{t('liveMeeting.room.waitingRoom.overlayDesc')}</p>
      <p className="mt-1.5 text-xs tabular-nums text-white/30">
        {t('liveMeeting.room.codeLabel', { code: room?.code ?? '' })}
      </p>
      <button
        type="button"
        onClick={() => void leave()}
        className="mt-9 flex h-10 items-center rounded-full border border-white/15 px-9 text-sm font-medium text-white/80 transition-colors hover:bg-white/10 hover:text-white"
      >
        {t('liveMeeting.room.waitingRoom.overlayCancel')}
      </button>
    </div>
  );
}

export default function RoomScreen() {
  const t = useT();
  const { phase, room, errorText, backHome, mediaAvailable, connectionState,mediaState,mediaDeviceError,retryMedia,mediaRecovering,mediaRecoveryError,retryScreen,screenState,panelTab,setPanelTab,entryStatus,retryEntry,cancelEntry } = useRoom();
  const [infoDialogOpen, setInfoDialogOpen] = useState(false);

  // SessionView redirects completed sessions home without an intermediate page.
  if (phase === 'ended') return null;

  // The persistent entry overlay owns the spinner, including the route handoff.
  // Keep the interactive room out of the tree until its initial connections settle.
  if (phase === 'joining' || (phase === 'joined' && entryStatus === 'loading')) {
    return <div data-testid="meeting-room" aria-busy="true" className="relative h-dvh bg-[#0B0D13]" />;
  }
  if (phase === 'joined' && entryStatus === 'error') {
    return <div data-testid="meeting-entry-error" className="relative h-dvh bg-[#0B0D13]">
      <FullCenter>
        <AlertCircle className="h-8 w-8 text-[#F87171]" />
        <p role="alert" className="max-w-sm px-4 text-center">{mediaRecoveryError || t(mediaState.reason === 'joinedOnOtherDevice' ? 'liveMeeting.room.rtc.joinedOnOtherDevice' : mediaState.reason==='sessionReleaseTimeout' ? 'liveMeeting.room.rtc.sessionReleaseTimeout' : 'home.quick.connectionFailed')}</p>
        {mediaState.reason === 'joinedOnOtherDevice' && <p className="max-w-sm px-4 text-center text-xs">{t('home.quick.otherDeviceHint')}</p>}
        <div className="flex flex-wrap justify-center gap-3 px-4">
          <button type="button" disabled={mediaRecovering} onClick={retryEntry} className="rounded-lg bg-primary px-4 py-2 text-primary-foreground disabled:opacity-50">{t(mediaState.releasingSessionId?'liveMeeting.room.rtc.releaseAndRetry':'liveMeeting.today.retry')}</button>
          <button type="button" onClick={cancelEntry} className="rounded-lg border border-white/15 px-4 py-2">{t('home.quick.cancelEntry')}</button>
        </div>
      </FullCenter>
    </div>;
  }

  return (
    <div data-testid="meeting-room" className="relative flex h-dvh min-h-0 min-w-0 flex-col overflow-hidden bg-[#0B0D13] text-white">
      <RoomHeader onShowInfoDialog={() => setInfoDialogOpen(true)} />
      {meetingUi.screenShare&&phase==='joined'&&(screenState.status==='choosing'||screenState.reason)&&<div role="status" data-testid="screen-status"
        className="mx-4 rounded-lg bg-primary/15 px-3 py-2 text-center text-xs text-foreground">
        {t(`liveMeeting.room.screen.${screenState.status==='choosing'?'choosing':screenState.reason}` as 'liveMeeting.room.screen.choosing')}
        {screenState.reason === 'network' && screenState.ownerName && <button type="button" onClick={retryScreen} className="ml-2 rounded-lg bg-primary px-3 py-1 text-primary-foreground">{t('liveMeeting.room.screen.retry')}</button>}
      </div>}
      {meetingUi.recording && <RecordingBanner />}
      {(meetingUi.audio || meetingUi.video) && (!mediaAvailable || mediaDeviceError || mediaState.reason==='restored') && phase === 'joined' && (
        <div role="status" data-testid="media-status" className="mx-4 flex shrink-0 flex-wrap items-center justify-center gap-2 rounded-lg bg-primary/10 px-3 py-2 text-center text-xs text-muted-foreground">
          <span>{mediaRecovering ? t('liveMeeting.room.rtc.releasing') : mediaRecoveryError || t(`liveMeeting.room.rtc.${mediaDeviceError?'permissionDenied':mediaState.reason==='sessionReleasing'?'sessionReleasing':mediaState.status==='connecting'||mediaState.status==='idle'?'connecting':mediaState.reason||'unavailable'}` as 'liveMeeting.room.rtc.unavailable')}</span>
          {(mediaRecovering||mediaState.status!=='connecting')&&mediaState.reason!=='restored'&&<button type="button" disabled={mediaRecovering} className="rounded bg-primary px-2 py-1 text-white disabled:opacity-50" onClick={()=>void retryMedia()}>{t(mediaRecovering?'liveMeeting.room.rtc.releasing':mediaState.releasingSessionId?'liveMeeting.room.rtc.releaseAndRetry':'liveMeeting.room.rtc.retry')}</button>}
        </div>
      )}
      {connectionState === 'reconnecting' && phase === 'joined' && (
        <p role="status" className="px-4 py-1 text-center text-xs text-warning">{t('liveMeeting.room.reconnecting')}</p>
      )}

      <div className="relative flex min-h-0 min-w-0 flex-1 overflow-hidden">
      <div className="flex min-h-0 min-w-0 flex-1 flex-col">
      <div className="flex min-h-0 min-w-0 flex-1 justify-center p-2 sm:p-4">
        <div className="h-full min-h-0 min-w-0 w-full">
          <VideoGrid />
        </div>
      </div>

      <div data-testid="room-toolbar-region" className="flex shrink-0 justify-center px-2 pb-3 pt-1 sm:px-4 sm:pb-4">
        <Toolbar onShowInfo={() => setInfoDialogOpen(true)} />
      </div>

      </div>
      {panelTab && <button type="button" aria-label={t('common.actions.close')} data-testid="room-panel-backdrop" onClick={() => setPanelTab(null)} className="absolute inset-0 z-20 bg-black/50 lg:hidden" />}
      <SidePanel />
      </div>

      {phase === 'waiting' && <WaitingOverlay />}

      {phase === 'error' && (
        <FullCenter>
          <div className="flex flex-col items-center gap-4 rounded-2xl border border-white/10 bg-white/[0.04] px-10 py-8 backdrop-blur-md">
            <AlertCircle className="h-8 w-8 text-[#F87171]" />
            <p className="text-sm text-foreground/80">{errorText ?? t('liveMeeting.join.errGeneric')}</p>
            <button
              type="button"
              onClick={backHome}
              className="inline-flex h-10 items-center gap-2 rounded-full border border-white/15 px-6 text-sm font-medium text-white/80 transition-colors hover:bg-white/10 hover:text-white"
            >
              <ArrowLeft className="h-4 w-4" />
              {t('common.actions.back')}
            </button>
          </div>
        </FullCenter>
      )}

      {/* Meeting info dialog (from the "more" menu) */}
      <Dialog open={infoDialogOpen} onOpenChange={setInfoDialogOpen}>
        <DialogContent className="max-w-[380px] rounded-xl border-white/10 bg-[#151A26]/95">
          <DialogTitle className="text-base font-semibold text-foreground">{t('liveMeeting.room.info.title')}</DialogTitle>
          {room && (
            <div className="mt-2 divide-y rounded-lg border border-white/10 bg-white/[0.04] px-4 text-sm">
              <div className="flex items-center justify-between gap-4 py-2.5">
                <span className="shrink-0 text-muted-foreground">{t('liveMeeting.room.info.topic')}</span>
                <span className="min-w-0 truncate text-right text-foreground">{room.title}</span>
              </div>
              <div className="flex items-center justify-between gap-4 py-2.5">
                <span className="shrink-0 text-muted-foreground">{t('liveMeeting.room.info.code')}</span>
                <span className="font-mono tabular-nums text-foreground">{room.code}</span>
              </div>
              <div className="flex items-center justify-between gap-4 py-2.5">
                <span className="shrink-0 text-muted-foreground">{t('liveMeeting.room.info.password')}</span>
                <span className="text-foreground">{room.pwdEnabled ? t('liveMeeting.room.info.pwdOn') : t('liveMeeting.room.info.pwdOff')}</span>
              </div>
            </div>
          )}
          {room && <ImInvite code={room.code} title={room.title} />}
          <div className="mt-3 flex justify-end">
            <button
              type="button"
              onClick={() => setInfoDialogOpen(false)}
              className="inline-flex h-9 items-center justify-center rounded-lg bg-primary px-4 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-primary/90"
            >
              {t('common.actions.close')}
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
