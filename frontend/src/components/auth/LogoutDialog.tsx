'use client';

import React, { useState } from 'react';
import { AlertCircle, Loader2, LogOut } from 'lucide-react';
import { toast } from 'sonner';
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
import { useServer } from '@/contexts/ServerContext';
import { useRecordingState } from '@/contexts/RecordingStateContext';
import { errorMessage } from '@/lib/server';

/** "Sign out?" confirmation. Signing out is blocked while a recording is running. */
export function LogoutDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const t = useT();
  const { logout } = useServer();
  const { isRecording } = useRecordingState();
  const [busy, setBusy] = useState(false);

  const handleLogout = async () => {
    setBusy(true);
    try {
      await logout();
      toast.success(t('auth.toast.loggedOut'));
      onOpenChange(false);
    } catch (err) {
      toast.error(t('auth.toast.logoutFailed'), { description: errorMessage(err) });
    } finally {
      setBusy(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={(next) => !busy && onOpenChange(next)}>
      <DialogContent className="sm:max-w-[420px]">
        <DialogHeader>
          <DialogTitle>{t('auth.account.logoutTitle')}</DialogTitle>
          <DialogDescription>{t('auth.account.logoutDescription')}</DialogDescription>
        </DialogHeader>
        {isRecording && (
          <div role="alert" className="flex items-start gap-2 rounded-lg border border-warning/30 bg-warning/10 px-3 py-2 text-sm text-warning">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{t('auth.account.logoutRecording')}</span>
          </div>
        )}
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} disabled={busy}>
            {t('common.actions.cancel')}
          </Button>
          <Button variant="destructive" onClick={handleLogout} disabled={busy || isRecording}>
            {busy ? <Loader2 className="h-4 w-4 animate-spin" /> : <LogOut className="h-4 w-4" />}
            {t('auth.account.logout')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
