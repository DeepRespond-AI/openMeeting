'use client';

import React, { useEffect, useState } from 'react';
import { AlertCircle, Loader2 } from 'lucide-react';
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
import { Label } from '@/components/ui/label';
import { useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { passwordProblem } from '@/lib/password';
import { errorMessage } from '@/lib/server';
import { describePasswordProblem, PasswordInput, passwordRulesOf } from './PasswordInput';

/**
 * Set the first password (legacy SMS-only accounts) or change it. Changing signs out the
 * account's other devices (server side).
 */
export function PasswordDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const t = useT();
  const { user, authConfig, changePassword } = useServer();
  const rules = passwordRulesOf(authConfig);
  const hasPassword = !!user?.has_password;
  const [oldPassword, setOldPassword] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) return;
    setOldPassword('');
    setPassword('');
    setConfirm('');
    setError(null);
  }, [open]);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (busy) return;
    if (hasPassword && !oldPassword) {
      setError(t('auth.errors.oldPasswordRequired'));
      return;
    }
    const problem = passwordProblem(password, rules);
    if (problem) {
      setError(describePasswordProblem(problem, rules, t));
      return;
    }
    if (password !== confirm) {
      setError(t('auth.errors.passwordMismatch'));
      return;
    }
    setBusy(true);
    try {
      await changePassword(hasPassword ? oldPassword : null, password);
      toast.success(hasPassword ? t('auth.toast.passwordChanged') : t('auth.toast.passwordSet'));
      onOpenChange(false);
    } catch (err) {
      setError(errorMessage(err) || t('auth.toast.passwordFailed'));
    } finally {
      setBusy(false);
    }
  };

  const field = (id: string, label: string, value: string, onChange: (v: string) => void, extra: Partial<React.ComponentProps<typeof PasswordInput>> = {}) => (
    <div className="space-y-2">
      <Label htmlFor={id}>{label}</Label>
      <PasswordInput
        id={id}
        value={value}
        maxLength={rules.maxLength}
        onChange={(e) => {
          onChange(e.target.value);
          setError(null);
        }}
        {...extra}
      />
    </div>
  );

  return (
    <Dialog open={open} onOpenChange={(next) => !busy && onOpenChange(next)}>
      <DialogContent className="sm:max-w-[440px]">
        <form onSubmit={handleSubmit} noValidate className="space-y-4">
          <DialogHeader>
            <DialogTitle>
              {hasPassword ? t('auth.account.passwordDialog.changeTitle') : t('auth.account.passwordDialog.setTitle')}
            </DialogTitle>
            <DialogDescription>
              {hasPassword ? t('auth.account.passwordDialog.changeDescription') : t('auth.account.passwordDialog.setDescription')}
            </DialogDescription>
          </DialogHeader>
          {hasPassword &&
            field('password-dialog-old', t('auth.fields.oldPassword'), oldPassword, setOldPassword, {
              autoComplete: 'current-password',
              autoFocus: true,
            })}
          {field('password-dialog-new', t('auth.fields.newPassword'), password, setPassword, {
            autoComplete: 'new-password',
            autoFocus: !hasPassword,
            placeholder: t('auth.fields.passwordPlaceholder', { min: rules.minLength, max: rules.maxLength }),
          })}
          {field('password-dialog-confirm', t('auth.fields.confirmPassword'), confirm, setConfirm, {
            autoComplete: 'new-password',
            placeholder: t('auth.fields.confirmPasswordPlaceholder'),
          })}
          {hasPassword && <p className="text-xs text-muted-foreground">{t('auth.account.passwordDialog.forgot')}</p>}
          {error && (
            <div role="alert" className="flex items-start gap-2 rounded-lg border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
              <span className="min-w-0 break-words">{error}</span>
            </div>
          )}
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={busy}>
              {t('common.actions.cancel')}
            </Button>
            <Button type="submit" disabled={busy}>
              {busy && <Loader2 className="h-4 w-4 animate-spin" />}
              {t('common.actions.save')}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
