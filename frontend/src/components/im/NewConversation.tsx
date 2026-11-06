'use client';
import { useState, useRef, useEffect } from 'react';
import { useDRClient } from '@deeprespond/im-web-react';
import type { ConversationView } from '@deeprespond/im-web';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogTitle,
} from '@/components/ui/dialog';
import { useT } from '@/i18n';
import {
  ActionError,
  inputClass,
  buttonClass,
  useImAction,
} from './useImAction';

export default function NewConversation({
  open,
  onOpenChange,
  onSelect,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSelect: (view: ConversationView) => void;
}) {
  const t = useT(),
    im = useDRClient(),
    { pending, error, run } = useImAction();
  const [mode, setMode] = useState<'single' | 'group'>('single'),
    [name, setName] = useState(''),
    [members, setMembers] = useState('');
  const committed = useRef(false);
  const [created, setCreated] = useState(false);
  useEffect(() => {
    if (!open) {
      committed.current = false;
      setCreated(false);
    }
  }, [open]);
  const submit = () =>
    run(async () => {
      if (!im || committed.current) return;
      if (mode === 'single') {
        onSelect(await im.conversations.openSingle(name.trim()));
      } else {
        const usernames = [
          ...new Set(members.split(/[\s,，]+/).filter(Boolean)),
        ];
        const group = await im.groups.create({
          name: name.trim(),
          type: 'private',
          members: usernames,
        });
        committed.current = true;
        setCreated(true);
        const failures = group.results.filter((r) => 'code' in r);
        // Creation is committed even if individual invitations failed. Open the
        // created group immediately; the result dialog keeps partial failures visible.
        const view = await im.conversations.get(group.group_id);
        if (view) onSelect(view);
        else
          onSelect({
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
          });
        if (failures.length)
          throw new Error(
            failures
              .map((r) => `${r.username}: ${'code' in r ? r.code : ''}`)
              .join('; '),
          );
      }
      setName('');
      setMembers('');
      onOpenChange(false);
    });
  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!pending) onOpenChange(v);
      }}
    >
      <DialogContent className="max-h-[85vh] w-[calc(100%-2rem)] max-w-md overflow-y-auto bg-[#151A26]">
        <DialogTitle>{t('im.workbench.newConversation')}</DialogTitle>
        <DialogDescription>{t('im.workbench.userIdHint')}</DialogDescription>
        <div className="flex gap-2">
          <button
            className={buttonClass}
            aria-pressed={mode === 'single'}
            disabled={pending || created}
            onClick={() => setMode('single')}
          >
            {t('im.workbench.single')}
          </button>
          <button
            className={buttonClass}
            aria-pressed={mode === 'group'}
            disabled={pending || created}
            onClick={() => setMode('group')}
          >
            {t('im.workbench.createGroup')}
          </button>
        </div>
        <form
          className="space-y-3"
          onSubmit={(e) => {
            e.preventDefault();
            void submit();
          }}
        >
          <label className="block space-y-1 text-sm">
            <span>
              {t(
                mode === 'single'
                  ? 'im.workbench.username'
                  : 'im.workbench.groupName',
              )}
            </span>
            <input
              autoFocus
              required
              maxLength={100}
              className={inputClass}
              value={name}
              disabled={pending}
              onChange={(e) => setName(e.target.value)}
            />
          </label>
          {mode === 'group' && (
            <label className="block space-y-1 text-sm">
              <span>{t('im.workbench.memberIds')}</span>
              <textarea
                className={inputClass}
                value={members}
                disabled={pending}
                onChange={(e) => setMembers(e.target.value)}
              />
            </label>
          )}
          <ActionError error={error} />
          {created ? (
            <button
              type="button"
              className={buttonClass}
              onClick={() => onOpenChange(false)}
            >
              {t('common.actions.close')}
            </button>
          ) : (
            <button className={buttonClass} disabled={pending || !name.trim()}>
              {t(pending ? 'im.workbench.working' : 'im.workbench.create')}
            </button>
          )}
        </form>
      </DialogContent>
    </Dialog>
  );
}
