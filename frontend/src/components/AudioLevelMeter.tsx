'use client';

import React from 'react';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

interface AudioLevelMeterProps {
  rmsLevel: number;    // 0.0 to 1.0
  peakLevel: number;   // 0.0 to 1.0
  isActive: boolean;   // Whether audio is being detected
  deviceName: string;
  className?: string;
  size?: 'small' | 'medium' | 'large';
}

/** Log-scale a 0..1 level so quiet speech is still visible. */
function toLogLevel(level: number): number {
  const normalized = Math.max(0, Math.min(1, level));
  return normalized > 0 ? Math.log10(normalized * 9 + 1) : 0;
}

function levelColor(level: number): string {
  if (level < 0.3) return 'bg-success';
  if (level < 0.7) return 'bg-warning';
  return 'bg-destructive';
}

const SIZE_CLASSES = {
  small: { container: 'h-2', text: 'text-xs' },
  medium: { container: 'h-2.5', text: 'text-sm' },
  large: { container: 'h-3', text: 'text-base' },
} as const;

export function AudioLevelMeter({
  rmsLevel,
  peakLevel,
  isActive,
  deviceName,
  className = '',
  size = 'medium',
}: AudioLevelMeterProps) {
  const t = useT();
  const logRms = toLogLevel(rmsLevel);
  const logPeak = toLogLevel(peakLevel);
  const rmsPercent = Math.round(logRms * 100);
  const peakPercent = Math.round(logPeak * 100);
  const sizes = SIZE_CLASSES[size];

  return (
    <div className={cn('flex items-center gap-2', className)}>
      {/* Device activity indicator */}
      <span
        className={cn('h-2 w-2 shrink-0 rounded-full', isActive ? 'bg-success animate-pulse' : 'bg-muted-foreground/30')}
        title={`${deviceName} · ${isActive ? t('recording.devices.active') : t('recording.devices.inactive')}`}
      />

      {/* Level meter */}
      <div className={cn('relative flex-1 overflow-hidden rounded-full bg-muted', sizes.container)}>
        <div
          className={cn('h-full rounded-full transition-all duration-150 ease-out', levelColor(logRms))}
          style={{ width: `${rmsPercent}%` }}
        />
        {peakPercent > rmsPercent && (
          <div
            className={cn('absolute bottom-0 top-0 w-0.5 transition-all duration-75', levelColor(logPeak))}
            style={{ left: `${peakPercent}%` }}
          />
        )}
      </div>

      <div className={cn('min-w-[3rem] text-right font-mono tabular-nums text-muted-foreground', sizes.text)}>
        {rmsPercent}%
      </div>
    </div>
  );
}

interface CompactAudioLevelMeterProps {
  rmsLevel: number;
  peakLevel: number;
  isActive: boolean;
  className?: string;
}

// Compact version for inline display in dropdowns
export function CompactAudioLevelMeter({ rmsLevel, isActive, className = '' }: CompactAudioLevelMeterProps) {
  const logRms = toLogLevel(rmsLevel);
  const rmsPercent = Math.round(logRms * 100);

  return (
    <div className={cn('flex items-center gap-1', className)}>
      <span className={cn('h-1.5 w-1.5 rounded-full', isActive ? 'bg-success' : 'bg-muted-foreground/30')} />
      <div className="h-1.5 w-8 overflow-hidden rounded-full bg-muted">
        <div className={cn('h-full transition-all duration-150', levelColor(logRms))} style={{ width: `${rmsPercent}%` }} />
      </div>
    </div>
  );
}

interface LiveWaveformProps {
  /** Bar heights (CSS lengths) driven by the parent while recording. */
  barHeights: string[];
  /** Animate bars; when false they rest as short dots. */
  active: boolean;
  /** Paused recordings show a muted, static waveform. */
  paused?: boolean;
  className?: string;
}

/** Small symmetric waveform shown next to the record control while recording. */
export function LiveWaveform({ barHeights, active, paused = false, className }: LiveWaveformProps) {
  return (
    <div className={cn('flex h-8 items-center gap-[3px]', className)} aria-hidden="true">
      {barHeights.map((height, index) => (
        <span
          key={index}
          className={cn(
            'w-1 rounded-full transition-all duration-200 ease-out',
            paused ? 'bg-warning/60' : active ? 'bg-destructive/80' : 'bg-muted-foreground/30',
          )}
          style={{ height: active && !paused ? height : '4px' }}
        />
      ))}
    </div>
  );
}
