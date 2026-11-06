'use client';

import { Mic, MicOff } from 'lucide-react';
import { useId } from 'react';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

/** Fill only the microphone capsule, from bottom to top, with measured audio. */
export default function MicrophoneIndicator({ muted, level = 0, iconClassName, mutedIconClassName, className }: {
  muted: boolean; level?: number; iconClassName?: string; mutedIconClassName?: string; className?: string;
}) {
  const t = useT();
  const capsuleId = useId();
  const value = muted || !Number.isFinite(level) ? 0 : Math.round(Math.min(1, Math.max(0, level)) * 100);
  return (
    <span role="meter" aria-label={t('liveMeeting.room.audio.level')} aria-valuemin={0} aria-valuemax={100}
      aria-valuenow={value} aria-valuetext={muted ? t('liveMeeting.room.toolbar.micOff') : t('liveMeeting.room.audio.levelValue', { value })}
      data-audio-level={value} className={cn('inline-flex shrink-0 items-center', className)}>
      <span className={cn('relative inline-flex h-3.5 w-3.5', iconClassName)} aria-hidden="true">
        {muted ? <MicOff className={cn('h-full w-full text-destructive', mutedIconClassName)} /> : <>
          <svg viewBox="0 0 24 24" className="absolute inset-0 h-full w-full text-success" fill="currentColor">
            <defs>
              <clipPath id={capsuleId} clipPathUnits="userSpaceOnUse">
                <rect x="9" y="2" width="6" height="13" rx="3" />
              </clipPath>
            </defs>
            <g clipPath={`url(#${capsuleId})`}>
              <rect x="9" y="2" width="6" height="13"
                className="transition-transform duration-100 motion-reduce:transition-none"
                style={{ transform: `translateY(${13 * (1 - value / 100)}px)` }} />
            </g>
          </svg>
          <Mic className="relative h-full w-full text-foreground/60" />
        </>}
      </span>
    </span>
  );
}
