'use client';
import Link from 'next/link';
import type { MessageView } from '@deeprespond/im-web';
import { useT } from '@/i18n';

const labels: Record<string, string> = {
  scheduled_created: '会议已预定', scheduled_updated: '会议预定已变更',
  scheduled_cancelled: '会议预定已取消', reminder: '会议即将开始',
  processing_completed: '会议纪要已生成', processing_failed: '会后处理失败，请查看会议记录',
};

/** A user custom message cannot masquerade as a business notification. */
export default function MeetingNotice({ message }: { message: MessageView }) {
  const t = useT();
  const body = message.body ?? {};
  const event = typeof body.event === 'string' ? body.event : '';
  const label = event === 'meeting_ended' ? t('meeting.shared.ended') : labels[event];
  if (message.sender !== 'notice' || body.kind !== 'openmeeting.meeting' || body.version !== 1 || !label) return null;
  const code = typeof body.code === 'string' && /^\d{4,6}$/.test(body.code) ? body.code : null;
  const meeting = typeof body.meetingId === 'string' && /^[\w-]{1,80}$/.test(body.meetingId) ? body.meetingId : null;
  return <div className="max-w-full space-y-2 rounded-lg border border-blue-400/30 p-3" data-testid="meeting-notice">
    <strong>{label}</strong>
    <p className="whitespace-pre-wrap break-words">{typeof body.title === 'string' ? body.title : ''}</p>
    {typeof body.startAt === 'string' && <p className="text-xs">{body.startAt}</p>}
    {code && event !== 'scheduled_cancelled' && <Link className="text-blue-400 underline" href={`/room?code=${code}`}>加入会议</Link>}
    {meeting && <Link className="text-blue-400 underline" href={`/meeting-details?id=${meeting}`}>查看会议记录</Link>}
  </div>;
}
