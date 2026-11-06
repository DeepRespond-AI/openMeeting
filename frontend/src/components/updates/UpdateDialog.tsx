'use client'

import { Download, Loader2, Sparkles } from 'lucide-react';
import { Button } from '@/components/ui/button';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { useT } from '@/i18n';
import type { UpdateInfo, UpdateProgress } from '@/services/updateService';
import { UpdateProgressLine } from './UpdateProgressLine';

interface UpdateDialogProps {
  open: boolean;
  info: UpdateInfo;
  installing: boolean;
  progress: UpdateProgress | null;
  error: string | null;
  onInstall: () => void;
  onClose: () => void;
}

/** Optional update: version, release notes, "Later" / "Update now" with download progress. */
export function UpdateDialog({ open, info, installing, progress, error, onInstall, onClose }: UpdateDialogProps) {
  const t = useT();
  return (
    <Dialog open={open} onOpenChange={(next) => !next && !installing && onClose()}>
      <DialogContent className="sm:max-w-[460px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2.5 text-base font-semibold">
            <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-accent text-primary">
              <Sparkles className="h-4 w-4" />
            </span>
            {t('update.dialog.title', { version: info.version ?? '' })}
          </DialogTitle>
          <DialogDescription>{t('update.dialog.description', { current: info.currentVersion })}</DialogDescription>
        </DialogHeader>

        {info.notes && (
          <div className="space-y-1.5">
            <p className="text-sm font-medium text-foreground">{t('update.dialog.notes')}</p>
            <div className="custom-scrollbar max-h-48 overflow-y-auto whitespace-pre-line rounded-lg bg-muted/60 p-3 text-sm text-muted-foreground">
              {info.notes}
            </div>
          </div>
        )}

        {installing ? (
          <UpdateProgressLine progress={progress} />
        ) : (
          <p className="text-xs text-muted-foreground">{t('update.dialog.restartHint')}</p>
        )}
        {error && (
          <p role="alert" className="rounded-lg border border-destructive/20 bg-destructive/10 p-3 text-sm text-destructive">
            {error}
          </p>
        )}

        <DialogFooter className="gap-3">
          <Button variant="outline" className="rounded-lg" disabled={installing} onClick={onClose}>
            {t('update.dialog.later')}
          </Button>
          <Button className="rounded-lg" disabled={installing} onClick={onInstall}>
            {installing ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download className="h-4 w-4" />}
            {installing ? t('update.dialog.installing') : t('update.dialog.install')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
