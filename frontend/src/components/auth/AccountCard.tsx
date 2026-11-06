'use client';

import React, { useState } from 'react';
import { Check, KeyRound, Loader2, LogOut, Pencil, X } from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { useI18n, useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { maskPhone } from '@/lib/phone';
import { errorMessage } from '@/lib/server';
import { ImUserAvatar as UserAvatar } from '@/components/im/ImUserAvatar';
import { AvatarEditor } from './AvatarEditor';
import { LogoutDialog } from './LogoutDialog';
import { PasswordDialog } from './PasswordDialog';
import { USER_NAME_MAX as NAME_MAX_LENGTH } from '@/lib/field-limits';
import { LimitedInput } from '@/components/ui/limited-input';

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-4 py-2.5 text-sm">
      <span className="shrink-0 text-muted-foreground">{label}</span>
      <span className="min-w-0 text-right text-foreground">{children}</span>
    </div>
  );
}

/** Settings card for the signed-in account: nickname (editable), masked phone, password, sign out. */
export function AccountCard() {
  const t = useT();
  const { locale } = useI18n();
  const { user, loggedIn, updateProfile } = useServer();
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState('');
  const [saving, setSaving] = useState(false);
  const [logoutOpen, setLogoutOpen] = useState(false);
  const [passwordOpen, setPasswordOpen] = useState(false);

  if (!loggedIn || !user) return null;

  const formatDate = (value: string | null | undefined) => {
    if (!value) return '—';
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? value : date.toLocaleString(locale, { hour12: false });
  };

  const startEdit = () => {
    setDraft(user?.name ?? '');
    setEditing(true);
  };

  const saveName = async () => {
    const name = draft.trim();
    if (!name) {
      toast.error(t('auth.errors.nameRequired'));
      return;
    }
    if (Array.from(name).length > NAME_MAX_LENGTH) {
      toast.error(t('auth.errors.nameTooLong', { max: NAME_MAX_LENGTH }));
      return;
    }
    if (name === user?.name) {
      setEditing(false);
      return;
    }
    setSaving(true);
    try {
      await updateProfile(name);
      toast.success(t('auth.toast.profileSaved'));
      setEditing(false);
    } catch (err) {
      toast.error(t('auth.toast.profileFailed'), { description: errorMessage(err) });
    } finally {
      setSaving(false);
    }
  };

  return (
    <section className="space-y-4 rounded-xl border border-border bg-card p-5 shadow-card">
      <div>
        <h3 className="text-base font-semibold text-foreground">{t('auth.account.title')}</h3>
        <p className="mt-1 text-xs text-muted-foreground">{t('auth.account.description')}</p>
      </div>

      <div className="flex items-center gap-4 rounded-xl bg-muted/60 p-4">
        <UserAvatar username={user.id} name={user?.name} size="lg" />
        <div className="min-w-0 flex-1">
          <div className="truncate text-lg font-semibold text-foreground" title={user?.name}>
            {user.name || maskPhone(user.phone) || t('auth.account.signedInAccount')}
          </div>
          <div className="truncate text-sm text-muted-foreground">{maskPhone(user?.phone) || '—'}</div>
        </div>
      </div>

      <AvatarEditor />

      <div className="divide-y divide-border">
        <Row label={t('auth.account.nickname')}>
          {editing ? (
            <span className="flex items-center justify-end gap-1.5">
              <LimitedInput
                value={draft}
                maxLength={NAME_MAX_LENGTH}
                disabled={saving}
                onChange={(e) => setDraft(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') void saveName();
                  if (e.key === 'Escape') setEditing(false);
                }}
                aria-label={t('auth.account.editNickname')}
                autoFocus
                className="h-8 w-48 max-w-full"
              />
              <Button size="icon" className="h-8 w-8" onClick={saveName} disabled={saving} aria-label={t('common.actions.save')}>
                {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Check className="h-4 w-4" />}
              </Button>
              <Button
                size="icon"
                variant="ghost"
                className="h-8 w-8"
                onClick={() => setEditing(false)}
                disabled={saving}
                aria-label={t('common.actions.cancel')}
              >
                <X className="h-4 w-4" />
              </Button>
            </span>
          ) : (
            <span className="flex items-center justify-end gap-2">
              <span className="truncate" title={user?.name}>{user?.name || '—'}</span>
              <Button size="sm" variant="ghost" onClick={startEdit} disabled={!user} aria-label={t('auth.account.editNickname')}>
                <Pencil className="h-3.5 w-3.5" />
                {t('common.actions.edit')}
              </Button>
            </span>
          )}
        </Row>
        <Row label={t('auth.account.phone')}>{maskPhone(user?.phone) || '—'}</Row>
        <Row label={t('auth.account.password')}>
          <span className="flex items-center justify-end gap-2">
            <span className={user?.has_password ? undefined : 'text-muted-foreground'}>
              {user?.has_password ? t('auth.account.passwordIsSet') : t('auth.account.passwordNotSet')}
            </span>
            <Button size="sm" variant="ghost" onClick={() => setPasswordOpen(true)} disabled={!user}>
              <KeyRound className="h-3.5 w-3.5" />
              {user?.has_password ? t('auth.account.changePassword') : t('auth.account.setPassword')}
            </Button>
          </span>
        </Row>
        <Row label={t('auth.account.memberSince')}>{formatDate(user?.created_at)}</Row>
        <Row label={t('auth.account.lastLogin')}>{formatDate(user?.last_login_at)}</Row>
      </div>

      <div className="flex justify-end">
        <Button
          variant="outline"
          onClick={() => setLogoutOpen(true)}
          className="text-destructive hover:bg-destructive/10 hover:text-destructive"
        >
          <LogOut className="h-4 w-4" />
          {t('auth.account.logout')}
        </Button>
      </div>
      <LogoutDialog open={logoutOpen} onOpenChange={setLogoutOpen} />
      <PasswordDialog open={passwordOpen} onOpenChange={setPasswordOpen} />
    </section>
  );
}
