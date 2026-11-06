'use client';

import { useMemo, useState } from 'react';
import { Calendar, ChevronLeft, ChevronRight } from 'lucide-react';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { useI18n } from '@/i18n';
import { cn } from '@/lib/utils';
import ScheduleTimeInput from './ScheduleTimeInput';

function sameDay(a: Date, b: Date): boolean {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

interface DateTimePickerProps {
  value: Date;
  onChange: (d: Date) => void;
  onValidityChange?: (valid: boolean) => void;
  disabled?: boolean;
}

/** Separate calendar and segmented HH:mm controls, sharing one local-time value. */
export default function DateTimePicker({ value, onChange, onValidityChange, disabled }: DateTimePickerProps) {
  const { t, locale } = useI18n();
  const [open, setOpen] = useState(false);
  const [view, setView] = useState(() => new Date(value.getFullYear(), value.getMonth(), 1));
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const label = new Intl.DateTimeFormat(locale, {
    year: 'numeric', month: '2-digit', day: '2-digit', weekday: 'short',
  }).format(value);
  const fullDate = (date: Date) => new Intl.DateTimeFormat(locale, { dateStyle: 'full' }).format(date);
  const days = useMemo(() => Array.from({ length: 42 }, (_, i) =>
    new Date(view.getFullYear(), view.getMonth(), 1 - view.getDay() + i)), [view]);
  const weekdayHeader = useMemo(() => Array.from({ length: 7 }, (_, i) =>
    new Intl.DateTimeFormat(locale, { weekday: 'narrow' }).format(new Date(2023, 0, 1 + i))), [locale]);

  function selectDay(day: Date) {
    const next = new Date(value);
    next.setFullYear(day.getFullYear(), day.getMonth(), day.getDate());
    next.setSeconds(0, 0);
    onChange(next);
    setOpen(false);
  }

  return (
    <div className="min-w-0" data-testid="schedule-date-time">
      <div className="flex min-w-0 items-start gap-2">
        <Popover modal open={open} onOpenChange={(next) => {
          if (next) setView(new Date(value.getFullYear(), value.getMonth(), 1));
          setOpen(next);
        }}>
          <PopoverTrigger asChild>
            <button type="button" disabled={disabled}
              aria-label={t('liveMeeting.schedule.picker.selectDate')}
              title={label} data-testid="schedule-date"
              className="flex h-10 min-w-0 flex-1 items-center justify-between gap-2 rounded-lg border border-border bg-muted px-3 text-sm text-foreground transition-colors hover:border-primary/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
            >
              <span className="min-w-0 truncate">{label}</span>
              <Calendar className="h-4 w-4 shrink-0 text-muted-foreground" />
            </button>
          </PopoverTrigger>
          <PopoverContent align="start" sideOffset={6} collisionPadding={12}
            aria-label={t('liveMeeting.schedule.picker.selectDate')}
            data-testid="schedule-calendar"
            className="custom-scrollbar max-h-[var(--radix-popover-content-available-height)] w-[min(290px,calc(100vw-24px))] overflow-y-auto rounded-xl bg-popover p-3"
          >
            <div className="flex items-center justify-between gap-2">
              <span className="text-sm font-semibold" aria-live="polite">
                {new Intl.DateTimeFormat(locale, { year: 'numeric', month: 'long' }).format(view)}
              </span>
              <div className="flex gap-1">
                {([-1, 1] as const).map((step) => {
                  const Icon = step === -1 ? ChevronLeft : ChevronRight;
                  return (
                    <button key={step} type="button"
                      aria-label={t(step === -1 ? 'liveMeeting.schedule.picker.prevMonth' : 'liveMeeting.schedule.picker.nextMonth')}
                      onClick={() => setView(new Date(view.getFullYear(), view.getMonth() + step, 1))}
                      className="flex h-8 w-8 items-center justify-center rounded-lg text-muted-foreground hover:bg-accent hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    ><Icon className="h-4 w-4" /></button>
                  );
                })}
              </div>
            </div>
            <div className="mt-2 grid grid-cols-7 text-center text-xs text-muted-foreground" aria-hidden="true">
              {weekdayHeader.map((day, i) => <span key={i} className="py-2">{day}</span>)}
            </div>
            <div className="grid grid-cols-7 gap-y-1">
              {days.map((day) => (
                <button key={day.getTime()} type="button" disabled={day < today}
                  aria-label={fullDate(day)} aria-pressed={sameDay(day, value)}
                  aria-current={sameDay(day, today) ? 'date' : undefined}
                  data-date={`${day.getFullYear()}-${String(day.getMonth() + 1).padStart(2, '0')}-${String(day.getDate()).padStart(2, '0')}`}
                  onClick={() => selectDay(day)}
                  className={cn(
                    'mx-auto flex h-8 w-8 items-center justify-center rounded-full text-xs tabular-nums transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-30',
                    sameDay(day, value) ? 'bg-primary text-primary-foreground' : 'hover:bg-accent',
                    day.getMonth() !== view.getMonth() && !sameDay(day, value) && 'text-muted-foreground',
                  )}
                >{day.getDate()}</button>
              ))}
            </div>
            <div className="mt-3 flex flex-wrap gap-1 border-t border-border pt-2">
              {(['today', 'tomorrow', 'dayAfter'] as const).map((key, i) => (
                <button key={key} type="button"
                  onClick={() => { const day = new Date(today); day.setDate(day.getDate() + i); selectDay(day); }}
                  className="rounded-lg px-2 py-1.5 text-xs text-primary hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >{t(`liveMeeting.schedule.picker.${key}`)}</button>
              ))}
            </div>
          </PopoverContent>
        </Popover>
        <ScheduleTimeInput value={value} onChange={onChange} onValidityChange={onValidityChange} disabled={disabled} />
      </div>
    </div>
  );
}
