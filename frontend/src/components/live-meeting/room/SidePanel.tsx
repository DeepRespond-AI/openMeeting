'use client';
import { meetingUi } from '@/config/meeting-ui';

/**
 * Right slide-out panel (V2 design, prototype room.js): members/chat tabs.
 * Members tab — waiting-room block with admit/deny (host), member rows with host
 * badge, raised hands with approve, mute-all. Chat tab — message list (own gradient
 * bubbles / file cards), emoji picker (3 categories), file sending, input row.
 */
import { useEffect, useRef, useState } from 'react';
import { Mic, MicOff, Paperclip, Send, Smile, X } from 'lucide-react';
import { toast } from 'sonner';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { useRoom } from './RoomProvider';
import ImMessage from './ImMessage';
import { showMessageTime } from '@/components/im/ChatMessage';
import ImResources from './ImResources';
import MicrophoneIndicator from './MicrophoneIndicator';
import { useIm } from '@/contexts/IMContext';
import { usePathname } from 'next/navigation';

const EMOJI_GROUPS = [
  ['😀', '😁', '😂', '🤣', '😊', '😇', '🙂', '😉', '😍', '🤩', '😘', '😋', '🤪', '🤨', '🤓', '😎', '🥳', '😏', '😌', '😔', '😴', '🥱', '😅', '🤔'],
  ['👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙', '👈', '👉', '👆', '👇', '☝️', '✋', '🖐️', '🖖', '👋', '🤝', '🙏', '💪', '👏', '🙌', '👐', '✊'],
  ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '💯', '🔥', '✨', '⭐', '💫', '💥', '🎉', '🎊', '🎈', '✅', '❌', '⚠️', '❓', '❗', '💬', '👀', '🚀'],
];
const EMOJI_TABS = ['😀', '👍', '❤️'];

function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1048576).toFixed(1)} MB`;
}

function fileIconColor(name: string): string {
  const ext = (name.split('.').pop() ?? '').toLowerCase();
  if (/^pdf$/.test(ext)) return '#F87171';
  if (/^(doc|docx|txt|md|pages)$/.test(ext)) return '#60A5FA';
  if (/^(xls|xlsx|csv|numbers)$/.test(ext)) return '#4ADE80';
  if (/^(png|jpg|jpeg|gif|webp|svg|heic)$/.test(ext)) return '#C084FC';
  if (/^(zip|rar|7z|tar|gz|dmg)$/.test(ext)) return '#FBBF24';
  if (/^(mp4|mov|avi|mkv)$/.test(ext)) return '#F472B6';
  if (/^(mp3|wav|m4a|aac|flac)$/.test(ext)) return '#4CC3FF';
  return '#94A3B8';
}

function fileIcon(name: string): React.ReactNode {
  return (
    <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={fileIconColor(name)} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" />
      <path d="M14 2v4a2 2 0 0 0 2 2h4" />
    </svg>
  );
}

function formatMsgTime(iso: string): string {
  const d = new Date(iso);
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

export default function SidePanel() {
  const t = useT();
  const { client } = useIm();
  const pathname = usePathname();
  const {
    room, self, isHost, chatGroupId, panelTab, messages, setPanelTab, audioLevels,
    admit, deny, approveHand, setAllMuted, chatReply, setChatReply, sendChat, sendFile,downloadFile,fileSending,
    setChatAtBottom, chatStatus, chatError, retryChat, chatHasOlder, chatLoadingOlder, loadOlderChat, fileProgress, cancelFile,
  } = useRoom();
  const [resource, setResource] = useState<{member: string | null} | null>(null);
  const [emojiTab, setEmojiTab] = useState(0);
  const [emojiOpen, setEmojiOpen] = useState(false);
  const [draft, setDraft] = useState('');
  const [sending, setSending] = useState(false);
  const textPending = useRef(false);
  const [muteAllPending, setMuteAllPending] = useState(false);
  const listRef = useRef<HTMLDivElement>(null);
  const atBottom = useRef(true);
  const historyAnchor = useRef<{ height: number; top: number; count: number } | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const open = panelTab !== null;
  const isChat = panelTab === 'chat';

  // Opening chat is a deliberate refresh boundary for the SDK's profile cache.
  useEffect(() => {
    if (!isChat || pathname !== '/room' || !client || !room || chatStatus !== 'ready') return;
    const usernames = room.participants.flatMap(p => p.userId ? [p.userId] : []);
    if (usernames.length) void client.users.fetch(usernames, {force:true}).catch(() => {});
  }, [isChat, pathname, client, chatStatus, room?.id]);

  useEffect(() => {
    const list = listRef.current;
    if (!isChat || !list) return;
    if (historyAnchor.current) {
      const anchor = historyAnchor.current;
      if (messages.length > anchor.count) {
        list.scrollTop = anchor.top + list.scrollHeight - anchor.height;
        historyAnchor.current = null;
      } else if (!chatLoadingOlder) historyAnchor.current = null;
      return;
    }
    if (atBottom.current) list.scrollTop = list.scrollHeight;
  }, [isChat, messages, chatLoadingOlder]);

  const loadHistory = () => {
    const list = listRef.current;
    if (list) historyAnchor.current = { height: list.scrollHeight, top: list.scrollTop, count: messages.length };
    atBottom.current = false;
    setChatAtBottom(false);
    void loadOlderChat();
  };

  if (!room || !self || !open || (isChat ? !meetingUi.chat : !meetingUi.members)) return null;

  const others = room.participants.filter((p) => !p.isSelf);
  const hasHostMutedMembers = room.participants.some((p) => !p.isHost && p.mutedByHost);

  const doSend = () => {
    const text = draft.trim();
    if (!text || textPending.current || chatStatus !== 'ready') return;
    textPending.current = true; setSending(true);
    void sendChat(text).then(() => setDraft(current => current === text ? '' : current)).catch((error) => {
      toast.error(error instanceof Error ? error.message : t('liveMeeting.room.errors.generic'));
    }).finally(() => { textPending.current = false; setSending(false); });
    inputRef.current?.focus();
  };

  const memberRow = (p: typeof self, key: string) => (
    <div key={key} className="flex items-center gap-3 rounded-lg px-3 py-2 transition-colors hover:bg-white/5">
      <button type="button" aria-label={`${t('liveMeeting.room.chat.profile')}: ${p.name}`} disabled={!meetingUi.chat || !p.userId} onClick={() => setResource({member: p.userId!})}
        className="flex h-8 w-8 shrink-0 select-none items-center justify-center rounded-full text-xs font-semibold text-white"
        style={{ background: p.isSelf ? 'linear-gradient(135deg,#6366f1,#3b82f6)' : 'rgba(255,255,255,0.1)' }}
      >
        {(p.isSelf ? t('liveMeeting.room.tile.me') : p.name).charAt(0)}
      </button>
      <span className="min-w-0 flex-1 truncate text-sm text-white/90">
        {p.isSelf ? `${t('liveMeeting.room.tile.me')}（${self.name}）` : p.name}
      </span>
      {meetingUi.handRaise && (p.handRaised || (p.isSelf && self.handRaised)) && (
        <span className="shrink-0 text-[14px]" title={t('liveMeeting.room.tile.hand')}>✋</span>
      )}
      {p.isHost && (
        <span className="shrink-0 rounded bg-white/10 px-1.5 py-0.5 text-[10px] text-white/55">
          {t('liveMeeting.room.member.host')}
        </span>
      )}
      {meetingUi.audio && <MicrophoneIndicator muted={!p.micOn || !!p.mutedByHost} level={audioLevels[p.id]} />}
      {meetingUi.handRaise && !p.isSelf && p.handRaised && isHost && (
        <button
          type="button"
          onClick={() => { void approveHand(p.id).then((ok) => { if (ok) toast.success(t('liveMeeting.room.hand.approveToast', { name: p.name })); }); }}
          className="ml-1 shrink-0 rounded-md bg-[#FBBF24]/15 px-2 py-1 text-[11px] font-medium text-[#FBBF24] transition-colors hover:bg-[#FBBF24]/25"
        >
          {t('liveMeeting.room.member.approve')}
        </button>
      )}
    </div>
  );

  return (
    <div
      className={cn(
        'absolute right-0 inset-y-0 z-30 flex h-full min-h-0 w-[min(24rem,100%)] shrink-0 flex-col border-l border-border bg-background shadow-elevated lg:relative lg:inset-auto lg:w-[360px]',
      )}
      aria-hidden={!open}
      data-testid="room-side-panel"
    >
      {meetingUi.chat && resource && <ImResources groupId={chatGroupId} member={resource.member} onClose={() => setResource(null)} />}
      {/* Tabs header */}
      <div className="relative shrink-0 border-b border-white/[0.08] px-3 pt-3">
        <div className="flex pr-8">
          {(['members', 'chat'] as const).filter(tab => meetingUi[tab]).map((tab) => (
            <button
              key={tab}
              type="button"
              onClick={() => setPanelTab(panelTab === tab ? null : tab)}
              className={cn(
                'relative flex-1 pb-2.5 text-[13px] font-medium transition-colors',
                panelTab === tab ? 'text-white' : 'text-white/40 hover:text-white/75',
              )}
            >
              {tab === 'members'
                ? `${t('liveMeeting.room.toolbar.members')}（${room.participants.length}）`
                : t('liveMeeting.room.toolbar.chat')}
              <span className={cn('absolute inset-x-3 bottom-0 h-0.5 rounded-full', panelTab === tab ? 'bg-brand-gradient' : 'bg-transparent')} />
            </button>
          ))}
        </div>
        <button
          type="button"
          aria-label={t('common.actions.close')}
          onClick={() => setPanelTab(null)}
          className="absolute right-2.5 top-2.5 inline-flex h-7 w-7 items-center justify-center rounded-lg text-white/50 transition-colors hover:bg-white/10 hover:text-white"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      {isChat ? (
        <>
          {chatStatus !== 'ready' && <div className="border-b border-white/10 px-3 py-2 text-xs text-white/70" role="status">
            {chatStatus === 'connecting' ? t('liveMeeting.room.chat.connecting') : chatError || t('liveMeeting.room.chat.unavailable')}
            {chatStatus === 'error' && <button type="button" onClick={retryChat} className="ml-2 underline">{t('liveMeeting.room.chat.retry')}</button>}
          </div>}
          {chatGroupId && <button className="shrink-0 border-b border-white/10 px-3 py-2 text-left text-xs text-white/70" onClick={() => setResource({member: null})}>{t('liveMeeting.room.chat.files')}</button>}
          {/* Chat messages */}
          <div ref={listRef}
            onScroll={e => {
              const el = e.currentTarget;
              atBottom.current = el.scrollHeight - el.scrollTop - el.clientHeight < 40;
              setChatAtBottom(atBottom.current);
            }} className="custom-scrollbar flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto bg-muted/20 px-3 py-3">
            {chatHasOlder && <button type="button" disabled={chatLoadingOlder} onClick={loadHistory} className="self-center text-xs text-white/60 underline disabled:opacity-50">{t('liveMeeting.room.chat.older')}</button>}
            {messages.length ? messages.map((m, index) => (
              m.sdk ? <ImMessage key={m.id} message={m} showTime={showMessageTime(m.sdk, messages[index - 1]?.sdk)} /> : m.attachment ? (
                m.sender.isSelf ? (
                  <div key={m.id} className="flex flex-col items-end gap-1">
                    <div className="flex w-[240px] items-center gap-2.5 rounded-2xl bg-[rgba(59,130,246,0.14)] px-3 py-2.5 ring-1 ring-[#3B82F6]/40">
                      <span className="shrink-0">{fileIcon(m.attachment.name)}</span>
                      <span className="min-w-0 flex-1">
                        <span className="block truncate text-[13px] font-medium text-white/95" title={m.attachment.name}>{m.attachment.name}</span>
                        <span className="mt-0.5 block text-[11px] text-white/40">{formatBytes(m.attachment.size)}</span>
                      </span>
                      <button
                        type="button"
                        title={t('liveMeeting.room.chat.download')}
                        aria-label={t('liveMeeting.room.chat.download')}
                        onClick={() => void downloadFile(m.attachment!)}
                        className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-white/10 text-white/70 transition-colors hover:bg-white/20 hover:text-white"
                      >
                        ↓
                      </button>
                    </div>
                    <span className="pr-1 text-[10px] text-white/25">{formatMsgTime(m.createdAt)}</span>
                  </div>
                ) : (
                  <div key={m.id} className="flex items-start gap-2">
                    <span className="flex h-7 w-7 shrink-0 select-none items-center justify-center rounded-full bg-white/10 text-[11px] font-semibold text-white/80">
                      {m.sender.name.charAt(0)}
                    </span>
                    <div className="min-w-0 flex-1">
                      <div className="mb-1 flex items-center gap-1.5">
                        <span className="text-[11px] text-white/45">{m.sender.name}</span>
                        <span className="text-[10px] text-white/25">{formatMsgTime(m.createdAt)}</span>
                      </div>
                      <div className="flex w-[240px] items-center gap-2.5 rounded-2xl bg-white/[0.08] px-3 py-2.5">
                        <span className="shrink-0">{fileIcon(m.attachment.name)}</span>
                        <span className="min-w-0 flex-1">
                          <span className="block truncate text-[13px] font-medium text-white/95" title={m.attachment.name}>{m.attachment.name}</span>
                          <span className="mt-0.5 block text-[11px] text-white/40">{formatBytes(m.attachment.size)}</span>
                        </span>
                        <button
                          type="button"
                          title={t('liveMeeting.room.chat.download')}
                          aria-label={t('liveMeeting.room.chat.download')}
                          onClick={() => void downloadFile(m.attachment!)}
                          className="flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-white/10 text-white/70 transition-colors hover:bg-white/20 hover:text-white"
                        >
                          ↓
                        </button>
                      </div>
                    </div>
                  </div>
                )
              ) : m.sender.isSelf ? (
                <div key={m.id} className="flex justify-end">
                  <div className="max-w-[80%] break-words [overflow-wrap:anywhere] rounded-2xl rounded-br-md bg-brand-gradient px-3.5 py-2 text-[13px] leading-relaxed text-white shadow-[0_4px_14px_rgba(59,130,246,0.3)]">
                    {m.text}
                  </div>
                </div>
              ) : (
                <div key={m.id} className="flex items-start gap-2">
                  <span className="flex h-7 w-7 shrink-0 select-none items-center justify-center rounded-full bg-white/10 text-[11px] font-semibold text-white/80">
                    {m.sender.name.charAt(0)}
                  </span>
                  <div className="min-w-0 flex-1">
                    <div className="mb-1 flex items-center gap-1.5">
                      <span className="text-[11px] text-white/45">{m.sender.name}</span>
                      <span className="text-[10px] text-white/25">{formatMsgTime(m.createdAt)}</span>
                    </div>
                    <div className="inline-block max-w-[92%] break-words [overflow-wrap:anywhere] rounded-2xl rounded-tl-md bg-white/[0.08] px-3.5 py-2 text-[13px] leading-relaxed text-white/90">
                      {m.text}
                    </div>
                  </div>
                </div>
              )
            )) : (
              <p className="px-2 py-6 text-center text-xs text-white/30">{t('liveMeeting.room.chat.empty')}</p>
            )}
          </div>

          {/* Chat input */}
          <div className="shrink-0 border-t border-border bg-background p-3">
            <p className="mb-2 text-center text-[10px] text-muted-foreground">{t('liveMeeting.room.chat.lifetime')}</p>
            {chatReply && <div className="mb-2 flex items-center gap-2 text-xs text-white/60"><span className="min-w-0 flex-1 truncate">{t('im.workbench.reply')}: {chatReply.text || chatReply.attachment?.name}</span><button onClick={() => setChatReply(null)}>{t('im.workbench.cancel')}</button></div>}
            <div className="relative">
              {emojiOpen && (
                <div className="absolute bottom-full left-0 right-0 z-40 mb-2 overflow-hidden rounded-2xl border border-white/10 bg-[#151A26]/95 shadow-elevated backdrop-blur-xl">
                  <div className="custom-scrollbar max-h-[220px] overflow-y-auto px-2.5 pt-2.5">
                    <div className="grid grid-cols-8 gap-0.5 pb-1.5">
                      {EMOJI_GROUPS[emojiTab].map((e) => (
                        <button
                          key={e}
                          type="button"
                          onClick={() => { setDraft((d) => d + e); inputRef.current?.focus(); }}
                          className="flex h-9 w-9 items-center justify-center rounded-lg text-[21px] leading-none transition-colors hover:bg-white/10 active:scale-90"
                        >
                          {e}
                        </button>
                      ))}
                    </div>
                  </div>
                  <div className="flex items-center gap-1 border-t border-white/[0.08] px-2.5 py-1.5">
                    {EMOJI_TABS.map((tab, i) => (
                      <button
                        key={tab}
                        type="button"
                        aria-label={`emoji ${i + 1}`}
                        onClick={() => setEmojiTab(i)}
                        className={cn(
                          'flex h-7 w-7 items-center justify-center rounded-lg text-[16px] leading-none transition-colors',
                          i === emojiTab ? 'bg-white/15' : 'opacity-45 hover:bg-white/10 hover:opacity-90',
                        )}
                      >
                        {tab}
                      </button>
                    ))}
                    <button
                      type="button"
                      aria-label={t('common.actions.close')}
                      onClick={() => setEmojiOpen(false)}
                      className="ml-auto flex h-7 w-7 items-center justify-center rounded-lg text-white/50 hover:bg-white/10 hover:text-white"
                    >
                      <X className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              )}
              <div className="flex items-center gap-1 rounded-2xl border border-border bg-card p-1.5 transition-colors focus-within:border-primary">
                <button
                  type="button"
                  aria-label={t('liveMeeting.room.chat.file')}
                  title={t('liveMeeting.room.chat.file')}
                  disabled={fileSending || chatStatus !== 'ready'}
                  onClick={() => fileRef.current?.click()}
                  className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-white/50 transition-colors hover:bg-white/10 hover:text-white"
                >
                  <Paperclip className="h-[18px] w-[18px]" />
                </button>
                <input
                  ref={fileRef}
                  type="file"
                  className="hidden"
                  aria-hidden="true"
                  tabIndex={-1}
                  onChange={(e) => {
                    const f = e.target.files?.[0];
                    if (f) {
                      void sendFile(f)
                        .then(() => toast.success(t('liveMeeting.room.chat.fileSent', { name: f.name })))
                        .catch((error) => toast.error(error instanceof Error ? error.message : t('liveMeeting.room.errors.generic')));
                    }
                    e.target.value = '';
                  }}
                />
                {fileSending&&<span role="status" className="shrink-0 text-xs text-white/60">{fileProgress}% <button type="button" onClick={cancelFile} className="underline">{t('liveMeeting.room.chat.cancel')}</button></span>}
                <button
                  type="button"
                  aria-label={t('liveMeeting.room.chat.emoji')}
                  title={t('liveMeeting.room.chat.emoji')}
                  onClick={() => setEmojiOpen((v) => !v)}
                  className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-white/50 transition-colors hover:bg-white/10 hover:text-white"
                >
                  <Smile className="h-[18px] w-[18px]" />
                </button>
                <input
                  ref={inputRef}
                  type="text"
                  autoComplete="off"
                  maxLength={200}
                  value={draft}
                  disabled={chatStatus !== 'ready'}
                  onChange={(e) => setDraft(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') doSend(); }}
                  placeholder={t('liveMeeting.room.chat.placeholder')}
                  className="h-8 min-w-0 flex-1 bg-transparent text-[13px] text-white outline-none placeholder:text-white/30"
                />
                <button
                  type="button"
                  aria-label={t('liveMeeting.room.chat.send')}
                  title={t('liveMeeting.room.chat.send')}
                  onClick={doSend}
                  disabled={sending || chatStatus !== 'ready' || !draft.trim()}
                  className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-brand-gradient text-white shadow-[0_4px_12px_rgba(59,130,246,0.35)] transition-all hover:brightness-110 active:scale-95"
                >
                  <Send className="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>
        </>
      ) : (
        <>
          {/* Members tab */}
          <div className="custom-scrollbar min-h-0 flex-1 overflow-y-auto px-2 pt-2">
            {isHost && room.waiting.length > 0 && (
              <div className="mx-1 mb-2 rounded-xl border border-[#FBBF24]/25 bg-[#FBBF24]/[0.06] p-2">
                <div className="px-1 pb-1 text-xs font-medium text-[#FBBF24]">
                  {t('liveMeeting.room.waitingRoom.badge', { count: room.waiting.length })}
                </div>
                {room.waiting.map((w) => (
                  <div key={w.participantId} className="flex items-center gap-2.5 rounded-lg px-1 py-1.5">
                    <span className="flex h-8 w-8 shrink-0 select-none items-center justify-center rounded-full bg-white/10 text-xs font-semibold text-white/80">
                      {w.name.charAt(0)}
                    </span>
                    <span className="min-w-0 flex-1 truncate text-sm text-white/90">{w.name}</span>
                    <button
                      type="button"
                      onClick={() => { void admit(w.participantId).then((ok) => { if (ok) toast.success(t('liveMeeting.room.waitingRoom.admittedToast', { name: w.name })); }); }}
                      className="shrink-0 rounded-md bg-brand-gradient px-2.5 py-1 text-[11px] font-medium text-white transition-all hover:brightness-110"
                    >
                      {t('liveMeeting.room.waitingRoom.admit')}
                    </button>
                    <button
                      type="button"
                      onClick={() => { void deny(w.participantId).then((ok) => { if (ok) toast(t('liveMeeting.room.waitingRoom.deniedToast', { name: w.name })); }); }}
                      className="ml-1 shrink-0 rounded-md bg-white/10 px-2.5 py-1 text-[11px] font-medium text-white/70 transition-colors hover:bg-white/20"
                    >
                      {t('liveMeeting.room.waitingRoom.deny')}
                    </button>
                  </div>
                ))}
              </div>
            )}
            {memberRow(self, 'self')}
            {others.length > 0 && (
              <div className="mt-1 border-t border-white/5 pt-1">
                {others.map((p) => memberRow(p, p.id))}
              </div>
            )}
          </div>
          {meetingUi.audio && <div className="mt-auto border-t border-white/10 p-3">
            {isHost ? (
              <button
                type="button"
                disabled={muteAllPending}
                aria-pressed={hasHostMutedMembers}
                aria-busy={muteAllPending}
                onClick={async () => {
                  setMuteAllPending(true);
                  try {
                    const muted = !hasHostMutedMembers;
                    if (await setAllMuted(muted)) {
                      toast.success(t(muted ? 'liveMeeting.room.member.allMutedToast' : 'liveMeeting.room.member.allUnmutedToast'));
                    }
                  } finally { setMuteAllPending(false); }
                }}
                className="flex h-9 w-full items-center justify-center gap-2 rounded-lg bg-white/10 text-sm font-medium text-white transition-colors hover:bg-white/20 disabled:cursor-wait disabled:opacity-50"
              >
                {hasHostMutedMembers ? <Mic className="h-4 w-4" /> : <MicOff className="h-4 w-4" />}
                {t(hasHostMutedMembers ? 'liveMeeting.room.member.unmuteAll' : 'liveMeeting.room.member.muteAll')}
              </button>
            ) : (
              <div className="py-1 text-center text-xs text-white/35">{t('liveMeeting.room.member.participantNote')}</div>
            )}
          </div>}
        </>
      )}
    </div>
  );
}
