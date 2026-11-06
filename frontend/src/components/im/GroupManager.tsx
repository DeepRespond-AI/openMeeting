'use client';
import { useCallback, useEffect, useState } from 'react';
import { useDRClient, useLiveList, useMe } from '@deeprespond/im-web-react';
import type {
  DRClient,
  GroupInfo,
  GroupMember,
  GroupMemberResult,
} from '@deeprespond/im-web';
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

function GroupEditor({
  groupId,
  onLeft,
}: {
  groupId: string;
  onLeft: () => void;
}) {
  const im = useDRClient(),
    me = useMe(),
    t = useT(),
    { pending, error, run, setError } = useImAction();
  const [memberRevision, setMemberRevision] = useState(0);
  const { snapshot, list } = useLiveList<GroupMember>(
    useCallback(
      (client: DRClient) => client.groups.members(groupId),
      [groupId, memberRevision],
    ),
    [groupId, memberRevision],
  );
  const [group, setGroup] = useState<GroupInfo | null>(null),
    [name, setName] = useState(''),
    [announcement, setAnnouncement] = useState(''),
    [description, setDescription] = useState(''),
    [invite, setInvite] = useState('');
  const [results, setResults] = useState<GroupMemberResult[]>([]);
  const [confirm, setConfirm] = useState<{
    label: string;
    task: () => Promise<unknown>;
  } | null>(null);
  const reloadMembers = async () => {
    setMemberRevision((value) => value + 1);
  };
  useEffect(() => {
    if (!im) return;
    let disposed = false;
    void im.groups
      .get(groupId, { refresh: true })
      .then((view) => {
        if (!disposed && view) {
          setGroup(view.group);
          setName(view.group.name);
          setDescription(view.group.description ?? '');
          setAnnouncement(view.group.announcement ?? '');
        }
      })
      .catch((e) => {
        if (!disposed) setError(e instanceof Error ? e.message : String(e));
      });
    return () => {
      disposed = true;
    };
  }, [im, groupId, setError]);
  const refresh = async () => {
    const updated = await im?.groups.get(groupId, { refresh: true });
    if (updated) setGroup(updated.group);
  };
  const owner = group?.owner === me?.username || group?.self?.role === 'owner';
  const admin = owner || group?.self?.role === 'admin';
  return (
    <div className="space-y-4">
      <ActionError error={error || snapshot.error?.message || ''} />
      {!group ? (
        <p role="status">{t('im.workbench.loading')}</p>
      ) : (
        <>
          <p className="break-all text-xs text-muted-foreground">
            {group.group_id} · {group.member_count} {t('im.workbench.members')}
          </p>
          <form
            className="space-y-2"
            onSubmit={(e) => {
              e.preventDefault();
              void run(async () => {
                await im?.groups.update(groupId, {
                  name: name.trim(),
                  description,
                  announcement,
                  version: group.info_version,
                });
                await refresh();
              });
            }}
          >
            <fieldset disabled={!admin || pending} className="space-y-2">
              <label className="block space-y-1 text-xs">
                {t('im.workbench.groupName')}
                <input
                  required
                  className={inputClass}
                  maxLength={100}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                />
              </label>
              <label className="block space-y-1 text-xs">
                {t('im.workbench.description')}
                <textarea
                  className={inputClass}
                  maxLength={500}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                />
              </label>
              <label className="block space-y-1 text-xs">
                {t('im.workbench.announcement')}
                <textarea
                  className={inputClass}
                  maxLength={2000}
                  value={announcement}
                  onChange={(e) => setAnnouncement(e.target.value)}
                />
              </label>
              {admin && (
                <button className={buttonClass} disabled={!name.trim()}>
                  {t('im.workbench.save')}
                </button>
              )}
            </fieldset>
          </form>
          {admin && (
            <button
              className={buttonClass}
              disabled={pending}
              onClick={() =>
                void run(async () => {
                  await im?.groups.setMuteAll(groupId, !group.mute_all);
                  await refresh();
                })
              }
            >
              {t(
                group.mute_all
                  ? 'im.workbench.unmuteAll'
                  : 'im.workbench.muteAll',
              )}
            </button>
          )}
          {(admin || group.member_invite !== 'disabled') && (
            <form
              className="flex gap-2"
              onSubmit={(e) => {
                e.preventDefault();
                void run(async () => {
                  if (!im) return;
                  setResults(
                    await im.groups.invite(groupId, [
                      ...new Set(invite.split(/[\s,，]+/).filter(Boolean)),
                    ]),
                  );
                  setInvite('');
                  await refresh();
                });
              }}
            >
              <input
                aria-label={t('im.workbench.memberIds')}
                className={inputClass}
                placeholder={t('im.workbench.memberIds')}
                value={invite}
                onChange={(e) => setInvite(e.target.value)}
              />
              <button
                className={buttonClass}
                disabled={pending || !invite.trim()}
              >
                {t('im.workbench.invite')}
              </button>
            </form>
          )}
          {results.length > 0 && (
            <ul role="status" className="max-h-36 overflow-y-auto text-xs">
              {results.map((r) => (
                <li key={r.username} className="break-all">
                  {r.username}: {'code' in r ? (r.message ?? r.code) : r.status}
                </li>
              ))}
            </ul>
          )}
          <h3 className="text-sm font-medium">{t('im.workbench.members')}</h3>
          {snapshot.loading && <p role="status">{t('im.workbench.loading')}</p>}
          <ul className="space-y-2">
            {snapshot.items.map((member) => (
              <li
                key={member.username}
                className="space-y-2 rounded-lg border border-white/10 p-2"
              >
                <p className="break-words text-sm">
                  {member.group_nickname || member.nickname || member.username}{' '}
                  · {t(`im.workbench.role_${member.role}`)}
                  {member.muted ? ` · ${t('im.workbench.muted')}` : ''}
                </p>
                <p className="break-all text-xs text-muted-foreground">
                  {member.username}
                </p>
                {member.username !== me?.username &&
                  member.role !== 'owner' &&
                  (owner || (admin && member.role === 'member')) && (
                    <div className="flex flex-wrap gap-1">
                      <button
                        className={buttonClass}
                        disabled={pending}
                        onClick={() =>
                          void run(async () => {
                            if (member.muted)
                              await im?.groups.unmute(groupId, member.username);
                            else
                              await im?.groups.mute(groupId, member.username, {
                                duration_seconds: 3600,
                              });
                            await reloadMembers();
                          })
                        }
                      >
                        {t(
                          member.muted
                            ? 'im.workbench.unmute'
                            : 'im.workbench.muteHour',
                        )}
                      </button>
                      <button
                        className={buttonClass}
                        disabled={pending}
                        onClick={() =>
                          setConfirm({
                            label: t('im.workbench.removeMember'),
                            task: async () => {
                              if (im)
                                setResults(
                                  await im.groups.removeMembers(groupId, [
                                    member.username,
                                  ]),
                                );
                              await refresh();
                              await reloadMembers();
                            },
                          })
                        }
                      >
                        {t('im.workbench.removeMember')}
                      </button>
                      {owner && (
                        <>
                          <button
                            className={buttonClass}
                            disabled={pending}
                            onClick={() =>
                              void run(async () => {
                                await im?.groups.setRole(
                                  groupId,
                                  member.username,
                                  member.role === 'admin' ? 'member' : 'admin',
                                );
                                await reloadMembers();
                              })
                            }
                          >
                            {t(
                              member.role === 'admin'
                                ? 'im.workbench.demote'
                                : 'im.workbench.promote',
                            )}
                          </button>
                          <button
                            className={buttonClass}
                            disabled={pending}
                            onClick={() =>
                              setConfirm({
                                label: t('im.workbench.transferOwner'),
                                task: async () => {
                                  await im?.groups.transferOwner(
                                    groupId,
                                    member.username,
                                  );
                                  await refresh();
                                  await reloadMembers();
                                },
                              })
                            }
                          >
                            {t('im.workbench.transferOwner')}
                          </button>
                        </>
                      )}
                    </div>
                  )}
              </li>
            ))}
          </ul>
          {snapshot.hasMore && (
            <button
              className={buttonClass}
              disabled={pending}
              onClick={() =>
                void run(async () => {
                  await list?.loadMore();
                })
              }
            >
              {t('im.workbench.loadMore')}
            </button>
          )}
          <button
            className={`${buttonClass} text-red-400`}
            disabled={pending}
            onClick={() =>
              setConfirm({
                label: t(
                  owner
                    ? 'im.workbench.dismissGroup'
                    : 'im.workbench.leaveGroup',
                ),
                task: async () => {
                  if (owner) await im?.groups.dismiss(groupId);
                  else await im?.groups.leave(groupId);
                  onLeft();
                },
              })
            }
          >
            {t(owner ? 'im.workbench.dismissGroup' : 'im.workbench.leaveGroup')}
          </button>
          {confirm && (
            <div
              role="alert"
              className="space-y-2 rounded-lg border border-red-400/30 p-3"
            >
              <p className="text-sm">
                {confirm.label} — {t('im.workbench.confirmHint')}
              </p>
              <div className="flex gap-2">
                <button
                  className={buttonClass}
                  disabled={pending}
                  onClick={() =>
                    void run(async () => {
                      await confirm.task();
                      setConfirm(null);
                    })
                  }
                >
                  {t('im.workbench.confirm')}
                </button>
                <button
                  className={buttonClass}
                  disabled={pending}
                  onClick={() => setConfirm(null)}
                >
                  {t('im.workbench.cancel')}
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

export default function GroupManager({
  groupId,
  open,
  onOpenChange,
  onLeft,
}: {
  groupId: string;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onLeft: () => void;
}) {
  const t = useT();
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[85vh] w-[calc(100%-2rem)] max-w-lg overflow-y-auto bg-[#151A26]">
        <DialogTitle>{t('im.workbench.groupSettings')}</DialogTitle>
        <DialogDescription>{t('im.workbench.groupHint')}</DialogDescription>
        {open && (
          <GroupEditor
            key={groupId}
            groupId={groupId}
            onLeft={() => {
              onOpenChange(false);
              onLeft();
            }}
          />
        )}
      </DialogContent>
    </Dialog>
  );
}
