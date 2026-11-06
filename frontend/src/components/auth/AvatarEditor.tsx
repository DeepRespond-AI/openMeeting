'use client';
import { useEffect, useRef, useState } from 'react';
import { toast } from 'sonner';
import { useIm } from '@/contexts/IMContext';
import { useT } from '@/i18n';
import { Button } from '@/components/ui/button';
import { AVATAR_MAX_BYTES, AVATAR_TYPES, saveImAvatar } from '@/services/im-avatar';

export function AvatarEditor() {
  const { client, status } = useIm(), t = useT();
  const [phase, setPhase] = useState<'uploading' | 'saving' | null>(null);
  const [progress, setProgress] = useState<number | null>(null);
  const [error, setError] = useState('');
  const input = useRef<HTMLInputElement>(null), controller = useRef<AbortController | null>(null), active = useRef(true);
  useEffect(() => { active.current = true; return () => { active.current = false; controller.current?.abort(); }; }, []);
  const change = async (file?: File) => {
    if (!file || !client || controller.current) return;
    setError('');
    if (!AVATAR_TYPES.includes(file.type)) { setError(t('auth.account.avatarType')); return; }
    if (file.size > AVATAR_MAX_BYTES) { setError(t('auth.account.avatarSize')); return; }
    const abort = new AbortController(); controller.current = abort;
    setPhase('uploading'); setProgress(0);
    try {
      await saveImAvatar(client, file, abort.signal, value => { if (active.current) setProgress(value); }, () => { if (active.current) setPhase('saving'); });
      if (active.current) toast.success(t('auth.account.avatarSaved'));
    } catch (e) {
      if (active.current && !abort.signal.aborted) setError(t('auth.account.avatarFailed'));
    } finally {
      if (controller.current === abort) controller.current = null;
      if (active.current) { setPhase(null); setProgress(null); }
    }
  };
  return <div data-testid="avatar-editor" className="space-y-2">
    <input ref={input} type="file" accept={AVATAR_TYPES.join(',')} className="sr-only" tabIndex={-1} aria-label={t('auth.account.avatarFile')} disabled={!!phase || status !== 'ready'} onChange={e => { const file = e.target.files?.[0]; e.target.value = ''; void change(file); }} />
    <div className="flex flex-wrap items-center gap-2">
      <Button type="button" variant="outline" size="sm" onClick={() => input.current?.click()} disabled={!!phase || status !== 'ready'}>{t('auth.account.changeAvatar')}</Button>
      {phase === 'uploading' && <Button type="button" variant="ghost" size="sm" onClick={() => controller.current?.abort()}>{t('common.actions.cancel')}</Button>}
      {phase && <span role="status" className="text-xs text-muted-foreground">{t(phase === 'saving' ? 'auth.account.avatarSaving' : 'auth.account.avatarUploading')}{phase === 'uploading' && progress !== null ? ` ${progress}%` : ''}</span>}
    </div>
    <p className="text-xs text-muted-foreground">{t('auth.account.avatarHint')}</p>
    {error && <p role="alert" className="break-words text-sm text-destructive">{error}</p>}
  </div>;
}
