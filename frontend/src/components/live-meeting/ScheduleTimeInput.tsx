'use client';

import { useEffect, useId, useMemo, useRef, useState } from 'react';
import type { KeyboardEvent } from 'react';
import { ChevronDown } from 'lucide-react';
import { Popover, PopoverAnchor, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

const pad = (n: number) => String(n).padStart(2, '0');
const validPart = (text: string, max: number) => /^\d{1,2}$/.test(text) && Number(text) <= max;
const timeLabel = (minute: number) => `${pad(Math.floor(minute / 60))}:${pad(minute % 60)}`;

interface ScheduleTimeInputProps {
  value: Date;
  onChange: (value: Date) => void;
  onValidityChange?: (valid: boolean) => void;
  disabled?: boolean;
}

/** Editable segments keep the colon fixed; the popup offers quarter-hour shortcuts. */
export default function ScheduleTimeInput({ value, onChange, onValidityChange, disabled }: ScheduleTimeInputProps) {
  const t = useT();
  const id = useId();
  const [hour, setHour] = useState(pad(value.getHours()));
  const [minute, setMinute] = useState(pad(value.getMinutes()));
  const [open, setOpen] = useState(false);
  const selected = value.getHours() * 60 + value.getMinutes();
  const [active, setActive] = useState(selected);
  const hourRef = useRef<HTMLInputElement>(null);
  const minuteRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const valid = validPart(hour, 23) && validPart(minute, 59);
  const options = useMemo(() => [...new Set([
    ...Array.from({ length: 96 }, (_, i) => i * 15), selected,
  ])].sort((a, b) => a - b), [selected]);
  const valueHour = value.getHours(), valueMinute = value.getMinutes();

  useEffect(() => { setHour(pad(valueHour)); setMinute(pad(valueMinute)); }, [valueHour, valueMinute]);
  useEffect(() => { onValidityChange?.(valid); }, [valid, onValidityChange]);
  useEffect(() => {
    if (!open) return;
    const frame = requestAnimationFrame(() => {
      const list = listRef.current;
      const option = list?.querySelector<HTMLElement>(`[data-minute="${active}"]`);
      if (list && option) list.scrollTop = option.offsetTop - (list.clientHeight - option.offsetHeight) / 2;
    });
    return () => cancelAnimationFrame(frame);
  }, [open, active]);

  function changeTime(hours: number, minutes: number) {
    const next = new Date(value);
    next.setHours(hours, minutes, 0, 0);
    onChange(next);
  }
  function commit() {
    if (!valid) return;
    setHour(pad(Number(hour)));
    setMinute(pad(Number(minute)));
    changeTime(Number(hour), Number(minute));
  }
  function selectTime(total: number) {
    setHour(pad(Math.floor(total / 60)));
    setMinute(pad(total % 60));
    changeTime(Math.floor(total / 60), total % 60);
    setOpen(false);
  }
  function segmentKey(event: KeyboardEvent<HTMLInputElement>, part: 'hour' | 'minute') {
    if (event.key === 'Enter') {
      event.preventDefault(); commit();
      if (part === 'hour') { minuteRef.current?.focus(); minuteRef.current?.select(); }
      else event.currentTarget.blur();
    } else if ((part === 'hour' && (event.key === ':' || (event.key === 'ArrowRight' && event.currentTarget.selectionStart === hour.length)))
      || (part === 'minute' && event.key === 'ArrowLeft' && event.currentTarget.selectionStart === 0)) {
      event.preventDefault();
      const input = part === 'hour' ? minuteRef.current : hourRef.current;
      input?.focus(); input?.select();
    } else if (event.key === 'ArrowUp' || event.key === 'ArrowDown') {
      event.preventDefault();
      const max = part === 'hour' ? 24 : 60;
      const current = Number(part === 'hour' ? hour : minute) || 0;
      const next = pad((current + (event.key === 'ArrowUp' ? 1 : -1) + max) % max);
      (part === 'hour' ? setHour : setMinute)(next);
    }
  }

  return (
    <div className="w-[126px] shrink-0">
      <Popover modal open={open} onOpenChange={(next) => { setOpen(next); if (next) setActive(selected); }}>
        <PopoverAnchor asChild>
          <div role="group" aria-label={t('liveMeeting.schedule.picker.timeLabel')}
            data-testid="schedule-time-input"
            className={cn('flex h-10 items-center rounded-lg border bg-muted pl-2 text-sm tabular-nums focus-within:ring-2 focus-within:ring-ring', valid ? 'border-border' : 'border-destructive')}
          >
            {(['hour', 'minute'] as const).map((part, i) => (
              <span key={part} className="flex items-center">
                {i === 1 && <span aria-hidden="true" data-testid="schedule-time-colon" className="select-none px-0.5">:</span>}
                <input ref={part === 'hour' ? hourRef : minuteRef}
                  type="text" inputMode="numeric" autoComplete="off" maxLength={2}
                  aria-label={t(part === 'hour' ? 'liveMeeting.schedule.picker.hour' : 'liveMeeting.schedule.picker.minute')}
                  aria-invalid={!validPart(part === 'hour' ? hour : minute, part === 'hour' ? 23 : 59)}
                  aria-describedby={!valid ? `${id}-error` : undefined}
                  disabled={disabled} value={part === 'hour' ? hour : minute}
                  onChange={(event) => (part === 'hour' ? setHour : setMinute)(event.target.value.replace(/\D/g, '').slice(0, 2))}
                  onBlur={commit} onKeyDown={(event) => segmentKey(event, part)}
                  onFocus={(event) => event.currentTarget.select()}
                  className="h-8 w-6 min-w-0 bg-transparent text-center text-foreground outline-none disabled:cursor-not-allowed disabled:opacity-50"
                />
              </span>
            ))}
            <PopoverTrigger asChild>
              <button type="button" disabled={disabled}
                aria-label={t('liveMeeting.schedule.picker.selectTime')}
                className="ml-auto flex h-9 w-8 shrink-0 items-center justify-center rounded-r-lg text-muted-foreground hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
              ><ChevronDown className="h-4 w-4" /></button>
            </PopoverTrigger>
          </div>
        </PopoverAnchor>
        <PopoverContent align="end" sideOffset={6} collisionPadding={12}
          aria-label={t('liveMeeting.schedule.picker.selectTime')}
          className="w-[126px] rounded-lg bg-popover p-1"
          onOpenAutoFocus={(event) => { event.preventDefault(); listRef.current?.focus(); }}
        >
          <div ref={listRef} role="listbox" tabIndex={0}
            aria-label={t('liveMeeting.schedule.picker.selectTime')}
            aria-activedescendant={`${id}-option-${active}`}
            data-testid="schedule-time-options"
            className="custom-scrollbar relative max-h-[min(256px,var(--radix-popover-content-available-height))] overflow-y-auto outline-none"
            onKeyDown={(event) => {
              const index = options.indexOf(active);
              if (['ArrowDown', 'ArrowUp', 'Home', 'End'].includes(event.key)) {
                event.preventDefault();
                setActive(options[event.key === 'Home' ? 0 : event.key === 'End' ? options.length - 1
                  : Math.min(options.length - 1, Math.max(0, index + (event.key === 'ArrowDown' ? 1 : -1)))]);
              } else if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault(); selectTime(active);
              }
            }}
          >
            {options.map((total) => (
              <button key={total} id={`${id}-option-${total}`} type="button" role="option" tabIndex={-1}
                aria-selected={selected === total} data-minute={total}
                onClick={() => selectTime(total)}
                className={cn('block w-full rounded-md px-3 py-2 text-left text-sm tabular-nums hover:bg-accent',
                  selected === total && 'bg-primary/15 text-primary',
                  active === total && 'ring-1 ring-inset ring-ring')}
              >{timeLabel(total)}</button>
            ))}
          </div>
        </PopoverContent>
      </Popover>
      {!valid && <p id={`${id}-error`} role="alert" className="mt-1 break-words text-xs text-destructive">{t('liveMeeting.schedule.picker.invalidTime')}</p>}
    </div>
  );
}
