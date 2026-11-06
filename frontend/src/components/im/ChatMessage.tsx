'use client';
import type { MessageView } from '@deeprespond/im-web';
import { useDRClient } from '@deeprespond/im-web-react';
import { useI18n } from '@/i18n';
import { cn } from '@/lib/utils';
import { toast } from 'sonner';
import { ImUserAvatar, useImUser } from './ImUserAvatar';
import MessageActions from './MessageActions';
import MessageContent from './MessageContent';

export function showMessageTime(message: MessageView, previous?: MessageView): boolean {
  const time = Date.parse(message.created_at ?? ''), before = Date.parse(previous?.created_at ?? '');
  return Number.isFinite(time) && (!Number.isFinite(before) || time - before >= 5 * 60_000 || new Date(time).toDateString() !== new Date(before).toDateString());
}

/** Avatar and name outside the bubble; timestamps and recalls are conversation notices. */
export default function ChatMessage({ message, name, own, showTime = false, testId = 'im-meeting-message' }:
  { message: MessageView; name?: string; own: boolean; showTime?: boolean; testId?: string }) {
  const { t, locale } = useI18n();
  const im = useDRClient();
  const profile = useImUser(message.sender ?? '', name);
  if (message.erased) return null;
  const date = new Date(message.created_at ?? '');
  const time = !Number.isNaN(date.getTime()) && showTime ? <time dateTime={message.created_at!} title={date.toLocaleString(locale)} className="block py-3 text-center text-[11px] text-muted-foreground">
    {date.toDateString() === new Date().toDateString() ? date.toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit', hour12: false }) : date.toLocaleString(locale, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false })}
  </time> : null;
  if (message.recalled) return <div data-testid={testId} className="w-full min-w-0">{time}<p data-testid="recalled-message" role="status" className="break-words py-3 text-center text-xs text-muted-foreground">
    {own ? t('im.message.recalledSelf') : t('im.message.recalledOther', { name: profile.name })}
  </p></div>;
  return <div data-testid={testId} className="w-full min-w-0">{time}
    <article className={cn('group flex min-w-0 items-start gap-2 py-1 text-[13px]', own ? 'flex-row-reverse' : '')}>
      <ImUserAvatar username={message.sender ?? ''} name={name} size="sm" className="h-8 w-8" />
      <div className={cn('flex min-w-0 max-w-[calc(100%-2.5rem)] flex-col gap-1', own ? 'items-end' : 'items-start')}>
        <span data-testid="message-sender-name" title={profile.name} className="max-w-full truncate text-[11px] text-muted-foreground">{profile.name}</span>
        <div className={cn('flex min-w-0 max-w-full items-start gap-1', own ? 'flex-row-reverse' : '')}>
          <div data-testid="message-bubble" className={cn('min-w-0 overflow-hidden rounded-sm px-3 py-2 leading-relaxed [overflow-wrap:anywhere]',
            own ? 'bg-primary text-primary-foreground' : 'border border-border bg-card text-card-foreground')}>
            <MessageContent message={message} />
          </div>
          <MessageActions message={message} />
        </div>
        {message._local.status !== 'sent' && <div role="status" className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
          <span className={message._local.status === 'failed' ? 'text-destructive' : ''}>{t(`im.workbench.status_${message._local.status}`)}</span>
          {message._local.status === 'failed' && message.client_msg_id && <button type="button" className="underline" onClick={() => void im?.messages.resend(message.client_msg_id!).catch(error => toast.error(error instanceof Error ? error.message : t('im.workbench.failed')))}>{t('im.chats.retry')}</button>}
        </div>}
      </div>
    </article>
  </div>;
}
