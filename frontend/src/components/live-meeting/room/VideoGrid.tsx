'use client';
import { meetingUi } from '@/config/meeting-ui';

/**
 * Room video grid (V2 design, prototype room.js): adaptive tile layout
 * (column count follows container width, min tile 320 px), avatar placeholder
 * tiles with name/mic bar, speaking glow, hand badge, network badge, hover
 * member menu, single-click fullscreen focus, and the dashed "invite" tile that
 * fills the last incomplete row. While sharing, square participant thumbnails
 * scroll in a left column beside the screen instead of competing for its height.
 */
import { useEffect, useRef, useState } from 'react';
import {
  Info,
  Mic,
  MicOff,
  MonitorUp,
  MoreVertical,
  UserPlus,
  UserRoundCog,
  VideoOff,
  X,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog';
import { useT, t as translate } from '@/i18n';
import { cn } from '@/lib/utils';
import { roomGridLayout } from '@/lib/room-grid-layout';
import type { Participant } from '@/services/live-meeting';
import { useRoom } from './RoomProvider';
import MediaElement from './MediaElement';
import NetworkBadge from './NetworkBadge';
import MicrophoneIndicator from './MicrophoneIndicator';

/** Copy-invite fallback for the invite tile (same text the info card composes). */
export function buildInviteText(title: string, code: string, link: string, hostName: string): string {
  return `${hostName}邀请您参加深应会议\n会议主题：${title}\n会议号：${code}\n入会链接：${link}\n`;
}

export function copyText(text: string, toastMsg: string): void {
  void (async () => {
    try {
      if (!navigator.clipboard?.writeText) throw new Error('Clipboard unavailable');
      await navigator.clipboard.writeText(text);
      toast.success(toastMsg);
    } catch { toast.error(translate('liveMeeting.room.info.copyFailed')); }
  })();
}

const AVATAR_GRADIENTS = [
  'linear-gradient(135deg,#6366f1,#3b82f6)',
  'linear-gradient(135deg,#3b82f6,#22d3ee)',
  'linear-gradient(135deg,#8b5cf6,#6366f1)',
  'linear-gradient(135deg,#22d3ee,#34d399)',
  'linear-gradient(135deg,#f472b6,#a78bfa)',
  'linear-gradient(135deg,#fbbf24,#f97316)',
];

function avatarGradient(id: string): string {
  let h = 0;
  for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) >>> 0;
  return AVATAR_GRADIENTS[h % AVATAR_GRADIENTS.length];
}

export default function VideoGrid() {
  const t = useT();
  const { room, self, activeSpeakerId, isHost, approveHand, setParticipantMuted, removeParticipant, transferHost,mediaState,screenState,audioLevels,audioConnected } = useRoom();
  const gridRef = useRef<HTMLDivElement>(null);
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [focusId, setFocusId] = useState<string | null>(null);
  const [infoMember, setInfoMember] = useState<Participant | null>(null);

  const participants = room?.participants ?? [];
  const hasScreen = meetingUi.screenShare && (screenState.tracks.length > 0 || screenState.status === 'connecting'
    || (screenState.status === 'error' && !!screenState.ownerName));

  useEffect(() => { if (hasScreen) setFocusId(null); }, [hasScreen]);

  // Adaptive column count (ResizeObserver — reacts to window and panel resize).
  useEffect(() => {
    const grid = gridRef.current;
    if (!grid) return;
    const compute = () => {
      setSize(previous => previous.width === grid.clientWidth && previous.height === grid.clientHeight
        ? previous : { width: grid.clientWidth, height: grid.clientHeight });
    };
    compute();
    const ro = new ResizeObserver(compute);
    ro.observe(grid);
    return () => ro.disconnect();
  }, [room?.id, self?.id]);

  if (!room || !self) return null;

  const layout = roomGridLayout(size.width, size.height, participants.length);
  const focused = focusId ? participants.find((p) => p.id === focusId) ?? null : null;
  const joinLink = `${typeof window !== 'undefined' ? window.location.origin : ''}/room?code=${room.code}`;

  const inviteText = () => buildInviteText(room.title, room.code, joinLink, self.name);

  const tile = (p: Participant, big = false, compact = false) => {
    const camera=meetingUi.video && p.camOn?mediaState.tracks.find(track=>track.kind==='video' &&
      ((track.local&&p.isSelf)||(!track.local&&p.userId===track.username))):undefined;
    const sharing = meetingUi.screenShare && p.isSelf && p.screenSharing;
    const speaking = meetingUi.audio && !sharing && p.micOn && activeSpeakerId === p.id && focusId == null;
    const hand = meetingUi.handRaise && p.handRaised;
    const network=p.userId?mediaState.network?.[p.userId]:undefined;
    const label = p.isSelf ? t('liveMeeting.room.tile.me') : p.name;
    return (
      <div
        key={p.id}
        data-testid="participant-tile"
        data-participant-id={p.id}
        role="button"
        tabIndex={0}
        onClick={() => compact ? setInfoMember(p) : setFocusId((cur) => (cur === p.id ? null : p.id))}
        onKeyDown={(e) => {
          if (e.target !== e.currentTarget || (e.key !== 'Enter' && e.key !== ' ')) return;
          e.preventDefault();
          if (compact) setInfoMember(p);
          else setFocusId((cur) => (cur === p.id ? null : p.id));
        }}
        aria-label={p.isSelf ? t('liveMeeting.room.tile.me') : p.name}
        className={cn(
          'group relative flex min-h-0 min-w-0 w-full cursor-pointer flex-col items-center justify-center overflow-hidden rounded-xl transition-colors',
          big ? 'h-full' : '',
          compact && 'aspect-square shrink-0',
          sharing && 'bg-[#16233D] ring-2 ring-[#3B82F6]',
          !sharing && speaking && 'bg-gradient-to-b from-[#222B3D] to-[#181D28] ring-2 ring-[#4ADE80]/70 shadow-[0_0_16px_rgba(74,222,128,0.18)]',
          !sharing && !speaking && 'bg-gradient-to-b from-[#1C2029] to-[#14171F] ring-1 ring-white/[0.06] hover:ring-white/20',
        )}
      >
        {/* Center: sharing notice / camera-off placeholder / avatar */}
        {camera ? <MediaElement item={camera} /> : sharing && !compact ? (
          <div className="flex flex-col items-center gap-2 text-[#8AB4F8]">
            <MonitorUp className="h-9 w-9" />
            <span className="text-xs font-medium text-foreground/80">{t('liveMeeting.room.tile.sharing')}</span>
          </div>
        ) : !compact && meetingUi.video && !p.camOn && p.isSelf ? (
          <div className="flex flex-col items-center gap-2 text-white/40">
            <VideoOff className="h-8 w-8" />
            <span className="text-xs">{t('liveMeeting.room.tile.camOff')}</span>
          </div>
        ) : (
          <span
            className={cn('flex select-none items-center justify-center rounded-full font-semibold text-white shadow-md',
              compact ? 'h-8 w-8 text-sm sm:h-10 sm:w-10 sm:text-base' : 'h-14 w-14 text-lg')}
            style={{ background: avatarGradient(p.id) }}
          >
            {label.charAt(0)}
          </span>
        )}

        {/* Hand badge */}
        {hand && (
          <span
            className={cn('absolute flex items-center justify-center rounded-md bg-warning/90 text-[13px] shadow-md',
              compact ? 'bottom-6 right-1 h-5 w-5' : 'left-9 top-2 h-6 w-6')}
            title={t('liveMeeting.room.tile.hand')}
          >
            ✋
          </span>
        )}

        {/* Hover menu */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <button
              type="button"
              aria-label={t('liveMeeting.room.tile.menu')}
              onClick={(e) => e.stopPropagation()}
              className={cn('absolute flex items-center justify-center rounded-md bg-black/45 text-white/80 backdrop-blur-sm transition-opacity hover:bg-black/70 hover:text-white focus-visible:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/40 group-hover:opacity-100',
                compact ? 'right-1 top-1 h-6 w-6 opacity-100 sm:opacity-0' : 'right-2 top-2 h-7 w-7 opacity-0')}
            >
              <MoreVertical className="h-4 w-4" />
            </button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" onClick={(e) => e.stopPropagation()}>
            {!compact && <DropdownMenuItem onClick={() => setFocusId((cur) => (cur === p.id ? null : p.id))}>
              <MonitorUp className="mr-2 h-4 w-4" />
              {focusId === p.id ? t('liveMeeting.room.tile.restore') : t('liveMeeting.room.memberMenu.setFocus')}
            </DropdownMenuItem>}
            <DropdownMenuItem onClick={() => setInfoMember(p)}>
              <Info className="mr-2 h-4 w-4" />
              {t('liveMeeting.room.memberMenu.viewInfo')}
            </DropdownMenuItem>
            {meetingUi.audio && isHost && !p.isSelf && (
              <DropdownMenuItem onClick={() => { void setParticipantMuted(p.id, p.micOn).then((ok) => { if (ok) toast(p.micOn ? t('liveMeeting.room.memberMenu.mutedToast', { name: p.name }) : t('liveMeeting.room.memberMenu.unmutedToast', { name: p.name })); }); }}>
                {p.micOn ? <MicOff className="mr-2 h-4 w-4" /> : <Mic className="mr-2 h-4 w-4" />}
                {p.micOn ? t('liveMeeting.room.memberMenu.mute', { name: p.name }) : t('liveMeeting.room.memberMenu.unmute')}
              </DropdownMenuItem>
            )}
            {isHost && !p.isSelf && (
              <>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={() => { void removeParticipant(p.id).then((ok) => { if (ok) toast.success(t('liveMeeting.room.memberMenu.removedToast', { name: p.name })); }); }}>
                  <X className="mr-2 h-4 w-4" />
                  {t('liveMeeting.room.memberMenu.remove')}
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => { void transferHost(p.id).then((ok) => { if (ok) toast.success(t('liveMeeting.room.memberMenu.transferredToast', { name: p.name })); }); }}>
                  <UserRoundCog className="mr-2 h-4 w-4" />
                  {t('liveMeeting.room.memberMenu.transfer')}
                </DropdownMenuItem>
              </>
            )}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Network badge */}
        <NetworkBadge sample={network} local={p.isSelf} connected={mediaState.status==='connected'}/>

        {/* Name bar */}
        <div className={cn('absolute flex items-center rounded-md bg-black/45 backdrop-blur-sm',
          compact ? 'bottom-1 left-1 right-1 gap-1 px-1 py-0.5' : 'bottom-2 left-2 max-w-[85%] gap-1.5 px-2 py-1')}>
          <span title={label} className={cn('truncate font-medium text-white/90', compact ? 'min-w-0 flex-1 text-[10px] sm:text-xs' : 'text-xs')}>{label}</span>
          {meetingUi.audio && <MicrophoneIndicator muted={!p.micOn || !!p.mutedByHost} level={audioLevels[p.id]} iconClassName="h-3 w-3" />}
        </div>
      </div>
    );
  };

  const inviteTile = (
    <button
      type="button"
      data-testid="invite-tile"
      style={{ gridColumn: `span ${layout.inviteSpan || 1}` }}
      title={t('liveMeeting.room.tile.invite')}
      onClick={() => copyText(inviteText(), t('liveMeeting.room.info.copiedInvite'))}
      className="flex h-full min-h-0 w-full flex-col items-center justify-center gap-2 rounded-xl border-2 border-dashed border-white/10 text-white/35 transition-colors hover:border-[#3B82F6]/50 hover:bg-white/[0.03] hover:text-white/70"
    >
      <UserPlus className="h-6 w-6" />
      <span className="text-xs font-medium">{t('liveMeeting.room.tile.invite')}</span>
    </button>
  );

  return (
    <div data-layout={hasScreen ? 'screen-share' : 'gallery'} className={cn('relative flex h-full min-h-0 min-w-0 w-full',
      hasScreen ? 'flex-row gap-2 sm:gap-3' : 'flex-col gap-3')}>
      <div ref={gridRef} data-testid="video-stage" className={cn('relative min-h-0 min-w-0 overflow-y-auto overscroll-contain p-0.5',
        hasScreen ? 'custom-scrollbar w-20 flex-none sm:w-28 lg:w-32' : 'flex-1')}>
      <div className="absolute left-2 top-2 z-10 flex flex-wrap gap-2">
        {meetingUi.audio && mediaState.tracks.filter(track=>track.kind==='audio'&&!track.local).map(track=>
          <MediaElement key={track.key} item={track} muted={!audioConnected || !mediaState.speakerEnabled} speakerId={mediaState.speakerDeviceId} />)}
      </div>
      {focused && !hasScreen ? (
        <div className="relative grid h-full w-full">
          {tile(focused, true)}
          <button
            type="button"
            onClick={(e) => { e.stopPropagation(); setFocusId(null); toast(t('liveMeeting.room.toasts.backToGrid')); }}
            className="absolute left-4 top-3 z-10 flex h-8 items-center gap-1.5 rounded-lg bg-black/55 px-3 text-xs font-medium text-white/85 backdrop-blur-sm transition-colors hover:bg-black/75 hover:text-white"
          >
            {t('liveMeeting.room.tile.restore')}
          </button>
        </div>
      ) : (
        <div
          data-testid="participant-grid"
          data-columns={hasScreen ? 1 : layout.columns}
          data-rows={hasScreen ? participants.length : layout.rows}
          className={cn('relative w-full', hasScreen ? 'flex flex-col gap-2' : 'grid min-h-full gap-3')}
          style={hasScreen ? undefined : {
            gridTemplateColumns: `repeat(${layout.columns}, minmax(0, 1fr))`,
            gridTemplateRows: `repeat(${layout.rows}, minmax(${layout.minHeight}px, 1fr))`,
            height: layout.scroll ? 'auto' : '100%',
          }}
        >
          {participants.map((p) => tile(p, false, hasScreen))}
          {!hasScreen && layout.inviteSpan > 0 && inviteTile}
        </div>
      )}

      </div>
      {hasScreen && <section data-testid="screen-stage" aria-label={t('liveMeeting.room.screen.stage')}
        className="relative min-h-0 min-w-0 flex-1 overflow-hidden rounded-xl border border-primary/40 bg-black">
        {screenState.tracks[0] ? <MediaElement item={screenState.tracks[0]} /> : <div className="flex h-full items-center justify-center px-3 text-center text-sm text-muted-foreground">{t('liveMeeting.room.screen.connecting')}</div>}
        <div className="absolute bottom-2 left-2 right-2 rounded bg-black/70 px-3 py-1.5 text-xs text-white">
          <p className="truncate">{screenState.status === 'sharing' ? t('liveMeeting.room.screen.yours') : screenState.ownerName}</p>
          {screenState.status === 'sharing' && <p>{t('liveMeeting.room.screen.published')}</p>}
        </div>
      </section>}
      {/* Member info dialog */}
      <Dialog open={!!infoMember} onOpenChange={(open) => { if (!open) setInfoMember(null); }}>
        <DialogContent className="max-w-[360px] rounded-xl border-white/10 bg-[#151A26]/95">
          <DialogTitle className="text-base font-semibold text-foreground">{t('liveMeeting.room.memberMenu.viewInfo')}</DialogTitle>
          {infoMember && (
            <div className="mt-2 divide-y rounded-lg border border-white/10 bg-white/[0.04] px-4 text-sm">
              <div className="flex items-center justify-between gap-4 py-2.5">
                <span className="shrink-0 text-muted-foreground">{t('liveMeeting.join.nickname')}</span>
                <span className="min-w-0 truncate text-right text-foreground">
                  {infoMember.isSelf ? `${t('liveMeeting.room.tile.me')}（${infoMember.name}）` : infoMember.name}
                </span>
              </div>
              {meetingUi.audio && <div className="flex items-center justify-between gap-4 py-2.5">
                <span className="shrink-0 text-muted-foreground">{t('liveMeeting.join.micOn')}</span>
                <span className="text-foreground">{infoMember.micOn ? t('liveMeeting.room.memberMenu.micOn') : t('liveMeeting.room.memberMenu.micOff')}</span>
              </div>}
              <div className="flex items-center justify-between gap-4 py-2.5">
                <span className="shrink-0 text-muted-foreground">{t('liveMeeting.room.member.host')}</span>
                <span className="text-foreground">{infoMember.isHost ? t('liveMeeting.room.member.host') : t('liveMeeting.room.memberMenu.roleMember')}</span>
              </div>
            </div>
          )}
          <div className="mt-3 flex justify-end">
            <button
              type="button"
              onClick={() => setInfoMember(null)}
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
