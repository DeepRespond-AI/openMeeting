'use client';
import type { MessageView } from '@deeprespond/im-web';
import { useT } from '@/i18n';
import MeetingNotice from './MeetingNotice';
import AttachmentMessage from './AttachmentMessage';
import Link from 'next/link';

/** Only SDK-validated attachment references reach the authenticated file APIs. */
export default function MessageContent({ message }: { message: MessageView }) {
  const t = useT(), body = message.body ?? {};
  if (message.recalled)
    return <span className="italic opacity-60">{t('im.chats.recalled')}</span>;
  if (message.type === 'custom' && message.sender === 'notice' && body.kind === 'openmeeting.meeting')
    return <MeetingNotice message={message} />;
  if (message.type === 'custom' && body.kind === 'openmeeting.invitation' && body.version === 1 &&
    typeof body.code === 'string' && /^\d{4,6}$/.test(body.code))
    return <div className="space-y-2 rounded-lg border border-blue-400/30 p-3">
      <strong>{t('liveMeeting.room.chat.inviteIm')}</strong>
      <p className="break-words">{typeof body.title === 'string' ? body.title : ''}</p>
      <p className="text-xs">{body.code}</p>
      <Link className="text-blue-400 underline" href={`/room?code=${body.code}`}>{t('liveMeeting.join.title')}</Link>
    </div>;
  if (message.type === 'text')
    return (
      <span className="whitespace-pre-wrap break-words">
        {typeof body.text === 'string' ? body.text : ''}
      </span>
    );
  if (message.type === 'location')
    return (
      <div className="max-w-full space-y-1 break-words">
        <strong>
          {typeof body.name === 'string'
            ? body.name
            : t('im.workbench.location')}
        </strong>
        <p>{typeof body.address === 'string' ? body.address : ''}</p>
        <p className="text-xs">
          {String(body.latitude ?? '—')}, {String(body.longitude ?? '—')}
        </p>
      </div>
    );
  if (!['image', 'video', 'voice', 'file'].includes(message.type))
    return (
      <span className="break-words">
        {typeof body.text === 'string' ? body.text : `[${message.type}]`}
      </span>
    );
  return <AttachmentMessage key={String(message.message_id)+String(body.url)} message={message} />;
}
