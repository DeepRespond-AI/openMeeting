"use client";

import { ReactNode } from 'react';
import { Sparkles, Square } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';
import Analytics from '@/lib/analytics';
import { cn } from '@/lib/utils';

type SummaryStatus = 'idle' | 'processing' | 'summarizing' | 'regenerating' | 'completed' | 'error';

export const chipButtonClass =
  'inline-flex h-8 max-w-[14rem] items-center gap-1.5 rounded-lg border border-border bg-card px-2.5 text-xs font-medium text-foreground transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50';

interface SummaryActionButtonProps {
  onGenerateSummary: (customPrompt: string) => Promise<void>;
  onStopGeneration: () => void;
  customPrompt: string;
  summaryStatus: SummaryStatus;
  hasSummary?: boolean;
}

/** Primary generate / regenerate button, or Stop while a summary is being generated. */
export function SummaryActionButton({
  onGenerateSummary,
  onStopGeneration,
  customPrompt,
  summaryStatus,
  hasSummary = false,
}: SummaryActionButtonProps) {
  const t = useT();
  const isGenerating = summaryStatus === 'processing' || summaryStatus === 'summarizing' || summaryStatus === 'regenerating';

  if (isGenerating) {
    return (
      <Button
        variant="outline"
        size="sm"
        className="rounded-lg border-destructive/30 text-destructive hover:bg-destructive/10 hover:text-destructive"
        onClick={() => {
          Analytics.trackButtonClick('stop_summary_generation', 'meeting_details');
          onStopGeneration();
        }}
      >
        <Square className="h-3.5 w-3.5" fill="currentColor" />
        {t('summary.panel.stop')}
      </Button>
    );
  }

  return (
    <Button
      size="sm"
      className="rounded-lg"
      onClick={() => {
        Analytics.trackButtonClick('generate_summary', 'meeting_details');
        void onGenerateSummary(customPrompt);
      }}
    >
      <Sparkles className="h-4 w-4" />
      {hasSummary ? t('summary.panel.regenerate') : t('summary.panel.generate')}
    </Button>
  );
}

interface SummaryGeneratorButtonGroupProps {
  languageSlot?: ReactNode;
  hasTranscripts?: boolean;
}

/** Generation settings: summary language. The server picks the model and the template (not shown). */
export function SummaryGeneratorButtonGroup({ hasTranscripts = true, languageSlot }: SummaryGeneratorButtonGroupProps) {
  if (!hasTranscripts) {
    return null;
  }
  return <div className="flex min-w-0 flex-wrap items-center gap-2">{languageSlot}</div>;
}
