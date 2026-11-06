'use client';

import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { useIm } from '@/contexts/IMContext';
import { useT } from '@/i18n';
import { subscribeMeetingRecordNotices } from '@/services/live-meeting/record-notices';

/** IM owns offline delivery/history. This bridge only refreshes records and shows a link. */
export default function MeetingRecordNotifications() {
  const { client, status } = useIm();
  const router = useRouter();
  const t = useT();
  const seen = useRef(new Set<string>());
  useEffect(() => {
    if (!client || status !== 'ready') return;
    return subscribeMeetingRecordNotices(client, message => {
      const body = message.body!;
      const key = body.event === 'meeting_ended' ? 'meeting.shared.ended'
        : body.event === 'processing_completed' ? 'meeting.shared.completed'
        : body.event === 'processing_failed' ? 'meeting.shared.failed' : null;
      if (!key) return;
      window.dispatchEvent(new Event('meeting-records-changed'));
      const meetingId = String(body.meetingId);
      toast(t(key), { description: typeof body.title === 'string' ? body.title : undefined,
        action: { label: t('meeting.shared.view'), onClick: () => {
          if (message.conversation_id && message.seq != null) client.conversations.markRead(message.conversation_id, { seq: message.seq });
          router.push(`/meeting-details?id=${meetingId}`);
        } },
        duration: 10000 });
    }, seen.current);
  }, [client, status, router, t]);
  return null;
}
