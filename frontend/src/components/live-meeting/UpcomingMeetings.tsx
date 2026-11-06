'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { CalendarDays, Loader2, MoreHorizontal, Plus, Search, Video, X } from 'lucide-react';
import { toast } from 'sonner';
import { useI18n } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { getLiveMeetingApi, type ScheduledMeeting } from '@/services/live-meeting';
import { formatTime } from '@/services/live-meeting/time';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import JoinDialog from './JoinDialog';
import ScheduleDialog from './ScheduleDialog';

/** Reservations remain reusable until cancellation, independent of past scenes. */
export default function UpcomingMeetings() {
  const { t, locale } = useI18n();
  const { user } = useServer();
  const [meetings, setMeetings] = useState<ScheduledMeeting[]>([]);
  const [loading, setLoading] = useState(true);
  const [failed, setFailed] = useState(false);
  const [now, setNow] = useState(Date.now);
  const [search, setSearch] = useState('');
  const [joinCode, setJoinCode] = useState<string | null>(null);
  const [scheduleOpen, setScheduleOpen] = useState(false);
  const [editing, setEditing] = useState<ScheduledMeeting | null>(null);
  const [cancelling, setCancelling] = useState<ScheduledMeeting | null>(null);
  const [saving, setSaving] = useState(false);
  const [cancelError, setCancelError] = useState<string | null>(null);
  const requestVersion = useRef(0);

  const refetch = useCallback(async () => {
    const version = ++requestVersion.current;
    setLoading(true);
    setFailed(false);
    try {
      const rows = await getLiveMeetingApi().listScheduledMeetings({});
      if (version !== requestVersion.current) return;
      setMeetings(rows);
      setNow(Date.now());
    } catch {
      if (version === requestVersion.current) setFailed(true);
    } finally {
      if (version === requestVersion.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    const refresh = () => { void refetch(); };
    refresh();
    window.addEventListener('scheduled-meetings-changed', refresh);
    window.addEventListener('focus', refresh);
    const timer = window.setInterval(() => { if (document.visibilityState === 'visible') refresh(); }, 30_000);
    return () => {
      requestVersion.current++;
      window.clearInterval(timer);
      window.removeEventListener('scheduled-meetings-changed', refresh);
      window.removeEventListener('focus', refresh);
    };
  }, [refetch]);

  const upcoming = useMemo(() => meetings
    .filter(m => !m.cancelled)
    .sort((a, b) => Date.parse(a.startAt) - Date.parse(b.startAt)), [meetings, now]);
  const groups = useMemo(() => {
    const query = search.trim().toLocaleLowerCase(locale).replace(/\s/g, '');
    const result = new Map<string, { date: Date; meetings: ScheduledMeeting[] }>();
    for (const meeting of upcoming) {
      if (query && ![meeting.title, meeting.code, meeting.host.name]
        .some(value => value.toLocaleLowerCase(locale).replace(/\s/g, '').includes(query))) continue;
      const date = new Date(meeting.startAt), key = date.toDateString();
      if (!result.has(key)) result.set(key, { date, meetings: [] });
      result.get(key)!.meetings.push(meeting);
    }
    return [...result.entries()];
  }, [upcoming, search, locale]);

  const dateLabel = (date: Date) => {
    const today = new Date(now), tomorrow = new Date(now);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const label = new Intl.DateTimeFormat(locale, { year: 'numeric', month: 'long', day: 'numeric', weekday: 'short' }).format(date);
    return date.toDateString() === today.toDateString() ? t('liveMeeting.upcoming.today', { date: label })
      : date.toDateString() === tomorrow.toDateString() ? t('liveMeeting.upcoming.tomorrow', { date: label }) : label;
  };

  const cancelMeeting = async () => {
    if (!cancelling || saving) return;
    setSaving(true);
    setCancelError(null);
    try {
      await getLiveMeetingApi().deleteScheduledMeeting(cancelling.id);
      setCancelling(null);
      window.dispatchEvent(new Event('scheduled-meetings-changed'));
      toast.success(t('liveMeeting.upcoming.cancelled'));
    } catch (error) {
      setCancelError(error instanceof Error ? error.message : t('liveMeeting.upcoming.cancelFailed'));
    } finally { setSaving(false); }
  };

  return <div className="flex h-full min-h-0 flex-col bg-background">
    <div className="shrink-0 border-b border-border">
      <div className="mx-auto flex max-w-5xl flex-wrap items-end justify-between gap-4 px-6 py-5">
        <div className="min-w-0">
          <h1 className="flex items-center gap-2 text-xl font-semibold text-foreground">
            {t('nav.meetings.upcomingTab')}
            {!loading && !failed && upcoming.length > 0 && <span className="rounded-full bg-muted px-2 py-0.5 text-xs tabular-nums text-muted-foreground">{upcoming.length}</span>}
          </h1>
          <p className="mt-0.5 text-sm text-muted-foreground">{t('liveMeeting.upcoming.description')}</p>
        </div>
        <div className="flex w-full flex-wrap items-center gap-2 sm:w-auto">
          <div className="relative min-w-0 flex-1 sm:w-72">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input aria-label={t('liveMeeting.upcoming.search')} placeholder={t('liveMeeting.upcoming.search')} value={search}
              onChange={e => setSearch(e.target.value)} className="h-9 bg-card pl-9 pr-9" />
            {search && <button type="button" aria-label={t('nav.meetings.clearSearch')} onClick={() => setSearch('')}
              className="absolute right-2 top-1/2 flex h-6 w-6 -translate-y-1/2 items-center justify-center rounded text-muted-foreground hover:bg-muted"><X className="h-4 w-4" /></button>}
          </div>
          <Button size="sm" onClick={() => { setEditing(null); setScheduleOpen(true); }}><Plus className="mr-1 h-4 w-4" />{t('liveMeeting.schedule.title')}</Button>
        </div>
      </div>
    </div>
    <div className="custom-scrollbar min-h-0 flex-1 overflow-y-auto" aria-busy={loading}>
      <div className="mx-auto max-w-5xl space-y-4 px-6 py-5">
        {loading ? <p role="status" className="flex items-center justify-center gap-2 py-12 text-sm text-muted-foreground"><Loader2 className="h-4 w-4 animate-spin" />{t('common.status.loading')}</p>
          : failed ? <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-card p-5">
            <p className="text-sm text-destructive">{t('liveMeeting.upcoming.loadFailed')}</p>
            <Button variant="outline" onClick={() => void refetch()}>{t('common.actions.retry')}</Button>
          </div> : groups.length ? groups.map(([key, group]) => <section key={key} className="rounded-xl border border-border bg-card p-4 shadow-card sm:p-5">
            <h2 className="mb-4 text-sm font-medium text-muted-foreground">{dateLabel(group.date)}</h2>
            <ul className="space-y-4">
              {group.meetings.map(m => <li key={m.id} data-testid="upcoming-meeting" className="relative border-l border-border pl-4">
                <span className="absolute -left-[3px] top-2 h-1.5 w-1.5 rounded-full bg-primary" aria-hidden="true" />
                <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
                  <time dateTime={m.startAt} className="shrink-0 text-xs tabular-nums text-muted-foreground">{formatTime(new Date(m.startAt), locale)} – {formatTime(new Date(Date.parse(m.startAt) + m.durationMin * 60_000), locale)}</time>
                  <button type="button" title={m.title} onClick={() => setJoinCode(m.code)} className="min-w-0 flex-1 basis-40 truncate text-left text-sm font-medium text-foreground hover:text-primary">{m.title}</button>
                  {m.activeRoomId && <span className="text-xs text-success">{t('liveMeeting.today.ongoing')}</span>}
                  <div className="flex shrink-0 items-center gap-1">
                    <Button size="sm" variant="outline" onClick={() => setJoinCode(m.code)} aria-label={t('liveMeeting.upcoming.joinMeeting', { title: m.title })}><Video className="mr-1 h-3.5 w-3.5" />{t('liveMeeting.today.join')}</Button>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild><button type="button" aria-label={t('liveMeeting.upcoming.actions', { title: m.title })} className="flex h-8 w-8 items-center justify-center rounded-md text-muted-foreground hover:bg-muted"><MoreHorizontal className="h-4 w-4" /></button></DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem disabled={!!m.activeRoomId} onSelect={() => { setEditing(m); setScheduleOpen(true); }}>{t('common.actions.edit')}</DropdownMenuItem>
                        <DropdownMenuItem disabled={!!m.activeRoomId} className="text-destructive" onSelect={() => { setCancelError(null); setCancelling(m); }}>{t('liveMeeting.upcoming.cancelAction')}</DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </div>
                <p className="mt-1 break-words text-xs text-muted-foreground">{t('liveMeeting.upcoming.host', { name: m.host.name })}<span className="px-2" aria-hidden="true">·</span><span className="whitespace-nowrap tabular-nums">{m.code.replace(/^(\d{3})(\d{3})$/, '$1 $2')}</span></p>
              </li>)}
            </ul>
          </section>) : <div className="flex flex-col items-center py-16 text-center">
            <span className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-accent"><CalendarDays className="h-6 w-6 text-primary" /></span>
            <p className="break-words text-sm text-muted-foreground">{search.trim() ? t('nav.meetings.noResults', { query: search.trim() }) : t('liveMeeting.upcoming.empty')}</p>
          </div>}
      </div>
    </div>
    <JoinDialog open={joinCode !== null} onOpenChange={open => { if (!open) setJoinCode(null); }} initialCode={joinCode} defaultName={user?.name || ''} />
    <ScheduleDialog open={scheduleOpen} meeting={editing} onOpenChange={setScheduleOpen} userName={user?.name || ''} />
    <Dialog open={!!cancelling} onOpenChange={open => { if (!open && !saving) setCancelling(null); }}>
      <DialogContent className="max-w-[440px]">
        <DialogTitle>{t('liveMeeting.upcoming.cancelTitle')}</DialogTitle>
        <DialogDescription className="break-words">{t('liveMeeting.upcoming.cancelConfirm', { title: cancelling?.title || '' })}</DialogDescription>
        {cancelError && <p role="alert" className="text-sm text-destructive">{cancelError}</p>}
        <div className="flex flex-wrap justify-end gap-3">
          <Button variant="outline" disabled={saving} onClick={() => setCancelling(null)}>{t('liveMeeting.upcoming.keepMeeting')}</Button>
          <Button variant="destructive" disabled={saving} onClick={() => void cancelMeeting()}>{saving ? t('common.actions.saving') : t('liveMeeting.upcoming.cancelAction')}</Button>
        </div>
      </DialogContent>
    </Dialog>
  </div>;
}
