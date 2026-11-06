import type { DRTauriClient, MessageView } from '@deeprespond/im-tauri';

export function isMeetingRecordNotice(message: MessageView) {
  const body = message.body;
  return message.type === 'custom' && message.sender === 'notice' && !message.recalled && !message.erased
    && body?.kind === 'openmeeting.meeting' && body.version === 1
    && typeof body.meetingId === 'string' && /^[\w-]{1,80}$/.test(body.meetingId)
    && ['meeting_ended', 'processing_completed', 'processing_failed'].includes(String(body.event));
}

/** SDK owns durable history/read positions. Memory only deduplicates visible notices. */
export function subscribeMeetingRecordNotices(
  client: DRTauriClient,
  show: (message: MessageView) => void,
  seen: Set<string>,
) {
  let disposed = false;
  const histories = new Map<string, () => void>();
  const deliver = (message: MessageView) => {
    if (disposed || !isMeetingRecordNotice(message)) return;
    const id = `${message.conversation_id}:${message.seq}`;
    if (seen.has(id)) return;
    if (seen.size >= 500) seen.delete(seen.values().next().value!);
    seen.add(id); show(message);
  };
  const offLive = client.on('message.received', ({ message }) => deliver(message));
  const conversations = client.conversations.list();
  const update = () => {
    if (disposed) return;
    for (const conversation of conversations.getSnapshot().items) {
      if (conversation.peer !== 'notice' || !conversation.conversation_id || histories.has(conversation.conversation_id)) continue;
      const id = conversation.conversation_id;
      const messages = client.messages.open(conversation.conversation_key);
      const readHistory = () => {
        // Notices intentionally do not increment unread_count. The SDK read
        // position still records explicit acknowledgement across devices.
        const current = conversations.getSnapshot().items.find(c => c.conversation_id === id);
        const readSeq = current?.state?.read_seq ?? 0;
        const latest = new Map<string, MessageView>();
        for (const message of [...messages.getSnapshot().items].reverse()) {
          if (!isMeetingRecordNotice(message) || (message.seq ?? 0) <= readSeq) continue;
          const meetingId = String(message.body!.meetingId);
          if (!latest.has(meetingId)) latest.set(meetingId, message);
          if (latest.size >= 3) break;
        }
        for (const message of [...latest.values()].reverse()) deliver(message);
      };
      const off = messages.subscribe(readHistory);
      histories.set(id, () => { off(); messages.dispose(); });
      readHistory();
    }
  };
  const offConversations = conversations.subscribe(update);
  update();
  return () => {
    disposed = true; offLive(); offConversations(); conversations.dispose();
    for (const close of histories.values()) close();
  };
}
