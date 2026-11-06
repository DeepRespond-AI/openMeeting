'use client';

import { motion } from 'framer-motion';
import { AlertCircle, RotateCw, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';

interface EmptyStateSummaryProps {
  onGenerate: () => void;
  hasModel: boolean;
  isGenerating?: boolean;
  error?: string | null;
}

export function EmptyStateSummary({
  onGenerate,
  hasModel,
  isGenerating = false,
  error = null,
}: EmptyStateSummaryProps) {
  const t = useT();

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.98 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.25, ease: 'easeOut' }}
      className="flex h-full flex-col items-center justify-center p-8 text-center"
    >
      <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-accent text-primary">
        <Sparkles className="h-6 w-6" />
      </div>
      <h3 className="text-base font-semibold text-foreground">{t('summary.empty.title')}</h3>
      <p className="mt-1.5 max-w-sm text-sm text-muted-foreground">{t('summary.empty.description')}</p>

      {error && (
        <p
          role="alert"
          className="mt-4 flex max-w-md items-start gap-2 rounded-lg border border-destructive/20 bg-destructive/10 px-3 py-2 text-left text-sm text-destructive"
        >
          <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
          <span className="break-words">{error}</span>
        </p>
      )}

      <Button
        onClick={onGenerate}
        disabled={!hasModel || isGenerating}
        className="mt-6 gap-2 rounded-lg"
        title={!hasModel ? t('summary.empty.noModel') : undefined}
      >
        {error ? <RotateCw className="h-4 w-4" /> : <Sparkles className="h-4 w-4" />}
        {isGenerating ? t('summary.empty.generating') : error ? t('summary.empty.retry') : t('summary.empty.generate')}
      </Button>

      {!hasModel && (
        <p className="mt-3 max-w-sm text-xs text-warning">{t('summary.empty.noModel')}</p>
      )}
    </motion.div>
  );
}
