'use client';

import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

interface ConfidenceIndicatorProps {
  confidence: number;
  showIndicator?: boolean;
  /** Also render the percentage next to the dot. */
  showLabel?: boolean;
}

type Level = 'high' | 'good' | 'medium' | 'low';

function levelFor(conf: number): Level {
  if (conf >= 0.8) return 'high';
  if (conf >= 0.7) return 'good';
  if (conf >= 0.4) return 'medium';
  return 'low';
}

const DOT_CLASS: Record<Level, string> = {
  high: 'bg-success',
  good: 'bg-primary',
  medium: 'bg-warning',
  low: 'bg-destructive',
};

export const ConfidenceIndicator: React.FC<ConfidenceIndicatorProps> = ({
  confidence,
  showIndicator = true,
  showLabel = false,
}) => {
  const t = useT();

  // Don't render if preference is disabled
  if (!showIndicator) {
    return null;
  }

  const level = levelFor(confidence);
  const percent = (confidence * 100).toFixed(0);
  const label = t(`transcript.confidence.${level}`);

  return (
    <div
      className="inline-flex items-center gap-1.5"
      title={t('transcript.confidence.title', { percent, label })}
      aria-label={t('transcript.confidence.aria', { percent })}
    >
      <span className={cn('h-2 w-2 rounded-full transition-colors duration-200', DOT_CLASS[level])} role="status" />
      {showLabel && <span className="text-xs text-muted-foreground tabular-nums">{percent}%</span>}
    </div>
  );
};
