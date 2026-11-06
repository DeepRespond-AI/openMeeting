'use client';
import { useEffect, useState } from 'react';
import { useDRClient } from '@deeprespond/im-web-react';
import { useT } from '@/i18n';
import { ActionError, buttonClass, useImAction } from './useImAction';

type Invitation = { group_id: string; name: string };
function invitations(items: unknown[]): Invitation[] {
  return items.flatMap((item) => {
    if (!item || typeof item !== 'object') return [];
    const row = item as Record<string, unknown>;
    if (typeof row.group_id !== 'string') return [];
    const group =
      row.group && typeof row.group === 'object'
        ? (row.group as Record<string, unknown>)
        : null;
    return [
      {
        group_id: row.group_id,
        name: typeof group?.name === 'string' ? group.name : row.group_id,
      },
    ];
  });
}
export default function GroupInvitations() {
  const im = useDRClient(),
    t = useT(),
    { pending, error, run, setError } = useImAction();
  const [items, setItems] = useState<Invitation[]>([]),
    [cursor, setCursor] = useState<string | null>(null),
    [revision, setRevision] = useState(0),
    [loading, setLoading] = useState(false);
  useEffect(
    () =>
      im?.on('groupRequests.changed', (e) => {
        if (e.list === 'invitations') setRevision((n) => n + 1);
      }),
    [im],
  );
  useEffect(() => {
    if (!im) return;
    let active = true;
    setLoading(true);
    void im.groups.invitations
      .received({ status: 'pending', limit: 50 })
      .then((page) => {
        if (active) {
          setItems(invitations(page.items));
          setCursor(page.next_cursor);
        }
      })
      .catch((e) => {
        if (active) setError(e instanceof Error ? e.message : String(e));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [im, revision, setError]);
  return (
    <div className="space-y-2 rounded-lg border border-white/10 p-2">
      <div className="flex items-center justify-between gap-2">
        <h3 className="text-xs">{t('im.workbench.groupInvitations')}</h3>
        <button
          className={buttonClass}
          disabled={loading}
          onClick={() => setRevision((n) => n + 1)}
        >
          {t('im.chats.retry')}
        </button>
      </div>
      <ActionError error={error} />
      {loading && (
        <p role="status" className="text-xs">
          {t('im.workbench.loading')}
        </p>
      )}
      {!loading && !items.length && (
        <p className="text-xs text-muted-foreground">
          {t('im.workbench.empty')}
        </p>
      )}
      {items.map((item) => (
        <div key={item.group_id} className="space-y-1">
          <p className="break-all text-xs">{item.name}</p>
          <div className="flex gap-1">
            {(['accept', 'decline'] as const).map((action) => (
              <button
                className={buttonClass}
                key={action}
                disabled={pending}
                onClick={() =>
                  void run(async () => {
                    await im?.groups.invitations[action](item.group_id);
                    setItems((prev) =>
                      prev.filter((g) => g.group_id !== item.group_id),
                    );
                  })
                }
              >
                {t(`im.workbench.${action}`)}
              </button>
            ))}
          </div>
        </div>
      ))}
      {cursor && (
        <button
          className={buttonClass}
          disabled={pending}
          onClick={() =>
            void run(async () => {
              if (!im) return;
              const page = await im.groups.invitations.received({
                status: 'pending',
                cursor,
                limit: 50,
              });
              setItems((prev) => [
                ...prev,
                ...invitations(page.items).filter(
                  (item) => !prev.some((p) => p.group_id === item.group_id),
                ),
              ]);
              setCursor(page.next_cursor);
            })
          }
        >
          {t('im.workbench.loadMore')}
        </button>
      )}
    </div>
  );
}
