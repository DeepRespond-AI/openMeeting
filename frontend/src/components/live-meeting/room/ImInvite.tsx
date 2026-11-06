'use client';
import { useState } from 'react';
import { useIm } from '@/contexts/IMContext';
import { useT } from '@/i18n';
import { ActionError, buttonClass, inputClass, useImAction } from '@/components/im/useImAction';

export default function ImInvite({ code, title }: { code: string; title: string }) {
  const { client } = useIm(), t = useT(), { pending, error, run } = useImAction();
  const [recipient, setRecipient] = useState(''), [sent, setSent] = useState(false);
  return <form className="space-y-2" onSubmit={e => {
    e.preventDefault(); setSent(false);
    void run(async () => {
      if (!client) return;
      await client.messages.send({ to_user: recipient.trim() }, { type: 'custom',
        body: { kind: 'openmeeting.invitation', version: 1, title, code } }, { waitUntil: 'sent' });
      setSent(true);
    });
  }}>
    <label className="block space-y-1 text-xs"><span>{t('liveMeeting.room.chat.inviteIm')}</span>
      <input className={inputClass} aria-label={t('im.workbench.username')} value={recipient} required maxLength={80} onChange={e => { setRecipient(e.target.value); setSent(false); }} placeholder={t('im.workbench.username')} />
    </label>
    <button className={buttonClass} disabled={pending || !client || !recipient.trim()}>{t('liveMeeting.room.chat.sendInvite')}</button>
    <ActionError error={error} />
    {sent && <p role="status" className="text-xs text-green-400">{t('liveMeeting.room.chat.inviteSent')}</p>}
  </form>;
}
