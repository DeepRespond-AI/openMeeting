import type { MessageView } from '@deeprespond/im-web';

/** Business sender identity is enforced by IM, never by an arbitrary body flag. */
export function isRoomInvalidation(message: MessageView, roomId: string): boolean {
  const body = message.body;
  return message.type === 'custom' && message.sender === 'notice' &&
    !message.recalled && !message.erased && body?.kind === 'openmeeting.meeting' &&
    body.version === 1 && body.event === 'room_state' && body.roomId === roomId &&
    typeof body.versionAt === 'string' && Number.isFinite(Date.parse(body.versionAt)) &&
    (body.reason === 'settings' || body.reason === 'host' || body.reason === 'recording');
}
