'use client';
import { useCallback, useEffect, useState } from 'react';
import { useDRClient, useLiveList } from '@deeprespond/im-web-react';
import type {
  ConversationView,
  DRClient,
  Friend,
  FriendRequest,
  GroupView,
} from '@deeprespond/im-web';
import { useT } from '@/i18n';
import {
  ActionError,
  inputClass,
  buttonClass,
  useImAction,
} from './useImAction';
import GroupInvitations from './GroupInvitations';

function ContactRow({
  friend,
  onSelect,
}: {
  friend: Friend;
  onSelect: (view: ConversationView) => void;
}) {
  const im = useDRClient(),
    t = useT(),
    { pending, error, run } = useImAction();
  const [editing, setEditing] = useState(false),
    [remark, setRemark] = useState(friend.remark),
    [confirm, setConfirm] = useState(false);
  return (
    <li className="space-y-2 rounded-xl border border-white/10 p-3">
      <p className="break-words text-sm font-medium">
        {friend.remark || friend.nickname || friend.username}
      </p>
      <p className="break-all text-xs text-muted-foreground">
        {friend.username}
      </p>
      <div className="flex flex-wrap gap-1">
        <button
          className={buttonClass}
          disabled={pending}
          onClick={() =>
            void run(async () => {
              if (im)
                onSelect(await im.conversations.openSingle(friend.username));
            })
          }
        >
          {t('im.workbench.message')}
        </button>
        <button
          className={buttonClass}
          disabled={pending}
          onClick={() => setEditing((v) => !v)}
        >
          {t('im.workbench.remark')}
        </button>
        <button
          className={buttonClass}
          disabled={pending}
          onClick={() => setConfirm((v) => !v)}
        >
          {t('im.workbench.removeContact')}
        </button>
      </div>
      {editing && (
        <form
          className="flex gap-1"
          onSubmit={(e) => {
            e.preventDefault();
            void run(async () => {
              await im?.friends.update(friend.username, { remark });
              setEditing(false);
            });
          }}
        >
          <input
            aria-label={t('im.workbench.remark')}
            className={inputClass}
            maxLength={100}
            value={remark}
            onChange={(e) => setRemark(e.target.value)}
          />
          <button disabled={pending} className={buttonClass}>
            {t('im.workbench.save')}
          </button>
        </form>
      )}
      {confirm && (
        <div className="space-y-2">
          <p className="text-xs">{t('im.workbench.removeContactHint')}</p>
          <button
            className={buttonClass}
            disabled={pending}
            onClick={() =>
              void run(async () => {
                await im?.friends.remove(friend.username);
              })
            }
          >
            {t('im.workbench.confirm')}
          </button>
        </div>
      )}
      <ActionError error={error} />
    </li>
  );
}

export default function ContactsPanel({
  onSelect,
}: {
  onSelect: (view: ConversationView) => void;
}) {
  const im = useDRClient(),
    t = useT(),
    { pending, error, run, setError } = useImAction();
  const { snapshot } = useLiveList<Friend>(
    useCallback((client: DRClient) => client.friends.list(), []),
    [],
  );
  const { snapshot: groups } = useLiveList<GroupView>(
    useCallback((client: DRClient) => client.groups.list(), []),
    [],
  );
  const [query, setQuery] = useState(''),
    [username, setUsername] = useState(''),
    [message, setMessage] = useState(''),
    [notice, setNotice] = useState('');
  const [requests, setRequests] = useState<FriendRequest[]>([]),
    [cursor, setCursor] = useState<string | null>(null),
    [requestsLoading, setRequestsLoading] = useState(false);
  const [tab, setTab] = useState<'contacts' | 'groups' | 'requests'>(
    'contacts',
  );
  const [requestRevision, setRequestRevision] = useState(0);
  useEffect(
    () =>
      im?.on('friendRequests.changed', () =>
        setRequestRevision((value) => value + 1),
      ),
    [im],
  );
  useEffect(() => {
    if (!im || tab !== 'requests') return;
    let disposed = false;
    setRequestsLoading(true);
    void im.friends.requests
      .received({ status: 'pending', limit: 50 })
      .then((page) => {
        if (!disposed) {
          setRequests(page.items);
          setCursor(page.next_cursor);
        }
      })
      .catch((e) => {
        if (!disposed) setError(e instanceof Error ? e.message : String(e));
      })
      .finally(() => {
        if (!disposed) setRequestsLoading(false);
      });
    return () => {
      disposed = true;
    };
  }, [im, tab, setError, requestRevision]);
  const openGroup = (group: GroupView) =>
    run(async () => {
      if (!im) return;
      const view = await im.conversations.get(group.group_id);
      onSelect(
        view ?? {
          conversation_key: group.group_id,
          conversation_id: group.group_id,
          conversation_type: 'group',
          peer: null,
          group_id: group.group_id,
          state: null,
          last_message: null,
          unread_count: 0,
          draft: null,
          muted: null,
          typing: [],
        },
      );
    });
  const filtered = snapshot.items.filter((f) =>
    `${f.remark} ${f.nickname} ${f.username}`
      .toLowerCase()
      .includes(query.toLowerCase()),
  );
  return (
    <div className="custom-scrollbar min-h-0 space-y-3 overflow-y-auto p-2">
      <div className="flex flex-wrap gap-1">
        {(['contacts', 'groups', 'requests'] as const).map((key) => (
          <button
            key={key}
            className={buttonClass}
            aria-pressed={tab === key}
            onClick={() => setTab(key)}
          >
            {t(`im.workbench.${key}`)}
          </button>
        ))}
      </div>
      <ActionError
        error={error || snapshot.error?.message || groups.error?.message || ''}
      />
      {notice && (
        <p role="status" className="text-xs text-green-400">
          {notice}
        </p>
      )}
      {tab === 'contacts' && (
        <>
          <form
            className="space-y-2 rounded-xl border border-white/10 p-2"
            onSubmit={(e) => {
              e.preventDefault();
              void run(async () => {
                if (!im) return;
                const result = await im.friends.requests.send({
                  username: username.trim(),
                  message: message.trim(),
                });
                setNotice(
                  t(
                    result.status === 'accepted'
                      ? 'im.workbench.contactAdded'
                      : 'im.workbench.requestSent',
                  ),
                );
                setUsername('');
                setMessage('');
              });
            }}
          >
            <label className="block text-xs">
              {t('im.workbench.username')}
              <input
                required
                maxLength={100}
                className={inputClass}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
              />
            </label>
            <input
              aria-label={t('im.workbench.requestMessage')}
              placeholder={t('im.workbench.requestMessage')}
              maxLength={200}
              className={inputClass}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
            />
            <button
              className={buttonClass}
              disabled={pending || !username.trim()}
            >
              {t('im.workbench.addContact')}
            </button>
          </form>
          <input
            aria-label={t('im.workbench.search')}
            placeholder={t('im.workbench.search')}
            className={inputClass}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          {snapshot.loading && (
            <p role="status" className="text-xs">
              {t('im.workbench.loading')}
            </p>
          )}
          <ul className="space-y-2">
            {filtered.map((friend) => (
              <ContactRow
                key={friend.username}
                friend={friend}
                onSelect={onSelect}
              />
            ))}
          </ul>
          {!snapshot.loading && !filtered.length && (
            <p className="text-sm text-muted-foreground">
              {t('im.workbench.empty')}
            </p>
          )}
        </>
      )}
      {tab === 'groups' && (
        <>
          <GroupInvitations />
          {groups.loading && <p role="status">{t('im.workbench.loading')}</p>}
          {groups.items.map((g) => (
            <button
              className={`${buttonClass} w-full truncate text-left`}
              key={g.group_id}
              disabled={pending}
              onClick={() => void openGroup(g)}
            >
              {g.group.name} ({g.group.member_count})
            </button>
          ))}
          {groups.hasMore && (
            <button
              className={buttonClass}
              onClick={() =>
                void run(async () => {
                  await im?.groups.list().loadMore();
                })
              }
            >
              {t('im.workbench.loadMore')}
            </button>
          )}
          {!groups.loading && !groups.items.length && (
            <p className="text-sm text-muted-foreground">
              {t('im.workbench.empty')}
            </p>
          )}
        </>
      )}
      {tab === 'requests' && (
        <>
          {requestsLoading && <p role="status">{t('im.workbench.loading')}</p>}
          {requests.map((request) => (
            <article
              key={request.username}
              className="space-y-2 rounded-xl border border-white/10 p-3"
            >
              <p className="break-all text-sm">
                {request.nickname || request.username}
              </p>
              <p className="break-all text-xs text-muted-foreground">
                {request.username}
              </p>
              <p className="whitespace-pre-wrap break-words text-xs">
                {request.message}
              </p>
              <div className="flex gap-2">
                {(['accept', 'decline'] as const).map((action) => (
                  <button
                    key={action}
                    className={buttonClass}
                    disabled={pending}
                    onClick={() =>
                      void run(async () => {
                        await im?.friends.requests[action](request.username);
                        setRequests((items) =>
                          items.filter((r) => r.username !== request.username),
                        );
                      })
                    }
                  >
                    {t(`im.workbench.${action}`)}
                  </button>
                ))}
              </div>
            </article>
          ))}
          {!requestsLoading && !requests.length && (
            <p className="text-sm text-muted-foreground">
              {t('im.workbench.empty')}
            </p>
          )}
          {cursor && (
            <button
              disabled={pending}
              className={buttonClass}
              onClick={() =>
                void run(async () => {
                  if (!im) return;
                  const page = await im.friends.requests.received({
                    status: 'pending',
                    cursor,
                    limit: 50,
                  });
                  setRequests((prev) => [
                    ...prev,
                    ...page.items.filter(
                      (p) => !prev.some((r) => r.username === p.username),
                    ),
                  ]);
                  setCursor(page.next_cursor);
                })
              }
            >
              {t('im.workbench.loadMore')}
            </button>
          )}
        </>
      )}
    </div>
  );
}
