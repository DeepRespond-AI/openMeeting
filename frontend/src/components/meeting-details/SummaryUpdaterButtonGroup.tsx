"use client";

import { Copy, Loader2, Save } from 'lucide-react';
import { useT } from '@/i18n';
import Analytics from '@/lib/analytics';
import { cn } from '@/lib/utils';

interface SummaryUpdaterButtonGroupProps {
  isSaving: boolean;
  isDirty: boolean;
  onSave: () => Promise<void>;
  onCopy: () => Promise<void>;
}

const iconButton =
  'inline-flex h-8 items-center justify-center gap-1.5 rounded-lg px-2 text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50';

/** Save (highlighted when there are unsaved edits) and copy for the summary editor. */
export function SummaryUpdaterButtonGroup({
  isSaving,
  isDirty,
  onSave,
  onCopy,
}: SummaryUpdaterButtonGroupProps) {
  const t = useT();
  const saveLabel = isSaving ? t('summary.panel.saving') : t('summary.panel.save');

  return (
    <div className="flex items-center gap-1">
      <button
        type="button"
        className={cn(
          iconButton,
          isDirty
            ? 'bg-primary/10 text-primary hover:bg-primary/15'
            : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground',
        )}
        title={isDirty ? t('summary.panel.unsaved') : saveLabel}
        aria-label={saveLabel}
        onClick={() => {
          Analytics.trackButtonClick('save_changes', 'meeting_details');
          onSave();
        }}
        disabled={isSaving}
      >
        {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
        <span className={cn(isDirty || isSaving ? 'inline' : 'hidden @[40rem]:inline')}>{saveLabel}</span>
      </button>

      <button
        type="button"
        className={cn(iconButton, 'w-8 px-0 text-muted-foreground hover:bg-accent hover:text-accent-foreground')}
        title={t('summary.panel.copy')}
        aria-label={t('summary.panel.copy')}
        onClick={() => {
          Analytics.trackButtonClick('copy_summary', 'meeting_details');
          onCopy();
        }}
      >
        <Copy className="h-4 w-4" />
      </button>
    </div>
  );
}
