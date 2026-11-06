import type { DRTauriClient } from '@deeprespond/im-tauri';
import type { MessageList, MessageView } from '@deeprespond/im-web';
import type { ChatAttachment, ChatMessage, Participant } from './types';

export interface MeetingChatState {
  status: 'connecting' | 'ready' | 'error';
  messages: ChatMessage[];
  hasOlder: boolean;
  loadingOlder: boolean;
  unread: number;
  error?: string;
}

/** SDK owns history, delivery, retries and storage. This only adapts the room UI. */
export class ImMeetingChat {
  private list: MessageList | null = null;
  private unsubscribe: (() => void) | null = null;
  private disposed = false;
  private upload: AbortController | null = null;
  private downloads = new Set<AbortController>();
  private cleanups: (() => void)[] = [];
  private viewing = false;
  private atBottom = true;
  private unread = 0;
  private update = () => {};
  private unreadEpoch = 0;
  private conversationId: string | null = null;

  constructor(
    private client: DRTauriClient,
    private roomId: string,
    private groupId: string,
    private selfUsername: string,
    private participants: () => readonly Participant[],
    private report: (state: MeetingChatState) => void,
  ) {}

  async connect() {
    const view = await this.client.conversations.refresh(this.groupId);
    if (this.disposed) return;
    this.conversationId = view.conversation_id;
    this.list = this.client.messages.open(view.conversation_key);
    // The room opens this list before the chat panel is visible.
    this.syncViewing();
    this.unread = view.unread_count ?? 0;
    const update = () => {
      if (this.disposed || !this.list) return;
      const snapshot = this.list.getSnapshot();
      this.report({
        status: snapshot.error ? 'error' : snapshot.loading === 'initial' ? 'connecting' : 'ready',
        error: snapshot.error?.message,
        // Membership tips belong to the members panel, not chat bubbles.
        messages: snapshot.items.filter(m => !m.erased && m.type !== 'tip').map(m => this.message(m)),
        hasOlder: snapshot.hasOlder,
        loadingOlder: snapshot.loading === 'older',
        unread: this.unread,
      });
    };
    this.unsubscribe = this.list.subscribe(update);
    this.update = update;
    this.cleanups.push(this.client.on('conversations.changed', () => {
      const epoch = ++this.unreadEpoch;
      void this.client.conversations.get(view.conversation_id!).then(latest => {
        if (this.disposed || epoch !== this.unreadEpoch) return;
        this.unread = latest?.unread_count ?? 0;
        update();
      }).catch(() => { /* retain last confirmed unread until SDK recovers */ });
    }));
    if (typeof document !== 'undefined') {
      const sync = () => this.syncViewing();
      document.addEventListener('visibilitychange', sync);
      window.addEventListener('focus', sync);
      window.addEventListener('blur', sync);
      this.cleanups.push(() => {
        document.removeEventListener('visibilitychange', sync);
        window.removeEventListener('focus', sync);
        window.removeEventListener('blur', sync);
      });
    }
    update();
  }

  private message(m: MessageView): ChatMessage {
    const participant = this.participants().find(p => p.userId === m.sender);
    const body = m.body ?? {};
    const attachment = ['file', 'image', 'video', 'voice'].includes(m.type) && typeof body.url === 'string'
      ? { url: body.url, name: typeof body.name === 'string' ? body.name : m.type,
          size: typeof body.size === 'number' ? body.size : 0 }
      : null;
    return {
      sdk: m,
      id: m.client_msg_id || m.message_id || `seq:${m.seq}`,
      sequence: m.seq ?? undefined,
      roomId: this.roomId,
      sender: { id: m.sender ?? 'system', name: participant?.name ?? m.sender ?? 'System',
        isSelf: m.sender === this.selfUsername },
      text: attachment ? '' : typeof body.text === 'string' ? body.text : `[${m.type}]`,
      attachment,
      createdAt: m.created_at ?? '',
    };
  }

  setViewing(visible: boolean) {
    this.viewing = visible;
    this.syncViewing();
  }

  setAtBottom(atBottom: boolean) { this.atBottom = atBottom; this.syncViewing(); }

  private syncViewing() {
    const focused = typeof document === 'undefined' || (document.visibilityState === 'visible' && document.hasFocus());
    const visible = this.viewing && focused;
    const latest = this.atBottom && !this.list?.getSnapshot().hasNewer;
    this.list?.setViewing({ visible, atBottom: latest });
    if (visible && latest) this.list?.markRead();
  }

  async loadOlder() { await this.list?.loadOlder(); }

  async sendText(text: string, replyTo?: number) {
    if (this.disposed) throw new Error('Chat closed');
    await this.client.messages.send({ to_group: this.groupId },
      { type: 'text', body: { text } }, { waitUntil: 'sent',
        ...(replyTo !== undefined ? { reply_to: { seq: replyTo } } : {}) });
  }

  async sendFile(file: File, progress: (percent: number) => void) {
    if (this.disposed) throw new Error('Chat closed');
    if (this.upload) throw new Error('Upload already in progress');
    const controller = new AbortController();
    this.upload = controller;
    const kind = file.type?.startsWith('image/') ? 'image' : file.type?.startsWith('video/') ? 'video' : 'file';
    try {
      // Group-file upload returns FileInfo without video duration. Preserve the
      // metadata from SDK preparation for the subsequent video message.
      const prepared = kind === 'video' ? await this.client.files.prepare(file, 'video') : null;
      if (this.disposed || controller.signal.aborted) throw new Error('Upload cancelled');
      const info = await this.client.files.upload(prepared?.blob ?? file, {
        purpose: 'group_file', group_id: this.groupId, kind, name: file.name,
        signal: controller.signal,
        onProgress: (loaded, total) => { if (!this.disposed && total) progress(Math.round(loaded / total * 100)); },
      });
      if (this.disposed || controller.signal.aborted) throw new Error('Upload cancelled');
      await this.client.messages.send({ to_group: this.groupId }, {
        type: kind, body: { url: info.url, name: info.name ?? file.name, size: info.size,
          ...(prepared ? {duration_seconds: prepared.duration_seconds ?? 0, format: prepared.format,
            ...(prepared.width ? {width: prepared.width, height: prepared.height} : {})} : {}),
          ...(info.width ? { width: info.width, height: info.height } : {}) },
      }, { waitUntil: 'sent' });
    } finally { if (this.upload === controller) this.upload = null; }
  }

  cancelUpload() { this.upload?.abort(); }

  /** Hide this session's SDK conversation without touching unrelated chats. */
  async close() {
    this.dispose();
    if (this.conversationId) await this.client.conversations.remove(this.conversationId);
  }

  async download(attachment: ChatAttachment) {
    if (this.disposed || !attachment.url || !this.client.files.isFileUrl(attachment.url)) {
      throw new Error('Invalid attachment');
    }
    const controller = new AbortController();
    this.downloads.add(controller);
    try {
      // The native SDK resolves IM references and streams to disk without a Blob copy.
      await this.client.desktop.download(attachment.url, { signal: controller.signal });
    } finally { this.downloads.delete(controller); }
  }

  dispose() {
    this.disposed = true;
    this.cancelUpload();
    this.downloads.forEach(controller => controller.abort());
    this.downloads.clear();
    this.unsubscribe?.();
    this.cleanups.forEach(cleanup => cleanup());
    this.list?.dispose();
    this.list = null;
  }
}
