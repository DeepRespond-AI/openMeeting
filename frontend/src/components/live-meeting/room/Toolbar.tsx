'use client';

/**
 * Bottom capsule toolbar (V2 design): mic / camera (red when off), share (blue when
 * on), chat + members with badges, "more" menu (hand / meeting info / settings),
 * and leave — hosts get "leave & end" with a confirm dialog, members leave directly.
 */
import { useState } from 'react';
import {
  Hand,
  Info,
  MessageSquare,
  MonitorUp,
  MoreHorizontal,
  Settings,
  Users,
  Video,
  VideoOff,
  LogOut,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { useRoom } from './RoomProvider';
import RoomSettings from './RoomSettings';
import AudioControls from './AudioControls';
import { meetingUi } from '@/config/meeting-ui';

export function formatElapsed(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  const mm = String(m).padStart(2, '0');
  const ss = String(s).padStart(2, '0');
  return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`;
}

function ToolButton({
  icon: Icon,
  label,
  active,
  tone = 'plain',
  badge,
  onClick,
  children,
}: {
  icon: React.ElementType;
  label: string;
  active?: boolean;
  tone?: 'plain' | 'toggle' | 'share';
  badge?: number;
  onClick: () => void;
  children?: React.ReactNode;
}) {
  return (
    <button
      type="button"
      aria-pressed={!!active}
      title={label}
      aria-label={label}
      onClick={onClick}
      className={cn(
        'relative flex h-11 w-11 shrink-0 flex-col items-center justify-center gap-0.5 rounded-full text-white transition-colors sm:h-12 sm:w-12',
        tone === 'toggle' && (active ? 'bg-white/10 hover:bg-white/20' : 'bg-[#DC3B3B] hover:bg-[#C23232]'),
        tone === 'share' && (active ? 'bg-[#0052D9] hover:bg-[#1C66E5]' : 'bg-white/10 hover:bg-white/20'),
        tone === 'plain' && (active ? 'bg-white/20' : 'bg-white/10 hover:bg-white/20'),
      )}
    >
      {children ?? <Icon className="h-[18px] w-[18px]" />}
      <span className="text-[9px] leading-none text-white/80">{label}</span>
      {!!badge && badge > 0 && (
        <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-[#DC3B3B] px-1 text-[9px] font-semibold text-white ring-2 ring-[#151A26]">
          {badge > 99 ? '99+' : badge}
        </span>
      )}
    </button>
  );
}

export default function Toolbar({ onShowInfo }: { onShowInfo: () => void }) {
  const t = useT();
  const {
    room, self, isHost, panelTab, chatUnread,screenState,
    toggleCam, toggleHand, toggleShare, setPanelTab, leave, end,
  } = useRoom();
  const [endConfirm, setEndConfirm] = useState(false);
  const [settingsOpen, setSettingsOpen] = useState(false);

  if (!room || !self) return null;
  const waitingCount = room.waiting.length;

  const handleLeave = () => {
    if (isHost) setEndConfirm(true);
    else void leave();
  };

  const handleEnd = async () => {
    try {
    await end();
    toast.success(t('liveMeeting.room.toasts.ended'));
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t('liveMeeting.room.errors.generic'));
    }
  };

  return (
    <>
      <div className="flex max-w-full flex-wrap items-center justify-center gap-1 rounded-2xl border border-white/10 bg-[#151A26]/80 px-2 py-2 shadow-[0_16px_44px_rgba(0,0,0,0.55)] backdrop-blur-xl sm:gap-1.5 sm:rounded-full sm:px-3">
        {meetingUi.audio && <AudioControls />}
        {meetingUi.video && <ToolButton
          icon={self.camOn ? Video : VideoOff}
          label={self.camOn ? t('liveMeeting.room.toolbar.cam') : t('liveMeeting.room.toolbar.camOff')}
          tone="toggle"
          active={self.camOn}
          onClick={toggleCam}
        />}
        {meetingUi.screenShare && <ToolButton
          icon={MonitorUp}
          label={screenState.status==='choosing'?t('liveMeeting.room.screen.cancel'):screenState.status==='sharing'||self.screenSharing?t('liveMeeting.room.screen.stop'):t('liveMeeting.room.toolbar.share')}
          tone="share"
          active={screenState.status==='sharing'||self.screenSharing}
          onClick={toggleShare}
        />}
        {meetingUi.chat && <ToolButton
          icon={MessageSquare}
          label={t('liveMeeting.room.toolbar.chat')}
          badge={chatUnread}
          active={panelTab === 'chat'}
          onClick={() => setPanelTab(panelTab === 'chat' ? null : 'chat')}
        />}
        {meetingUi.members && <ToolButton
          icon={Users}
          label={t('liveMeeting.room.toolbar.members')}
          badge={waitingCount}
          active={panelTab === 'members'}
          onClick={() => setPanelTab(panelTab === 'members' ? null : 'members')}
        />}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <div>
              <ToolButton icon={MoreHorizontal} label={t('liveMeeting.room.toolbar.more')} onClick={() => {}} />
            </div>
          </DropdownMenuTrigger>
          <DropdownMenuContent side="top" align="start" className="mb-1 border-white/10 bg-[#151A26]/95">
            {meetingUi.handRaise && !isHost && <DropdownMenuItem onClick={toggleHand}>
              <Hand className="mr-2 h-4 w-4" />
              {self.handRaised ? t('liveMeeting.room.hand.lower') : t('liveMeeting.room.hand.raise')}
            </DropdownMenuItem>}
            <DropdownMenuItem onClick={onShowInfo}>
              <Info className="mr-2 h-4 w-4" />
              {t('liveMeeting.room.info.title')}
            </DropdownMenuItem>
            {meetingUi.settings && <DropdownMenuItem onClick={() => setSettingsOpen(true)}>
              <Settings className="mr-2 h-4 w-4" />
              {t('liveMeeting.room.memberMenu.settings')}
            </DropdownMenuItem>}
          </DropdownMenuContent>
        </DropdownMenu>
        <div className="mx-1 h-8 w-px bg-white/15" aria-hidden="true" />
        <button
          type="button"
          onClick={handleLeave}
          className={cn(
            'flex h-11 shrink-0 items-center justify-center gap-2 rounded-full px-3 text-xs font-semibold text-white transition-colors sm:h-12 sm:px-5 sm:text-sm',
            isHost ? 'bg-[#B91C1C] hover:bg-[#991B1B]' : 'bg-[#DC3B3B] hover:bg-[#C23232]',
          )}
        >
          <LogOut className="h-[18px] w-[18px]" />
          {isHost ? t('liveMeeting.room.toolbar.end') : t('liveMeeting.room.toolbar.leave')}
        </button>
      </div>

      {/* Host: end-for-everyone confirmation */}
      {meetingUi.settings && <RoomSettings open={settingsOpen} onOpenChange={setSettingsOpen} />}
      <Dialog open={endConfirm} onOpenChange={setEndConfirm}>
        <DialogContent className="max-w-[380px] rounded-xl border-white/10 bg-[#151A26]/95">
          <DialogTitle className="text-base font-semibold text-foreground">{t('liveMeeting.room.endConfirm.title')}</DialogTitle>
          <DialogDescription className="text-sm text-muted-foreground">{t('liveMeeting.room.endConfirm.desc')}</DialogDescription>
          <div className="mt-2 flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setEndConfirm(false)}
              className="inline-flex h-9 items-center justify-center rounded-lg border border-white/10 bg-white/[0.06] px-4 text-sm font-medium text-foreground/80 transition-colors hover:bg-white/[0.12] hover:text-white"
            >
              {t('liveMeeting.room.endConfirm.leaveOnly')}
            </button>
            <button
              type="button"
              onClick={() => { setEndConfirm(false); void handleEnd(); }}
              className="inline-flex h-9 items-center justify-center rounded-lg bg-[#DC3B3B] px-4 text-sm font-semibold text-white transition-colors hover:bg-[#C23232]"
            >
              {t('liveMeeting.room.endConfirm.end')}
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
