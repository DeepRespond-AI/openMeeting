'use client';
import { meetingUi } from '@/config/meeting-ui';
import { LimitedInput } from '@/components/ui/limited-input';
import { MEETING_TITLE_MAX } from '@/lib/field-limits';

import { useEffect, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogTitle,
} from '@/components/ui/dialog';
import { useT } from '@/i18n';
import { useRoom } from './RoomProvider';
import { getMediaClient } from '@/services/live-meeting';

export default function RoomSettings({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  const t = useT();
  const { room, isHost, updateSettings, mediaState } = useRoom();
  const [title, setTitle] = useState(''),
    [pwd, setPwd] = useState('');
  const [pwdEnabled, setPwdEnabled] = useState(false),
    [waitRoom, setWaitRoom] = useState(false);
  const [saving, setSaving] = useState(false),
    [error, setError] = useState('');
  useEffect(() => {
    if (open && room) {
      setTitle(room.title);
      setPwdEnabled(room.pwdEnabled);
      setWaitRoom(room.waitRoom);
      setPwd('');
      setError('');
    }
  }, [open, room?.id]);
  if (!room || !meetingUi.settings) return null;
  const save = async () => {
    if (saving) return;
    if (!title.trim()) {
      setError(t('liveMeeting.room.settings.titleRequired'));
      return;
    }
    if (
      pwdEnabled &&
      ((pwd && !/^[0-9]{4,6}$/.test(pwd)) || (!room.pwdEnabled && !pwd))
    ) {
      setError(t('liveMeeting.room.settings.invalidPassword'));
      return;
    }
    setSaving(true);
    setError('');
    try {
      await updateSettings({
        title: title.trim(),
        pwdEnabled,
        waitRoom,
        ...(pwdEnabled && pwd ? { pwd } : {}),
      });
      onOpenChange(false);
    } catch (e) {
      setError(
        e instanceof Error ? e.message : t('liveMeeting.room.errors.generic'),
      );
    } finally {
      setSaving(false);
    }
  };
  const field =
    'w-full rounded-lg border border-white/15 bg-white/5 px-3 py-2 disabled:opacity-60';
  return (
    <Dialog
      open={open}
      onOpenChange={(value) => {
        if (!saving) onOpenChange(value);
      }}
    >
      <DialogContent className="max-h-[85vh] w-[calc(100%-2rem)] max-w-md overflow-y-auto bg-[#151A26]">
        <DialogTitle>{t('liveMeeting.room.memberMenu.settings')}</DialogTitle>
        <DialogDescription>
          {t(
            isHost
              ? 'liveMeeting.room.settings.description'
              : 'liveMeeting.room.settings.hostOnly',
          )}
        </DialogDescription>
        <form
          className="space-y-4"
          onSubmit={(e) => {
            e.preventDefault();
            void save();
          }}
        >
          <fieldset disabled={!isHost || saving} className="space-y-4">
            <label className="block space-y-1 text-sm">
              <span>{t('liveMeeting.room.settings.title')}</span>
              <LimitedInput
                className={field}
                value={title}
                maxLength={MEETING_TITLE_MAX}
                onChange={(e) => setTitle(e.target.value)}
              />
            </label>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={pwdEnabled}
                onChange={(e) => setPwdEnabled(e.target.checked)}
              />
              {t('liveMeeting.room.settings.passwordEnabled')}
            </label>
            {pwdEnabled && isHost && (
              <label className="block space-y-1 text-sm">
                <span>{t('liveMeeting.room.settings.password')}</span>
                <input
                  type="password"
                  inputMode="numeric"
                  autoComplete="new-password"
                  className={field}
                  value={pwd}
                  maxLength={6}
                  placeholder={t(
                    room.pwdEnabled
                      ? 'liveMeeting.room.settings.keepPassword'
                      : 'liveMeeting.room.settings.invalidPassword',
                  )}
                  onChange={(e) => setPwd(e.target.value)}
                />
              </label>
            )}
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={waitRoom}
                onChange={(e) => setWaitRoom(e.target.checked)}
              />
              {t('liveMeeting.room.settings.waitRoom')}
            </label>
          </fieldset>
          {meetingUi.audio && <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={mediaState.speakerEnabled}
              onChange={(e) => {
                void getMediaClient()
                  .setSpeakerEnabled(e.target.checked)
                  .catch((error) =>
                    setError(
                      error instanceof Error
                        ? error.message
                        : t('liveMeeting.room.errors.generic'),
                    ),
                  );
              }}
            />
            {t('liveMeeting.room.settings.speaker')}
          </label>}
          {error && (
            <p role="alert" className="text-sm text-red-400">
              {error}
            </p>
          )}
          {isHost && (
            <button
              disabled={saving}
              className="w-full rounded-lg bg-blue-600 px-4 py-2 disabled:opacity-50"
            >
              {t(
                saving
                  ? 'liveMeeting.room.settings.saving'
                  : 'liveMeeting.room.settings.save',
              )}
            </button>
          )}
        </form>
      </DialogContent>
    </Dialog>
  );
}
