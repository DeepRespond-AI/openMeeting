import React from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';

interface ConfirmationModalProps {
  onConfirm: () => void;
  onCancel: () => void;
  /** Body / description text. Defaults to a generic "cannot be undone" message. */
  text?: string;
  isOpen: boolean;
  /** Dialog title. Defaults to "Confirm deletion". */
  title?: string;
  /** Confirm button label. Defaults to "Delete". */
  confirmText?: string;
  /** Cancel button label. Defaults to "Cancel". */
  cancelText?: string;
  /** Confirm button style. Defaults to "destructive". */
  variant?: 'destructive' | 'default';
  /** Disables both buttons (e.g. while the action runs). */
  isLoading?: boolean;
}

export function ConfirmationModal({
  onConfirm,
  onCancel,
  text,
  isOpen,
  title,
  confirmText,
  cancelText,
  variant = 'destructive',
  isLoading = false,
}: ConfirmationModalProps) {
  const t = useT();

  return (
    <Dialog
      open={isOpen}
      onOpenChange={(open) => {
        if (!open) onCancel();
      }}
    >
      <DialogContent className="max-w-md rounded-xl border-border bg-card shadow-elevated sm:rounded-xl">
        <DialogHeader>
          <DialogTitle className="text-base font-semibold">
            {title ?? t('dialogs.confirm.deleteTitle')}
          </DialogTitle>
          <DialogDescription className="leading-relaxed">
            {text ?? t('dialogs.confirm.deleteDescription')}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter className="gap-3">
          <Button variant="outline" className="rounded-lg" onClick={onCancel} disabled={isLoading}>
            {cancelText ?? t('common.actions.cancel')}
          </Button>
          <Button
            variant={variant === 'destructive' ? 'destructive' : 'default'}
            className="rounded-lg"
            onClick={onConfirm}
            disabled={isLoading}
          >
            {confirmText ?? t('common.actions.delete')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
