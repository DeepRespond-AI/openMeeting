'use client'

import { Download, Loader2 } from 'lucide-react';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';
import type { UpdateInfo, UpdateProgress } from '@/services/updateService';
import { UpdateProgressLine } from './UpdateProgressLine';

interface ForceUpdateGateProps {
  info: UpdateInfo;
  installing: boolean;
  progress: UpdateProgress | null;
  error: string | null;
  onInstall: () => void;
}

/** Forced update: covers the whole app (login screen included); the only action is updating. */
export function ForceUpdateGate({ info, installing, progress, error, onInstall }: ForceUpdateGateProps) {
  const t = useT();
  return (
    <div
      role="alertdialog"
      aria-modal="true"
      aria-labelledby="force-update-title"
      className="fixed inset-0 z-[100] flex items-center justify-center bg-background p-6"
    >
      <div className="w-full max-w-md rounded-2xl border border-border bg-card p-8 text-center shadow-elevated">
        <div className="mx-auto mb-5 w-fit rounded-2xl bg-accent p-4">
          <BrandLogo size={48} />
        </div>
        <h1 id="force-update-title" className="text-xl font-semibold text-foreground">
          {t('update.force.title')}
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          {t('update.force.description', {
            current: info.currentVersion,
            version: info.version ?? '',
            app: t('common.appName'),
          })}
        </p>

        {info.notes && (
          <div className="custom-scrollbar mt-5 max-h-40 overflow-y-auto whitespace-pre-line rounded-lg bg-muted/60 p-3 text-left text-sm text-muted-foreground">
            {info.notes}
          </div>
        )}

        <div className="mt-6 space-y-3 text-left">
          {installing && <UpdateProgressLine progress={progress} />}
          {error && (
            <p role="alert" className="rounded-lg border border-destructive/20 bg-destructive/10 p-3 text-sm text-destructive">
              {error}
            </p>
          )}
          <Button className="h-10 w-full rounded-lg" disabled={installing} onClick={onInstall}>
            {installing ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
            {installing ? t('update.dialog.installing') : error ? t('update.force.retry') : t('update.force.install')}
          </Button>
        </div>
      </div>
    </div>
  );
}
