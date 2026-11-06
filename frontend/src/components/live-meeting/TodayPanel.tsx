'use client';

/**
 * Home "Today" panel (V2 design): today's scheduled meetings with derived status
 * badges (ongoing / upcoming / past) and a join action per row. Falls back to the
 * moon-window empty state from the P0 dashboard.
 */
import { useCallback, useEffect, useState } from 'react';
import { Video } from 'lucide-react';
import { useI18n } from '@/i18n';
import { cn } from '@/lib/utils';
import { getLiveMeetingApi } from '@/services/live-meeting';
import { dayRange, deriveScheduledStatus, formatTime } from '@/services/live-meeting/time';
import type { ScheduledMeeting } from '@/services/live-meeting';
import EmptyIllustration from './EmptyIllustration';
import ScheduleDialog from './ScheduleDialog';
import { Dialog, DialogContent, DialogTitle, DialogDescription } from '@/components/ui/dialog';
import { toast } from 'sonner';

interface TodayPanelProps {
  /** Bump to refetch (e.g. after scheduling a meeting). */
  version: number;
  onJoin: (code: string) => void;
}

export default function TodayPanel({ version, onJoin }: TodayPanelProps) {
  const { t, locale } = useI18n();
  const [meetings, setMeetings] = useState<ScheduledMeeting[]>([]);
  const [loading, setLoading] = useState(true);
  const [failed, setFailed] = useState(false);
  const [editing, setEditing] = useState<ScheduledMeeting | null>(null);
  const [cancelling, setCancelling] = useState<ScheduledMeeting | null>(null);
  const [saving, setSaving] = useState(false);
  const [cancelError, setCancelError] = useState<string | null>(null);

  const refetch = useCallback(() => {
    setLoading(true);
    setFailed(false);
    const { from, to } = dayRange();
    getLiveMeetingApi()
      .listScheduledMeetings({ from, to })
      .then(rows => setMeetings(rows.filter(m => !m.cancelled)))
      .catch(() => setFailed(true))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    refetch();
    window.addEventListener('scheduled-meetings-changed', refetch);
    window.addEventListener('focus', refetch);
    const id = window.setInterval(() => { if (document.visibilityState === 'visible') refetch(); }, 30_000);
    return () => {
      window.removeEventListener('scheduled-meetings-changed', refetch);
      window.removeEventListener('focus', refetch);
      window.clearInterval(id);
    };
  }, [refetch, version]);

  const now = new Date();

  return (
    <section className="flex min-h-0 flex-1 flex-col">
      <div className="flex min-h-0 flex-1 flex-col rounded-2xl border border-white/[0.06] bg-white/[0.03] p-1.5 backdrop-blur-md">
        {loading ? (
          <p role="status" className="p-5 text-sm text-muted-foreground">{t('liveMeeting.today.loading')}</p>
        ) : failed ? (
          <div role="alert" className="flex flex-wrap items-center justify-between gap-3 p-5 text-sm">
            <p className="text-destructive">{t('liveMeeting.today.loadFailed')}</p>
            <button type="button" onClick={refetch} className="rounded-lg bg-primary px-3 py-2 text-primary-foreground">{t('liveMeeting.today.retry')}</button>
          </div>
        ) : meetings.length ? (
          <>
            <h2 className="px-4 pb-1 pt-3 text-[13px] font-medium text-foreground/45">
              {t('liveMeeting.today.count', { count: meetings.length })}
            </h2>
            <div className="custom-scrollbar flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto px-2 pb-2">
              {meetings.map((m) => {
                const status = deriveScheduledStatus(m, now);
                const start = new Date(m.startAt);
                const end = new Date(start.getTime() + m.durationMin * 60_000);
                return (
                  <div
                    key={m.id}
                    className="group flex flex-wrap items-center gap-3 rounded-xl border border-white/[0.05] bg-white/[0.03] px-4 py-3 transition-all duration-200 hover:border-white/[0.1] hover:bg-white/[0.06]"
                  >
                    <span
                      className={cn(
                        'h-8 w-1 shrink-0 rounded-full',
                        status === 'ongoing' && 'bg-emerald-400',
                        status === 'upcoming' && 'bg-brand-cyan',
                        status === 'past' && 'bg-white/15',
                      )}
                      aria-hidden="true"
                    />
                    <div className="min-w-0 basis-[calc(100%-1.75rem)] flex-1 sm:basis-0">
                      <p className="truncate text-sm font-medium text-foreground" title={m.title}>
                        {m.title}
                        {m.pwdEnabled && <span className="ml-1.5 text-xs text-muted-foreground">·</span>}
                      </p>
                      <p className="mt-0.5 flex flex-wrap items-center gap-1.5 text-xs text-muted-foreground">
                        <span className="whitespace-nowrap tabular-nums">
                          {formatTime(start, locale)} – {formatTime(end, locale)}
                        </span>
                        <span className="whitespace-nowrap tabular-nums">{m.code.replace(/^(\d{3})(\d{3})$/, '$1 $2')}</span>
                        <span
                          className={cn(
                            'shrink-0 whitespace-nowrap rounded px-1.5 py-0.5 text-[10px] font-medium',
                            status === 'ongoing' && 'bg-emerald-400/15 text-emerald-300',
                            status === 'upcoming' && 'bg-brand-cyan/10 text-brand-cyan',
                            status === 'past' && 'bg-white/[0.06] text-muted-foreground',
                          )}
                        >
                          {t(`liveMeeting.today.${status}`)}
                        </span>
                      </p>
                    </div>
                    {!m.cancelled && (
                      <button
                        type="button"
                        onClick={() => onJoin(m.code)}
                        className={cn(
                          'inline-flex h-8 shrink-0 items-center justify-center gap-1.5 rounded-lg px-3.5 text-xs font-semibold transition-all active:scale-95',
                          status === 'ongoing'
                            ? 'bg-brand-gradient text-white shadow-[0_4px_14px_rgba(59,130,246,0.35)] hover:brightness-110'
                            : 'border border-white/10 bg-white/[0.06] text-foreground/80 hover:bg-white/[0.12] hover:text-white',
                        )}
                      >
                        <Video className="h-3.5 w-3.5" />
                        {t('liveMeeting.today.join')}
                      </button>
                    )}
                    {!m.activeRoomId && <div className="flex shrink-0 gap-2">
                      <button className="rounded-lg px-2 py-2 text-xs hover:bg-white/10" aria-label={t('liveMeeting.upcoming.editMeeting', { title: m.title })} onClick={() => setEditing(m)}>{t('common.actions.edit')}</button>
                      <button className="rounded-lg px-2 py-2 text-xs text-destructive hover:bg-white/10" aria-label={t('liveMeeting.upcoming.cancelMeeting', { title: m.title })} onClick={() => { setCancelError(null); setCancelling(m); }}>{t('liveMeeting.upcoming.cancelAction')}</button>
                    </div>}
                  </div>
                );
              })}
            </div>
          </>
        ) : (
          <div className="flex flex-1 flex-col items-center gap-3 px-4 py-4 text-center sm:flex-row sm:gap-5 sm:px-5 sm:text-left">
            <div className="shrink-0">
              <EmptyIllustration />
            </div>
            <div className="min-w-0">
              <p className="text-sm font-medium text-foreground/70">{t('home.today.emptyTitle')}</p>
              <p className="mt-1.5 text-xs leading-relaxed text-muted-foreground">{t('home.today.emptyDesc')}</p>
            </div>
          </div>
        )}
      </div>
      <ScheduleDialog open={!!editing} meeting={editing} onOpenChange={open => { if (!open) setEditing(null); }} userName={editing?.host.name || ''} />
      <Dialog open={!!cancelling} onOpenChange={open => { if (!open && !saving) setCancelling(null); }}>
        <DialogContent className="max-w-[440px]">
          <DialogTitle>{t('liveMeeting.upcoming.cancelTitle')}</DialogTitle>
          <DialogDescription className="break-words">{t('liveMeeting.upcoming.cancelConfirm', { title: cancelling?.title || '' })}</DialogDescription>
          {cancelError && <p role="alert" className="break-words text-sm text-destructive">{cancelError}</p>}
          <div className="flex flex-wrap justify-end gap-3">
            <button disabled={saving} className="rounded-lg border px-4 py-2" onClick={() => setCancelling(null)}>{t('liveMeeting.upcoming.keepMeeting')}</button>
            <button disabled={saving} className="rounded-lg bg-destructive px-4 py-2 text-white" onClick={async () => {
              if (!cancelling) return; setSaving(true); setCancelError(null);
              try { await getLiveMeetingApi().deleteScheduledMeeting(cancelling.id); setCancelling(null); window.dispatchEvent(new Event('scheduled-meetings-changed')); toast.success(t('liveMeeting.upcoming.cancelled')); }
              catch (error) { setCancelError(error instanceof Error ? error.message : t('liveMeeting.upcoming.cancelFailed')); }
              finally { setSaving(false); }
            }}>{saving ? t('common.actions.saving') : t('liveMeeting.upcoming.cancelAction')}</button>
          </div>
        </DialogContent>
      </Dialog>
    </section>
  );
}
