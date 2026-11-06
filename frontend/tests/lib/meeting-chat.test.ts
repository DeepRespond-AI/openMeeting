import { expect, test } from 'bun:test';
import { ImMeetingChat } from '../../src/services/live-meeting/chat';

function fixture() {
  const rooms = new Map<string, any[]>();
  const listeners = new Map<string, () => void>();
  const removed: string[] = [];
  let release: ((value: any) => void) | undefined;
  const client: any = {
    config: {}, on: () => () => {},
    conversations: {
      refresh: async (id: string) => ({ conversation_id: id, conversation_key: id }),
      get: async () => ({ unread_count: 0 }), remove: async (id: string) => { removed.push(id); },
    },
    messages: {
      open: (id: string) => ({
        getSnapshot: () => ({ items: rooms.get(id) ?? [], loading: 'none', hasOlder: false }),
        subscribe: (fn: () => void) => { listeners.set(id, fn); return () => { listeners.delete(id); }; },
        dispose() {}, setViewing() {}, markRead() {},
      }),
      send: async (target: any, content: any) => { rooms.set(target.to_group, [{ ...content, sender: 'self', _local: {status:'sent'} }]); listeners.get(target.to_group)?.(); },
    },
    files: { upload: (_file: any, options: any) => new Promise((resolve, reject) => {
      release = resolve; options.signal.addEventListener('abort', () => reject(Error('cancelled')));
    }) },
  };
  const create = (id: string, reports: any[]) => new ImMeetingChat(client, `room-${id}`, id, 'self', () => [], state => reports.push(state));
  return { client, create, rooms, listeners, removed, resolveUpload: () => release?.({url:'file',size:1}) };
}

test('tips are excluded; ending hides only this chat and next meeting starts empty', async () => {
  const f = fixture(), first: any[] = [], next: any[] = [];
  f.rooms.set('one', [{ type: 'tip', body: {} }, { type: 'text', body: {text:'previous meeting'}, sender:'self' }]);
  const old = f.create('one', first); await old.connect();
  expect(first.at(-1).messages.map((m: any) => m.text)).toEqual(['previous meeting']);
  await old.close(); expect(f.removed).toEqual(['one']);
  const current = f.create('two', next); await current.connect();
  expect(next.at(-1).messages).toEqual([]);
  expect(f.listeners.has('one')).toBe(false);
  await expect(old.sendText('late')).rejects.toThrow('closed'); current.dispose();
});

test('ending aborts file upload before it can send into the closed meeting', async () => {
  const f = fixture(), reports: any[] = [], chat = f.create('one', reports);
  await chat.connect();
  const task = chat.sendFile(new File(['data'], 'report.txt', { type: 'text/plain' }), () => {});
  await chat.close();
  await expect(task).rejects.toThrow('cancelled');
  f.resolveUpload(); expect(f.rooms.has('one')).toBe(false);
});

test('an obsolete connection cannot report messages after disposal', async () => {
  const f = fixture(), reports: any[] = [];
  let resolve!: (value: any) => void;
  f.client.conversations.refresh = () => new Promise(r => { resolve = r; });
  const chat = f.create('one', reports), connecting = chat.connect(); chat.dispose();
  resolve({ conversation_key: 'one', conversation_id: 'one' }); await connecting;
  expect(reports).toEqual([]); expect(f.listeners.size).toBe(0);
});
