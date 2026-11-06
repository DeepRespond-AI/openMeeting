'use client';

/**
 * Chats workbench: conversations, contacts, groups and rich messages.
 * Lifecycle (connecting / unavailable / error) comes from IMContext; data hooks from
 * @deeprespond/im-web-react (LiveList → useSyncExternalStore under the hood).
 */
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Loader2,
  MessageCircle,
  RefreshCw,
  VolumeX,
  ArrowLeft,
} from 'lucide-react';
import { useI18n, useT } from '@/i18n';
import { cn } from '@/lib/utils';
import EmptyIllustration from '@/components/live-meeting/EmptyIllustration';
import { useIm } from '@/contexts/IMContext';
import {
  useConnectionState,
  useConversationTitle,
  useDRClient,
  useDisplayName,
  useLiveList,
  useMe,
  useMessageList,
} from '@deeprespond/im-web-react';
import type {
  ConversationView,
  DRClient,
  MessageView,
} from '@deeprespond/im-web';
import NewConversation from '@/components/im/NewConversation';
import ContactsPanel from '@/components/im/ContactsPanel';
import ConversationTools from '@/components/im/ConversationTools';
import MessageComposer from '@/components/im/MessageComposer';
import ChatMessage, { showMessageTime } from '@/components/im/ChatMessage';
import {
  ActionError,
  buttonClass,
  useImAction,
} from '@/components/im/useImAction';

/* ---------- lifecycle screens ---------- */

function LifecycleCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="mx-auto my-6 flex w-[calc(100%-2rem)] max-w-sm flex-col items-center gap-3 rounded-2xl border border-white/[0.08] bg-white/[0.04] px-5 py-8 text-center backdrop-blur-md sm:my-16 sm:px-8 sm:py-10">
      {children}
    </div>
  );
}

/* ---------- time helpers ---------- */

function formatMsgTime(iso: string | null, locale: string): string {
  if (!iso) return '';
  const d = new Date(iso);
  const now = new Date();
  const sameDay = d.toDateString() === now.toDateString();
  return sameDay
    ? new Intl.DateTimeFormat(locale, {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false,
      }).format(d)
    : new Intl.DateTimeFormat(locale, {
        month: '2-digit',
        day: '2-digit',
      }).format(d);
}

function messageText(m: MessageView): string {
  if (m.recalled) return '';
  if (m.type === 'text' && typeof m.body?.text === 'string') return m.body.text;
  return `[${m.type}]`;
}

/* ---------- conversation list ---------- */

function ConversationRow({
  view,
  active,
  locale,
  onClick,
}: {
  view: ConversationView;
  active: boolean;
  locale: string;
  onClick: () => void;
}) {
  const t = useT();
  const title = useConversationTitle(view) ?? view.peer ?? view.group_id ?? '—';
  const last = view.last_message;
  const preview = last
    ? last.recalled
      ? t('im.chats.recalled')
      : `${last.sender_type === 'user' ? '' : ''}${messageText(last) || `[${last.type}]`}`
    : '';
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        'flex w-full items-center gap-3 rounded-xl px-3 py-2.5 text-left transition-colors',
        active ? 'bg-white/[0.09]' : 'hover:bg-white/[0.05]',
      )}
    >
      <span className="relative flex h-10 w-10 shrink-0 select-none items-center justify-center rounded-full bg-brand-gradient text-sm font-semibold text-white">
        {title.charAt(0).toUpperCase()}
        {view.muted && (
          <span className="absolute -bottom-0.5 -right-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-[#151A26]">
            <VolumeX className="h-2.5 w-2.5 text-white/60" />
          </span>
        )}
      </span>
      <span className="min-w-0 flex-1">
        <span className="flex items-center justify-between gap-2">
          <span className="min-w-0 truncate text-sm font-medium text-foreground">
            {title}
          </span>
          <span className="shrink-0 text-[10px] tabular-nums text-muted-foreground">
            {formatMsgTime(last?.created_at ?? null, locale)}
          </span>
        </span>
        <span className="mt-0.5 flex items-center justify-between gap-2">
          <span
            className={cn(
              'min-w-0 truncate text-xs',
              view.unread_count > 0
                ? 'text-foreground/80'
                : 'text-muted-foreground',
            )}
          >
            {preview || '\u00A0'}
          </span>
          {view.unread_count > 0 && (
            <span className="flex h-4 min-w-4 shrink-0 items-center justify-center rounded-full bg-[#DC3B3B] px-1 text-[9px] font-semibold text-white">
              {view.unread_count > 99 ? '99+' : view.unread_count}
            </span>
          )}
        </span>
      </span>
    </button>
  );
}

/* ---------- chat pane ---------- */

function ChatPane({
  view,
  onBack,
}: {
  view: ConversationView;
  onBack: () => void;
}) {
  const t = useT();
  const im = useDRClient();
  const me = useMe();
  const conn = useConnectionState();
  const { snapshot, list } = useMessageList(view.conversation_key);
  const title = useConversationTitle(view) ?? view.peer ?? view.group_id ?? '—';
  const displayName = useDisplayName(view.peer);
  const { error, run } = useImAction();
  const scrollRef = useRef<HTMLDivElement>(null);

  const key = view.conversation_key;
  const itemCount = snapshot.items.length;
  const profileNames = [...new Set([view.peer, ...snapshot.items.map(m => m.sender)].filter((name): name is string => !!name))].sort().join('\n');
  useEffect(() => {
    if (profileNames) void im?.users.fetch(profileNames.split('\n'), {force:true}).catch(() => {});
  }, [im, key, profileNames]);

  // Opened conversation counts as read.
  useEffect(() => {
    if (view.conversation_id) im?.conversations.markRead(view.conversation_id);
  }, [im, view.conversation_id, itemCount]);

  // Follow appended messages without losing the position when loading history.
  useEffect(() => {
    const el = scrollRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [
    snapshot.items[snapshot.items.length - 1]?.client_msg_id,
    snapshot.items[snapshot.items.length - 1]?.seq,
    key,
  ]);

  const online = conn.kind === 'ready' || conn.kind === 'syncing';

  return (
    <section className="flex min-h-0 min-w-0 flex-1 flex-col">
      {/* Header */}
      <div className="flex h-14 shrink-0 items-center justify-between gap-3 border-b border-white/[0.06] px-5">
        <div className="flex min-w-0 items-center gap-2.5">
          <button
            className="md:hidden"
            aria-label={t('im.workbench.back')}
            onClick={onBack}
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <h2 className="truncate text-sm font-semibold text-foreground">
            {title}
          </h2>
          {view.conversation_type === 'single' &&
            displayName &&
            displayName !== title && (
              <span className="shrink-0 text-xs text-muted-foreground">
                {displayName}
              </span>
            )}
        </div>
        <span className="flex shrink-0 items-center gap-1.5 text-[11px] text-muted-foreground">
          <span
            className={cn(
              'h-2 w-2 rounded-full',
              online ? 'bg-emerald-400' : 'animate-pulse bg-amber-400',
            )}
            aria-hidden="true"
          />
          {online ? t('im.chats.title') : t('im.chats.connecting')}
        </span>
      </div>

      <ConversationTools view={view} onRemoved={onBack} />
      <ActionError error={error || snapshot.error?.message || ''} />
      {/* Messages */}
      <div
        ref={scrollRef}
        className="custom-scrollbar flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto px-5 py-4"
      >
        {snapshot.hasOlder && (
          <button
            type="button"
            onClick={() =>
              void run(async () => {
                const el = scrollRef.current,
                  height = el?.scrollHeight ?? 0,
                  top = el?.scrollTop ?? 0;
                await list?.loadOlder();
                requestAnimationFrame(() => {
                  if (el) el.scrollTop = top + el.scrollHeight - height;
                });
              })
            }
            className="mx-auto rounded-full border border-white/10 bg-white/[0.05] px-3 py-1 text-[11px] text-muted-foreground transition-colors hover:bg-white/[0.1] hover:text-foreground"
          >
            {t('im.chats.loadOlder')}
          </button>
        )}
        {!snapshot.hasOlder && itemCount > 0 && (
          <p className="py-2 text-center text-[11px] text-muted-foreground/60">
            {t('im.chats.historyStart')}
          </p>
        )}
        {snapshot.items.filter(m => !m.erased).map((m, index, items) => {
          if (m.sender_type === 'system') {
            return (
              <p
                key={`${m.client_msg_id ?? m.message_id ?? m.seq}`}
                className="py-1 text-center text-[11px] text-muted-foreground/70"
              >
                {messageText(m) || t('im.chats.recalled')}
              </p>
            );
          }
          const own = m.sender !== null && m.sender === me?.username;
          return (
            <ChatMessage key={`${m.client_msg_id ?? m.message_id ?? m.seq}`} message={m} own={own}
              showTime={showMessageTime(m, items[index - 1])} testId="im-direct-message" />
          );
        })}
      </div>

      <MessageComposer
        view={view}
        online={online}
      />
    </section>
  );
}

/* ---------- ready shell ---------- */

function ChatsReady() {
  const t = useT();
  const { locale } = useI18n();
  const im = useDRClient();
  const { snapshot } = useLiveList<ConversationView>(
    useCallback((client: DRClient) => client.conversations.list(), []),
    [],
  );
  const [selectedKey, setSelectedKey] = useState<string | null>(null);
  const [opened, setOpened] = useState<ConversationView | null>(null);
  const [newOpen, setNewOpen] = useState(false),
    [contacts, setContacts] = useState(false);
  const { error, run } = useImAction();
  const select = (view: ConversationView) => {
    setOpened(view);
    setSelectedKey(view.conversation_key);
  };

  const conversations = snapshot.items.filter(c => c.state?.membership !== 'dismissed');
  const selected = useMemo(
    () =>
      conversations.find((c) => c.conversation_key === selectedKey) ??
      (opened?.conversation_key === selectedKey && !snapshot.items.some(c => c.conversation_key === selectedKey && c.state?.membership === 'dismissed')
        ? (conversations.find(
            (c) =>
              c.conversation_type === opened.conversation_type &&
              (c.conversation_type === 'single'
                ? c.peer === opened.peer
                : c.group_id === opened.group_id),
          ) ?? opened)
        : null),
    [conversations, selectedKey, opened, snapshot.items],
  );

  useEffect(() => {
    if (selected && selected.conversation_key !== selectedKey) {
      setSelectedKey(selected.conversation_key);
      setOpened(selected);
    }
  }, [selected, selectedKey]);

  return (
    <div className="mx-auto flex h-full w-full max-w-6xl flex-col px-3 pb-4 pt-4 sm:px-8 sm:pb-6 sm:pt-8">
      <div className="rise rise-1 shrink-0">
        <h1 className="text-2xl font-semibold tracking-tight text-foreground">
          {t('im.chats.title')}
        </h1>
        <p className="mt-0.5 text-sm text-muted-foreground">
          {t('im.chats.subtitle')}
        </p>
        <div className="mt-2 flex flex-wrap gap-2">
          <button className={buttonClass} onClick={() => setNewOpen(true)}>
            {t('im.workbench.newConversation')}
          </button>
          <button
            className={buttonClass}
            aria-pressed={contacts}
            onClick={() => {
              setContacts((v) => !v);
              setSelectedKey(null);
            }}
          >
            {t('im.workbench.contacts')}
          </button>
          <button
            className={buttonClass}
            onClick={() =>
              void run(async () => {
                await im?.conversations.markAllRead();
              })
            }
          >
            {t('im.workbench.markAllRead')}
          </button>
        </div>
        <ActionError error={error || snapshot.error?.message || ''} />
        <NewConversation
          open={newOpen}
          onOpenChange={setNewOpen}
          onSelect={select}
        />
      </div>

      <div className="rise rise-2 mt-5 flex min-h-0 flex-1 gap-4">
        {/* Conversation list */}
        <aside
          className={cn(
            'min-h-0 w-full shrink-0 flex-col rounded-2xl border border-white/[0.06] bg-white/[0.03] p-2 backdrop-blur-md md:flex md:w-[300px]',
            selected ? 'hidden' : 'flex',
          )}
        >
          {contacts ? (
            <ContactsPanel onSelect={select} />
          ) : conversations.length ? (
            <div className="custom-scrollbar flex min-h-0 flex-1 flex-col gap-1 overflow-y-auto">
              {conversations.map((c) => (
                <ConversationRow
                  key={c.conversation_key}
                  view={c}
                  active={c.conversation_key === selectedKey}
                  locale={locale}
                  onClick={() => select(c)}
                />
              ))}
            </div>
          ) : snapshot.loading ? (
            <div className="flex flex-1 items-center justify-center text-muted-foreground">
              <Loader2 className="h-5 w-5 animate-spin" />
            </div>
          ) : (
            <div className="flex flex-1 flex-col items-center justify-center gap-3 px-4 text-center">
              <EmptyIllustration />
              <p className="text-sm font-medium text-foreground/70">
                {t('im.chats.emptyTitle')}
              </p>
              <p className="text-xs leading-relaxed text-muted-foreground">
                {t('im.chats.emptyDesc')}
              </p>
            </div>
          )}
        </aside>

        {/* Chat pane / placeholder */}
        {selected ? (
          <ChatPane
            key={selected.conversation_type === 'single' ? `single:${selected.peer}` : `group:${selected.group_id}`}
            view={selected}
            onBack={() => {
              setSelectedKey(null);
              setOpened(null);
            }}
          />
        ) : (
          <section className="hidden min-w-0 flex-1 flex-col items-center justify-center gap-3 md:flex rounded-2xl border border-white/[0.06] bg-white/[0.03] text-center backdrop-blur-md">
            <MessageCircle className="h-10 w-10 text-muted-foreground/40" />
            <p className="text-sm text-muted-foreground">
              {t('im.chats.selectChat')}
            </p>
          </section>
        )}
      </div>
    </div>
  );
}

/** Chats entry: lifecycle screens first, then the ready two-pane layout. */
export default function ChatsPage() {
  const t = useT();
  const { status, errorText, relogin } = useIm();

  return (
    <div className="h-full min-h-0 min-w-0 overflow-y-auto">
      {status === 'ready' ? (
        <ChatsReady />
      ) : status === 'connecting' ? (
        <LifecycleCard>
          <Loader2 className="h-6 w-6 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">
            {t('im.chats.connecting')}
          </p>
        </LifecycleCard>
      ) : status === 'unavailable' ? (
        <LifecycleCard>
          <MessageCircle className="h-8 w-8 text-muted-foreground/50" />
          <p className="text-sm text-muted-foreground">
            {t('im.chats.unavailable')}
          </p>
        </LifecycleCard>
      ) : (
        <LifecycleCard>
          <RefreshCw className="h-8 w-8 text-destructive" />
          <p className="text-sm font-medium text-foreground">
            {t('im.chats.errorTitle')}
          </p>
          {errorText && (
            <p className="max-w-full break-all text-xs text-muted-foreground">
              {errorText}
            </p>
          )}
          <button
            type="button"
            onClick={relogin}
            className="mt-1 inline-flex h-9 items-center gap-2 rounded-xl bg-brand-gradient px-5 text-sm font-semibold text-white shadow-[0_6px_16px_rgba(59,130,246,0.35)] transition-all hover:brightness-110"
          >
            <RefreshCw className="h-4 w-4" />
            {t('im.chats.retry')}
          </button>
        </LifecycleCard>
      )}
    </div>
  );
}
