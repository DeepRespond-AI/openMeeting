'use client';

import { Loader2 } from 'lucide-react';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

interface StatusOverlaysProps {
  // Status flags
  isProcessing: boolean;      // Processing transcription after recording stops
  isSaving: boolean;          // Saving transcript to database
  /** Optional live detail from the recording state (e.g. "Processing 3 remaining segments…"). */
  detail?: string;
  className?: string;
}

/**
 * Inline post-recording status (finalizing / saving), shown in place of the record control
 * while the meeting is being wrapped up.
 */
export function StatusOverlays({ isProcessing, isSaving, detail, className }: StatusOverlaysProps) {
  const t = useT();
  if (!isProcessing && !isSaving) return null;

  const title = isSaving ? t('home.overlays.saving') : t('home.overlays.finalizing');

  return (
    <div
      role="status"
      aria-live="polite"
      className={cn('flex min-h-16 items-center gap-3 rounded-full bg-accent px-5 py-3 text-accent-foreground', className)}
    >
      <Loader2 className="h-5 w-5 shrink-0 animate-spin" />
      <div className="min-w-0 leading-tight">
        <p className="text-sm font-medium">{title}</p>
        {detail && detail !== title && <p className="truncate text-xs text-muted-foreground">{detail}</p>}
      </div>
    </div>
  );
}
