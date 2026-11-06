import { describe, expect, test } from 'bun:test';
import { subscribeMeetingRecordNotices } from '../../src/services/live-meeting/record-notices';

const notice = (seq: number, meetingId = 'meeting-test', event = 'meeting_ended') => ({
  conversation_id: 'notice-conversation', seq, sender: 'notice', type: 'custom',
  body: { kind: 'openmeeting.meeting', version: 1, event, meetingId },
});
function sdk(items: any[] = [], readSeq = 0) {
  const live = new Set<Function>(), history = new Set<Function>(), conversations = new Set<Function>();
  const disposed: string[] = [];
  const messageList = { getSnapshot: () => ({ items }), subscribe: (fn: Function) => { history.add(fn); return () => history.delete(fn); }, dispose: () => disposed.push('messages') };
  const list = { getSnapshot: () => ({ items: [{ conversation_id: 'notice-conversation', conversation_key: 'notice-conversation', peer: 'notice', unread_count: 0, state: { read_seq: readSeq } }] }), subscribe: (fn: Function) => { conversations.add(fn); return () => conversations.delete(fn); }, dispose: () => disposed.push('conversations') };
  const client: any = { on: (_: string, fn: Function) => { live.add(fn); return () => live.delete(fn); }, conversations: { list: () => list }, messages: { open: () => messageList } };
  return { client, disposed, live, history, conversations, receive: (message: any) => live.forEach(fn => fn({ message })), hydrate: (messages: any[]) => { items = messages; history.forEach(fn => fn()); } };
}

describe('meeting record notifications from IM history', () => {
  test('reconnect surfaces persisted notices without a realtime event or unread increment', () => {
    const im = sdk([notice(1)]), seen = new Set<string>(), shown: any[] = [];
    const close = subscribeMeetingRecordNotices(im.client, m => shown.push(m), seen);
    expect(shown.map(m => m.seq)).toEqual([1]); close();
  });
  test('late history hydration surfaces the notice after login', () => {
    const im = sdk(), shown: any[] = [];
    const close = subscribeMeetingRecordNotices(im.client, m => shown.push(m), new Set());
    im.hydrate([notice(2)]); expect(shown.map(m => m.seq)).toEqual([2]); close();
  });
  test('SDK read positions suppress acknowledged messages', () => {
    const im = sdk([notice(1, 'meeting-one'), notice(2, 'meeting-two')], 1), shown: any[] = [];
    const close = subscribeMeetingRecordNotices(im.client, m => shown.push(m), new Set());
    expect(shown.map(m => m.seq)).toEqual([2]); close();
  });
  test('history and realtime duplicates stay deduplicated across reconnects', () => {
    const im = sdk([notice(1)]), seen = new Set<string>(), shown: any[] = [];
    const close = subscribeMeetingRecordNotices(im.client, m => shown.push(m), seen);
    im.receive(notice(1)); close(); const again = subscribeMeetingRecordNotices(im.client, m => shown.push(m), seen);
    expect(shown.length).toBe(1); again();
  });
  test('forgeries, erased messages and unrelated events cannot open a record notice', () => {
    const im = sdk([{ ...notice(1), sender: 'attacker' }, { ...notice(2), erased: true }, notice(3, 'meeting-one', 'room_state'), notice(4, '../bad')]), shown: any[] = [];
    const close = subscribeMeetingRecordNotices(im.client, m => shown.push(m), new Set());
    expect(shown.length).toBe(0); close();
  });
  test('backlog shows latest status per meeting with a bounded number of popups', () => {
    const im = sdk([notice(1, 'meeting-a'), notice(2, 'meeting-b'), notice(3, 'meeting-c'), notice(4, 'meeting-d'), notice(5, 'meeting-d', 'processing_failed')]), shown: any[] = [];
    const close = subscribeMeetingRecordNotices(im.client, m => shown.push(m), new Set());
    expect(shown.map(m => m.seq)).toEqual([2, 3, 5]); close();
    expect(im.live.size + im.history.size + im.conversations.size).toBe(0);
    expect(im.disposed.sort()).toEqual(['conversations', 'messages']);
  });
});
