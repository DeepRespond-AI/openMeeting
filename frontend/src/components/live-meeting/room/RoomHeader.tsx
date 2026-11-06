'use client';

/**
 * Room top bar (V2 design): brand logo, title, clickable meeting code → info &
 * invite popover, encryption badge → encryption popover, elapsed timer.
 * Password state is displayed read-only (runtime editing needs a backend
 * room-update endpoint, plan §8.5).
 */
import { useEffect, useState } from 'react';
import { ArrowLeft, ChevronDown, Copy, Info, Lock, Share } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { copyText } from './VideoGrid';
import { useRoom } from './RoomProvider';
import { formatElapsed } from './Toolbar';

function useElapsed(startedAt: string | null): number {
  const [sec, setSec] = useState(0);
  useEffect(() => {
    if (!startedAt) return;
    const start = new Date(startedAt).getTime();
    const tickFn = () => setSec(Math.max(0, Math.floor((Date.now() - start) / 1000)));
    tickFn();
    const id = window.setInterval(tickFn, 1000);
    return () => window.clearInterval(id);
  }, [startedAt]);
  return sec;
}

function InfoRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="shrink-0 text-white/45">{label}</span>
      {children}
    </div>
  );
}

function SmallCopyButton({ label, onClick }: { label: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="inline-flex shrink-0 items-center gap-1 rounded-md bg-white/10 px-2 py-0.5 text-[11px] text-white/70 transition-colors hover:bg-white/20 hover:text-white"
    >
      <Copy className="h-3 w-3" />
      {label}
    </button>
  );
}

export default function RoomHeader({ onShowInfoDialog }: { onShowInfoDialog: () => void }) {
  const t = useT();
  const router = useRouter();
  const { room, self } = useRoom();
  const sec = useElapsed(room?.startedAt ?? null);

  if (!room || !self) return null;
  const joinLink = `${typeof window !== 'undefined' ? window.location.origin : ''}/room?code=${room.code}`;
  const inviteText = () =>
    `${self.name}邀请您参加深应会议\n会议主题：${room.title}\n会议号：${room.code}\n入会链接：${joinLink}\n`;

  const share = () => {
    const text = inviteText();
    if (typeof navigator !== 'undefined' && 'share' in navigator) {
      try {
        void navigator.share({ title: room.title, text, url: joinLink }).catch(() => {});
        return;
      } catch {
        /* fall through to copy */
      }
    }
    copyText(`${text}\n${joinLink}`, t('liveMeeting.room.info.shareFallback'));
  };

  return (
    <header className="relative z-30 flex min-h-14 shrink-0 items-center justify-between gap-2 border-b border-white/[0.06] bg-[#0E1119]/90 px-3 py-2 backdrop-blur-xl sm:px-5">
      <div className="relative flex min-w-0 flex-1 flex-wrap items-center gap-x-2.5 gap-y-1">
        <button type="button" data-testid="minimize-meeting" onClick={() => router.push('/')} title={t('liveMeeting.room.session.minimizeHint')} aria-label={t('liveMeeting.room.session.minimize')}
          className="flex h-8 shrink-0 items-center gap-1 rounded-lg px-2 text-xs text-muted-foreground hover:bg-accent hover:text-foreground">
          <ArrowLeft className="h-4 w-4" /><span className="hidden sm:inline">{t('liveMeeting.room.session.minimize')}</span>
        </button>
        <BrandLogo size={26} />
        <h1 className="min-w-0 max-w-[min(40vw,26rem)] truncate text-sm font-semibold text-white" title={room.title}>
          {room.title}
        </h1>

        {/* Meeting code → info & invite popover */}
        <Popover>
          <PopoverTrigger asChild>
            <button
              type="button"
              title={t('liveMeeting.room.info.title')}
              className="inline-flex shrink-0 items-center gap-1 rounded-md px-1.5 py-0.5 text-xs tabular-nums text-white/50 transition-colors hover:bg-white/10 hover:text-white/90 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/30"
            >
              {t('liveMeeting.room.codeLabel', { code: room.code })}
              <ChevronDown className="h-3 w-3 text-white/40 transition-transform duration-200" />
            </button>
          </PopoverTrigger>
          <PopoverContent side="bottom" align="start" sideOffset={8} className="w-[332px] rounded-2xl border-white/10 bg-[#151A26]/95 p-0 backdrop-blur-xl">
            <div className="border-b border-white/10 px-4 py-3 text-[13px] font-semibold text-white">
              {t('liveMeeting.room.info.title')}
            </div>
            <div className="space-y-3 px-4 py-3.5 text-[13px]">
              <InfoRow label={t('liveMeeting.room.info.topic')}>
                <span className="min-w-0 truncate text-right text-white/90">{room.title}</span>
              </InfoRow>
              <InfoRow label={t('liveMeeting.room.info.code')}>
                <span className="flex items-center gap-2">
                  <span className="font-mono tabular-nums tracking-[0.15em] text-white">{room.code}</span>
                  <SmallCopyButton label={t('liveMeeting.room.info.copy')} onClick={() => copyText(room.code, t('liveMeeting.room.info.copiedCode'))} />
                </span>
              </InfoRow>
              <InfoRow label={t('liveMeeting.room.info.password')}>
                <span className={cn('text-white/70', room.pwdEnabled && 'text-brand-cyan')}>
                  {room.pwdEnabled ? t('liveMeeting.room.info.pwdOn') : t('liveMeeting.room.info.pwdOff')}
                </span>
              </InfoRow>
              <InfoRow label={t('liveMeeting.room.info.link')}>
                <span className="flex min-w-0 items-center gap-2">
                  <span className="min-w-0 truncate font-mono text-[12px] text-brand-cyan">/room?code={room.code}</span>
                  <SmallCopyButton label={t('liveMeeting.room.info.copy')} onClick={() => copyText(joinLink, t('liveMeeting.room.info.copiedLink'))} />
                </span>
              </InfoRow>
            </div>
            <div className="border-t border-white/10 px-4 py-3">
              <div className="mb-2 text-[11px] text-white/40">{t('liveMeeting.room.info.inviteTitle')}</div>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => copyText(inviteText(), t('liveMeeting.room.info.copiedInvite'))}
                  className="inline-flex h-9 items-center justify-center gap-1.5 rounded-lg bg-brand-gradient text-[13px] font-semibold text-white shadow-[0_4px_12px_rgba(59,130,246,0.4)] transition-all hover:brightness-110 active:scale-[0.97]"
                >
                  <Copy className="h-3.5 w-3.5" />
                  {t('liveMeeting.room.info.copyInvite')}
                </button>
                <button
                  type="button"
                  onClick={share}
                  className="inline-flex h-9 items-center justify-center gap-1.5 rounded-lg border border-white/15 bg-white/[0.06] text-[13px] font-medium text-white/85 transition-colors hover:bg-white/[0.12] hover:text-white"
                >
                  <Share className="h-3.5 w-3.5" />
                  {t('liveMeeting.room.info.share')}
                </button>
              </div>
            </div>
          </PopoverContent>
        </Popover>
      </div>

      <div className="relative flex shrink-0 items-center gap-2">
        {/* Encryption badge → encryption popover */}
        <Popover>
          <PopoverTrigger asChild>
            <button
              type="button"
              title={t('liveMeeting.room.enc.title')}
              aria-label={t('liveMeeting.room.enc.title')}
              className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-2.5 py-1 text-xs text-white/70 transition-colors hover:bg-white/[0.18] hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/30"
            >
              <Lock className="h-3 w-3" />
              <span className="hidden sm:inline">{t('liveMeeting.room.enc.title')}</span>
            </button>
          </PopoverTrigger>
          <PopoverContent side="bottom" align="end" sideOffset={8} className="w-[304px] rounded-2xl border-white/10 bg-[#151A26]/95 p-0 backdrop-blur-xl">
            <div className="border-b border-white/10 px-4 py-3 text-[13px] font-semibold text-white">
              {t('liveMeeting.room.enc.title')}
            </div>
            <div className="flex items-center gap-2.5 border-b border-white/10 px-4 py-3">
              <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/15 text-brand-cyan">
                <Info className="h-4 w-4" />
              </span>
              <div className="min-w-0">
                <div className="text-[13px] text-white">{t('liveMeeting.room.enc.ok')}</div>
                <div className="mt-0.5 text-[11px] text-white/40">{t('liveMeeting.room.enc.okDesc')}</div>
              </div>
            </div>
            <div className="flex items-center justify-between px-4 py-3.5">
              <div className="min-w-0">
                <div className="text-[13px] font-medium text-white">{t('liveMeeting.room.enc.pwd')}</div>
                <div className="mt-0.5 text-[11px] text-white/40">{t('liveMeeting.room.enc.pwdDesc')}</div>
              </div>
              <span
                className={cn(
                  'shrink-0 rounded-full px-2.5 py-1 text-[11px] font-medium',
                  room.pwdEnabled ? 'bg-primary/15 text-brand-cyan' : 'bg-white/[0.07] text-white/45',
                )}
              >
                {room.pwdEnabled ? t('liveMeeting.room.info.pwdOn') : t('liveMeeting.room.info.pwdOff')}
              </span>
            </div>
          </PopoverContent>
        </Popover>

        {/* Elapsed timer */}
        <span className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-2.5 py-1 text-xs tabular-nums text-white/70">
          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="10" />
            <polyline points="12 6 12 12 16 14" />
          </svg>
          {formatElapsed(sec)}
        </span>
      </div>
    </header>
  );
}
