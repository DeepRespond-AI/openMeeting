'use client';
import { useState } from 'react';
import { useDRClient } from '@deeprespond/im-web-react';
import type { MessageView } from '@deeprespond/im-web';
import { useT } from '@/i18n';
import { MoreHorizontal } from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { ActionError, useImAction } from './useImAction';

/** Deletion only changes the current user's history. */
export default function MessageActions({ message }: { message: MessageView }) {
  const im = useDRClient(), t = useT();
  const [deleting, setDeleting] = useState(false);
  const { pending, error, run, setError } = useImAction();
  const id = message.conversation_id, seq = message.seq;
  const sent = message._local.status === 'sent';
  const own = !!message.sender && message.sender === im?.auth.currentUser?.username;
  const text = typeof message.body?.text === 'string' ? message.body.text : typeof message.body?.name === 'string' ? message.body.name : '';
  if (message.recalled || message.erased) return null;
  const recallError = () => {
    const seconds = im?.config?.recall_window_seconds ?? 120;
    return seconds > 0 && seconds % 60 === 0 ? t('im.message.recallExpiredMinutes', { minutes: seconds / 60 })
      : seconds > 0 ? t('im.message.recallExpiredSeconds', { seconds }) : t('im.message.recallUnavailable');
  };
  const feedback = (task: () => Promise<unknown>) => void run(async () => {
    try { await task(); }
    catch (e) {
      const reason = typeof e === 'object' && e !== null && 'reason' in e ? e.reason : '';
      toast.error(reason === 'recall_window_expired' ? recallError() : e instanceof Error ? e.message : t('im.workbench.failed'));
      throw e;
    }
  });
  return <>
    <DropdownMenu>
      <DropdownMenuTrigger asChild><button type="button" disabled={pending} aria-label={t('im.workbench.messageActions')}
        className="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:opacity-50"><MoreHorizontal className="h-4 w-4" /></button></DropdownMenuTrigger>
      <DropdownMenuContent align="end" side="bottom" className="min-w-24">
        <DropdownMenuItem disabled={!text || pending} onSelect={() => feedback(async () => {
          if (!navigator.clipboard?.writeText) throw new Error(t('im.message.copyFailed'));
          await navigator.clipboard.writeText(text); toast.success(t('common.actions.copied'));
        })}>{t('common.actions.copy')}</DropdownMenuItem>
        <DropdownMenuItem disabled={pending || !im || (sent ? !id || seq === null : !message.client_msg_id)} onSelect={() => { setError(''); setDeleting(true); }}>{t('common.actions.delete')}</DropdownMenuItem>
        {own && sent && id && seq !== null && <DropdownMenuItem disabled={pending} onSelect={() => feedback(async () => {
          if (!im) throw new Error(t('im.message.recallUnavailable'));
          if (!im.messages.canRecall(message)) throw new Error(recallError());
          await im.messages.recall(id, seq);
        })}>{t('im.workbench.recall')}</DropdownMenuItem>}
      </DropdownMenuContent>
    </DropdownMenu>
    <Dialog open={deleting} onOpenChange={open => { if (!pending) setDeleting(open); }}>
      <DialogContent className="max-w-[400px]">
        <DialogTitle>{t('im.message.deleteTitle')}</DialogTitle>
        <DialogDescription>{t('im.message.deleteDescription')}</DialogDescription>
        <ActionError error={error} />
        <div className="flex justify-end gap-3">
          <Button variant="outline" disabled={pending} onClick={() => setDeleting(false)}>{t('common.actions.cancel')}</Button>
          <Button disabled={pending} onClick={() => void run(async () => {
            if (!im) throw new Error(t('im.workbench.failed'));
            if (sent && id && seq !== null) await im.messages.deleteForMe(id, [seq]);
            else if (message.client_msg_id) await im.messages.discard(message.client_msg_id);
            else throw new Error(t('im.workbench.failed'));
            setDeleting(false);
          })}>{pending ? t('im.workbench.working') : t('common.actions.confirm')}</Button>
        </div>
      </DialogContent>
    </Dialog>
  </>;
}
