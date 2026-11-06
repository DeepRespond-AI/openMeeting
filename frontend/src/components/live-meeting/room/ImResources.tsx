'use client';
import { useEffect, useRef, useState } from 'react';
import type { GroupFile, UserProfile } from '@deeprespond/im-web';
import { useIm } from '@/contexts/IMContext';
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog';
import { useT } from '@/i18n';
import { buttonClass } from '@/components/im/useImAction';

export default function ImResources({ groupId, member, onClose }: {
  groupId: string | null; member: string | null; onClose: () => void;
}) {
  const { client } = useIm(), t = useT();
  const [files, setFiles] = useState<GroupFile[]>([]), [profile, setProfile] = useState<UserProfile>();
  const [cursor, setCursor] = useState<string | null>(null), [loading, setLoading] = useState(true);
  const [error, setError] = useState(''), [retry, setRetry] = useState(0);
  const [downloading, setDownloading] = useState(false);
  const [avatar, setAvatar] = useState('');
  const download = useRef<AbortController | null>(null);
  useEffect(() => () => download.current?.abort(), []);
  useEffect(() => {
    if (!client) { setLoading(false); return; }
    let disposed = false;
    let objectUrl = '';
    const abort = new AbortController();
    setLoading(true); setError(''); setFiles([]); setProfile(undefined); setCursor(null); setAvatar('');
    void (async () => {
      if (member) {
        const users = await client.users.fetch([member]);
        const user = users.get(member);
        if (!disposed) setProfile(user);
        if (user?.avatar_url && client.files.isFileUrl(user.avatar_url)) {
          const blob = await client.files.fetchBlob(user.avatar_url, { signal: abort.signal,
            onProgress: loaded => { if (loaded > 5 * 1024 * 1024) abort.abort(); } });
          if (blob.size < 5 * 1024 * 1024 && blob.type.startsWith('image/') && !disposed) {
            objectUrl = URL.createObjectURL(blob); setAvatar(objectUrl);
          }
        }
      } else if (groupId) {
        const page = await client.files.groupFiles(groupId, { limit: 30 });
        if (!disposed) { setFiles(page.items); setCursor(page.next_cursor); }
      }
    })().catch(e => { if (!disposed) setError(e instanceof Error ? e.message : String(e)); })
      .finally(() => { if (!disposed) setLoading(false); });
    return () => { disposed = true; abort.abort(); if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [client, groupId, member, retry]);
  useEffect(() => {
    if (!client || !member) return;
    return client.on('users.changed', event => {
      if (event.usernames.includes(member)) setProfile(client.users.get(member));
    });
  }, [client, member]);
  const more = async () => {
    if (!client || !groupId || !cursor || loading) return;
    setLoading(true); setError('');
    try {
      const page = await client.files.groupFiles(groupId, { cursor, limit: 30 });
      setFiles(previous => [...previous, ...page.items.filter(f => !previous.some(p => p.file_id === f.file_id))]);
      setCursor(page.next_cursor);
    } catch (e) { setError(e instanceof Error ? e.message : String(e)); }
    finally { setLoading(false); }
  };
  return <Dialog open onOpenChange={open => { if (!open) onClose(); }}>
    <DialogContent aria-describedby={undefined}>
      <DialogTitle>{t(member ? 'liveMeeting.room.chat.profile' : 'liveMeeting.room.chat.files')}</DialogTitle>
      {error && <div role="alert" className="break-words text-sm text-red-400">{error} <button className={buttonClass} onClick={() => setRetry(n => n + 1)}>{t('im.chats.retry')}</button></div>}
      {loading && <p role="status">{t('im.workbench.loading')}</p>}
      {member ? <div className="space-y-3 break-words">
        {avatar && <img src={avatar} alt="" className="h-16 w-16 rounded-full object-cover" />}
        <p>{profile?.nickname || member}</p><p className="break-all text-xs text-muted-foreground">{member}</p>
        {!loading && !profile && !error && <p>{t('im.workbench.empty')}</p>}
      </div> : <>
        <ul className="max-h-[55dvh] space-y-2 overflow-y-auto" data-testid="im-file-list">
          {files.map(file => <li key={file.file_id} className="flex items-center gap-2 rounded border p-3">
            <span className="min-w-0 flex-1 break-all text-sm">{file.name || file.file_id}<span className="block text-xs text-muted-foreground">{file.size} B · {file.owner_nickname || file.owner}</span></span>
            <button className={buttonClass} disabled={downloading} onClick={async () => {
              if (!client || download.current) return;
              const abort = new AbortController(); download.current = abort;
              setDownloading(true); setError('');
              try {
                if (!client.files.isFileUrl(file.url)) throw new Error(t('im.workbench.invalidAttachment'));
                await client.desktop.download(file.url, { signal: abort.signal });
              }
              catch (e) { setError(e instanceof Error ? e.message : String(e)); }
              finally { download.current = null; setDownloading(false); }
            }}>{t('im.workbench.download')}</button>
          </li>)}
        </ul>
        {!loading && !files.length && !error && <p>{t('im.workbench.empty')}</p>}
        {cursor && <button className={buttonClass} disabled={loading} onClick={() => void more()}>{t('liveMeeting.room.chat.moreFiles')}</button>}
      </>}
    </DialogContent>
  </Dialog>;
}
