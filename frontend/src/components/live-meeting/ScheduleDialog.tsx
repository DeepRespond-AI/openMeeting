'use client';

/**
 * Schedule-meeting dialog (V2 design, prototype schedule.js): topic, custom start-time
 * picker, duration presets + custom input, and the password / reminder / wait-room
 * switches. On success the scheduled meeting lands in the home "Today" panel.
 */
import { useEffect, useState } from 'react';
import { LimitedInput } from '@/components/ui/limited-input';
import { MEETING_TITLE_MAX } from '@/lib/field-limits';
import { Calendar } from 'lucide-react';
import { toast } from 'sonner';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { Switch } from '@/components/ui/switch';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { getLiveMeetingApi } from '@/services/live-meeting';
import DateTimePicker from './DateTimePicker';
import type { ScheduledMeeting } from '@/services/live-meeting';

const PRESET_DURATIONS = [30, 60, 90] as const;

interface ScheduleDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  /** Display name for the default topic ("<name>'s meeting"). */
  userName: string;
  /** Called after a meeting is scheduled so parents can refresh (home "Today"). */
  onScheduled?: () => void;
  meeting?: ScheduledMeeting | null;
}

export default function ScheduleDialog({ open, onOpenChange, userName, onScheduled, meeting }: ScheduleDialogProps) {
  const t = useT();
  const defaultTopic = t('liveMeeting.schedule.topicDefault', { name: userName || 'Me' });

  const [topic, setTopic] = useState(defaultTopic);
  const [start, setStart] = useState(() => new Date(Date.now() + 60 * 60 * 1000));
  const [timeValid, setTimeValid] = useState(true);
  const [durationMin, setDurationMin] = useState<number>(60);
  const [durationCustom, setDurationCustom] = useState('');
  const [customActive, setCustomActive] = useState(false);
  const [pwdOn, setPwdOn] = useState(false);
  const [pwd, setPwd] = useState('');
  const [remind, setRemind] = useState(true);
  const [waitRoom, setWaitRoom] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Reset the form each time the dialog opens (prototype re-creates it per open).
  useEffect(() => {
    if (open) {
      setError(null);
      setTimeValid(true);
      if (meeting) {
        setTopic(meeting.title); setStart(new Date(meeting.startAt)); setDurationMin(meeting.durationMin);
        setDurationCustom(PRESET_DURATIONS.includes(meeting.durationMin as 30 | 60 | 90) ? '' : String(meeting.durationMin));
        setCustomActive(!PRESET_DURATIONS.includes(meeting.durationMin as 30 | 60 | 90));
        setPwdOn(meeting.pwdEnabled); setPwd(meeting.pwd || ''); setRemind(meeting.remind);
        setWaitRoom(meeting.waitRoom); setSubmitting(false); return;
      }
      setTopic(t('liveMeeting.schedule.topicDefault', { name: userName || 'Me' }));
      setStart(new Date(Date.now() + 60 * 60 * 1000));
      setDurationMin(60);
      setDurationCustom('');
      setCustomActive(false);
      setPwdOn(false);
      setPwd('');
      setRemind(true);
      setWaitRoom(false);
      setSubmitting(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, userName, meeting]);

  const effectiveDuration = (): number | null => {
    if (durationCustom) {
      const n = parseInt(durationCustom, 10);
      return Number.isInteger(n) && n >= 5 && n <= 720 ? n : null;
    }
    return durationMin;
  };

  const submit = async () => {
    if (!timeValid) return;
    const dur = effectiveDuration();
    if (dur == null) {
      toast.error(t('liveMeeting.schedule.errDuration'));
      return;
    }
    if (pwdOn && !/^\d{4,6}$/.test(pwd)) {
      toast.error(t('liveMeeting.schedule.errPwd'));
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const api = getLiveMeetingApi();
      const startAt = new Date(start);
      startAt.setSeconds(0, 0);
      const input = {
        title: topic.trim() || defaultTopic,
        startAt: meeting && start.getTime() === Date.parse(meeting.startAt) ? meeting.startAt : startAt.toISOString(),
        durationMin: dur,
        pwdEnabled: pwdOn,
        pwd: pwdOn ? pwd : null,
        remind,
        waitRoom,
      };
      const saved = meeting ? await api.updateScheduledMeeting(meeting.id, input) : await api.createScheduledMeeting(input);
      onOpenChange(false);
      window.dispatchEvent(new Event('scheduled-meetings-changed'));
      toast.success(meeting ? t('liveMeeting.schedule.modified') : t('liveMeeting.schedule.success', { code: saved.code }));
      onScheduled?.();
    } catch (err) {
      setError(err instanceof Error ? err.message : t('liveMeeting.schedule.saveFailed'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(next) => { if (!submitting) onOpenChange(next); }}>
      <DialogContent className="max-h-[92vh] max-w-[440px] gap-0 overflow-y-auto rounded-2xl border-white/10 bg-[#12151D]/95 p-6 backdrop-blur-xl">
        {/* Header */}
        <div className="relative flex flex-col items-center text-center">
          <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-gradient text-white shadow-[0_6px_16px_rgba(59,130,246,0.35)]">
            <Calendar className="h-6 w-6" />
          </div>
          <DialogTitle className="mt-3 text-lg font-semibold text-foreground">{meeting ? t('liveMeeting.schedule.editTitle') : t('liveMeeting.schedule.title')}</DialogTitle>
          <DialogDescription className="mt-1 text-[13px] text-muted-foreground">
            {t('liveMeeting.schedule.subtitle')}
          </DialogDescription>
        </div>

        <form
          className="mt-5 flex flex-col gap-4 text-left"
          onSubmit={(e) => { e.preventDefault(); void submit(); }}
        >
          {/* Topic */}
          <div>
            <label htmlFor="sched-title" className="mb-1.5 block text-[13px] font-medium text-foreground/70">
              {t('liveMeeting.schedule.topic')}
            </label>
            <LimitedInput
              id="sched-title"
              type="text"
              maxLength={MEETING_TITLE_MAX}
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
              className="flex h-10 w-full rounded-lg border border-white/10 bg-white/[0.06] px-3 text-sm text-foreground placeholder:text-muted-foreground/50 focus:border-brand-cyan focus:outline-none focus:ring-2 focus:ring-brand-cyan/25"
            />
          </div>

          {/* Start time */}
          <div>
            <span className="mb-1.5 block text-[13px] font-medium text-foreground/70">{t('liveMeeting.schedule.startTime')}</span>
            <DateTimePicker value={start} onChange={setStart} onValidityChange={setTimeValid} disabled={submitting} />
          </div>

          {/* Duration */}
          <div>
            <span className="mb-1.5 block text-[13px] font-medium text-foreground/70">{t('liveMeeting.schedule.duration')}</span>
            <div role="radiogroup" aria-label={t('liveMeeting.schedule.duration')} className="flex flex-wrap gap-1.5">
              {PRESET_DURATIONS.map((min) => {
                const active = !durationCustom && !customActive && durationMin === min;
                return (
                  <button
                    key={min}
                    type="button"
                    role="radio"
                    aria-checked={active}
                    onClick={() => { setDurationMin(min); setDurationCustom(''); setCustomActive(false); }}
                    className={cn(
                      'rounded-lg border px-3.5 py-1.5 text-sm font-medium transition-colors',
                      active
                        ? 'border-primary bg-primary/15 text-white'
                        : 'border-white/10 bg-white/[0.06] text-foreground/50 hover:text-white',
                    )}
                  >
                    {t('liveMeeting.schedule.durationMin', { min })}
                  </button>
                );
              })}
              <span
                className={cn(
                  'flex items-center gap-1.5 rounded-lg border px-3.5 py-1.5 transition-colors',
                  durationCustom || customActive ? 'border-primary bg-primary/15' : 'border-white/10 bg-white/[0.06]',
                )}
              >
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={3}
                  placeholder={t('liveMeeting.schedule.durationCustom')}
                  value={durationCustom}
                  onFocus={() => setCustomActive(true)}
                  onChange={(e) => {
                    const v = e.target.value.replace(/\D/g, '').slice(0, 3);
                    setDurationCustom(v);
                  }}
                  className="w-12 bg-transparent text-center text-sm text-white placeholder:text-muted-foreground/60 focus:outline-none"
                />
                <span className="text-sm text-foreground/50">{t('liveMeeting.schedule.durationUnit')}</span>
              </span>
            </div>
          </div>

          {/* Settings: password / reminder / waiting room */}
          <div className="rounded-xl bg-white/[0.04] px-4 py-1">
            <div className="flex items-center justify-between border-b border-white/[0.06] py-2.5">
              <div className="min-w-0">
                <div className="text-sm text-foreground/80">{t('liveMeeting.schedule.password')}</div>
                <div className="mt-0.5 text-xs text-muted-foreground">{t('liveMeeting.schedule.passwordDesc')}</div>
              </div>
              <Switch checked={pwdOn} onCheckedChange={setPwdOn} />
            </div>
            {pwdOn && (
              <div className="flex items-center gap-2.5 border-b border-white/[0.06] py-2.5">
                <span className="shrink-0 text-xs text-foreground/45">{t('liveMeeting.schedule.passwordLabel')}</span>
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={6}
                  placeholder={t('liveMeeting.schedule.passwordPlaceholder')}
                  value={pwd}
                  onChange={(e) => setPwd(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  className="flex h-9 flex-1 rounded-lg border border-white/10 bg-white/[0.06] px-3 text-sm tracking-widest text-white placeholder:tracking-normal placeholder:text-muted-foreground/60 focus:border-brand-cyan focus:outline-none focus:ring-2 focus:ring-brand-cyan/25"
                />
              </div>
            )}
            <div className="flex items-center justify-between border-b border-white/[0.06] py-2.5">
              <div className="min-w-0">
                <div className="text-sm text-foreground/80">{t('liveMeeting.schedule.remind')}</div>
                <div className="mt-0.5 text-xs text-muted-foreground">{t('liveMeeting.schedule.remindDesc')}</div>
              </div>
              <Switch checked={remind} onCheckedChange={setRemind} />
            </div>
            <div className="flex items-center justify-between py-2.5">
              <div className="min-w-0">
                <div className="text-sm text-foreground/80">{t('liveMeeting.schedule.waitRoom')}</div>
                <div className="mt-0.5 text-xs text-muted-foreground">{t('liveMeeting.schedule.waitRoomDesc')}</div>
              </div>
              <Switch checked={waitRoom} onCheckedChange={setWaitRoom} />
            </div>
          </div>

          {error && <p role="alert" className="break-words text-sm text-destructive">{error}</p>}
          {/* Footer */}
          <div className="flex items-center justify-end gap-2 border-t border-white/[0.08] pt-4">
            <button
              type="button"
              disabled={submitting}
              onClick={() => onOpenChange(false)}
              className="inline-flex h-10 items-center justify-center rounded-lg border border-white/10 bg-white/[0.06] px-4 text-sm font-medium text-foreground/80 transition-colors hover:bg-white/[0.12] hover:text-white"
            >
              {t('liveMeeting.schedule.cancel')}
            </button>
            <button
              type="submit"
              disabled={submitting || !timeValid}
              className="inline-flex h-10 items-center justify-center gap-2 rounded-xl bg-brand-gradient px-6 text-sm font-semibold text-white shadow-[0_6px_16px_rgba(59,130,246,0.35)] transition-all hover:brightness-110 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50"
            >
              <Calendar className="h-4 w-4" />
              {submitting ? t('liveMeeting.schedule.saving') : meeting ? t('liveMeeting.schedule.saveChanges') : t('liveMeeting.schedule.submit')}
            </button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}
