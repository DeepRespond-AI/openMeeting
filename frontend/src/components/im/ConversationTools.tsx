'use client';
import { useState } from 'react';
import { useDRClient } from '@deeprespond/im-web-react';
import type { ConversationView } from '@deeprespond/im-web';
import { useT } from '@/i18n';
import { ActionError, buttonClass, useImAction } from './useImAction';
import GroupManager from './GroupManager';

export default function ConversationTools({
  view,
  onRemoved,
}: {
  view: ConversationView;
  onRemoved: () => void;
}) {
  const im = useDRClient(),
    t = useT(),
    { pending, error, run } = useImAction();
  const [groupOpen, setGroupOpen] = useState(false);
  const [removeConfirm, setRemoveConfirm] = useState(false);
  const id = view.conversation_id;
  const mute = () =>
    run(async () => {
      if (!im) return;
      const target =
        view.conversation_type === 'group'
          ? { conversation_type: 'group' as const, target: view.group_id! }
          : { conversation_type: 'single' as const, target: view.peer! };
      if (view.muted) await im.push.unmute(target);
      else if (target.conversation_type === 'group')
        await im.push.mute(target, { mode: 'none' });
      else await im.push.mute(target, { mode: 'none' });
    });
  return (
    <div className="space-y-2 border-b border-white/10 px-4 py-2">
      <div className="flex flex-wrap gap-2">
        <button
          className={buttonClass}
          disabled={pending || !id}
          onClick={() =>
            void run(async () => {
              if (im && id)
                await im.conversations.setPinned(id, !view.state?.pinned_at);
            })
          }
        >
          {t(view.state?.pinned_at ? 'im.workbench.unpin' : 'im.workbench.pin')}
        </button>
        <button
          className={buttonClass}
          disabled={pending}
          onClick={() => void mute()}
        >
          {t(view.muted ? 'im.workbench.unmute' : 'im.workbench.mute')}
        </button>
        {view.group_id && (
          <button className={buttonClass} onClick={() => setGroupOpen(true)}>
            {t('im.workbench.groupSettings')}
          </button>
        )}
        <button
          className={buttonClass}
          disabled={pending || !id}
          onClick={() => setRemoveConfirm(true)}
        >
          {t('im.workbench.removeConversation')}
        </button>
      </div>
      {removeConfirm && (
        <div className="flex flex-wrap items-center gap-2 text-xs" role="alert">
          <span>{t('im.workbench.removeConversationHint')}</span>
          <button
            className={buttonClass}
            disabled={pending}
            onClick={() =>
              void run(async () => {
                if (im && id) {
                  await im.conversations.remove(id);
                  setRemoveConfirm(false);
                  onRemoved();
                }
              })
            }
          >
            {t('im.workbench.confirm')}
          </button>
          <button
            className={buttonClass}
            onClick={() => setRemoveConfirm(false)}
          >
            {t('im.workbench.cancel')}
          </button>
        </div>
      )}
      <ActionError error={error} />
      {view.group_id && (
        <GroupManager
          groupId={view.group_id}
          open={groupOpen}
          onOpenChange={setGroupOpen}
          onLeft={onRemoved}
        />
      )}
    </div>
  );
}
