'use client';
import { useEffect, useRef, useState } from 'react';
import { useDRClient } from '@deeprespond/im-web-react';
import type { ConversationView, VoiceRecorder } from '@deeprespond/im-web';
import { useT } from '@/i18n';
import {
  ActionError,
  buttonClass,
  inputClass,
  useImAction,
} from './useImAction';

export default function MessageComposer({
  view,
  online,
}: {
  view: ConversationView;
  online: boolean;
}) {
  const im = useDRClient(),
    t = useT(),
    { pending, error, run, setError } = useImAction();
  const [draft, setDraft] = useState(view.draft?.text ?? ''),
    [file, setFile] = useState<File | null>(null),
    [recording, setRecording] = useState(false),
    [seconds, setSeconds] = useState(0),
    [locationOpen, setLocationOpen] = useState(false);
  const [latitude, setLatitude] = useState(''),
    [longitude, setLongitude] = useState(''),
    [place, setPlace] = useState('');
  const recorder = useRef<VoiceRecorder | null>(null),
    active = useRef(true),
    draftRef = useRef(draft),
    dirty = useRef(false);
  draftRef.current = draft;
  const target = { conversation_key: view.conversation_key };
  useEffect(() => {
    active.current = true;
    return () => {
      active.current = false;
      recorder.current?.cancel();
      if (dirty.current)
        void im?.conversations
          .setDraft(
            view.conversation_key,
            draftRef.current ? { text: draftRef.current } : null,
          )
          .catch(() => {});
    };
  }, [im, view.conversation_key]);
  useEffect(() => {
    if (!recording) return;
    const started = Date.now();
    const timer = setInterval(() => {
      const elapsed = Math.floor((Date.now() - started) / 1000);
      if (elapsed >= 120) {
        recorder.current?.cancel();
        recorder.current = null;
        setRecording(false);
        setSeconds(0);
        setError(t('im.workbench.recordingLimit'));
      } else setSeconds(elapsed);
    }, 1000);
    return () => clearInterval(timer);
  }, [recording, setError, t]);
  const send = () =>
    run(async () => {
      if (!im || recording) return;
      if (file) {
        const type = file.type.startsWith('image/')
          ? 'image'
          : file.type.startsWith('video/')
            ? 'video'
            : 'file';
        await im.messages.send(target, {
          type,
          file,
          body: { name: file.name },
        });
        if (active.current) setFile(null);
      }
      if (draft.trim()) {
        await im.messages.send(target, {
          type: 'text',
          body: { text: draft.trim() },
        });
        if (active.current) {
          setDraft('');
          draftRef.current = '';
          dirty.current = false;
        }
        await im.conversations.setDraft(view.conversation_key, null);
      }
    });
  const record = () =>
    run(async () => {
      if (!im) return;
      if (recorder.current) {
        const current = recorder.current;
        recorder.current = null;
        setRecording(false);
        const result = await current.stop();
        if (!active.current) return;
        await im.messages.send(target, {
          type: 'voice',
          file: result.blob,
          body: { duration_seconds: result.duration_seconds },
        });
      } else {
        const next = await im.files.recordVoice();
        if (!active.current) {
          next.cancel();
          return;
        }
        recorder.current = next;
        try {
          await next.start();
          if (!active.current) {
            next.cancel();
            return;
          }
          setSeconds(0);
          setRecording(true);
        } catch (e) {
          next.cancel();
          recorder.current = null;
          throw e;
        }
      }
    });
  const sendLocation = () =>
    run(async () => {
      const lat = Number(latitude),
        lon = Number(longitude);
      if (
        !latitude.trim() ||
        !longitude.trim() ||
        !Number.isFinite(lat) ||
        !Number.isFinite(lon) ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180
      )
        throw new Error(t('im.workbench.invalidLocation'));
      await im?.messages.send(target, {
        type: 'location',
        body: { latitude: lat, longitude: lon, name: place.trim() },
      });
      setLocationOpen(false);
    });
  return (
    <div className="space-y-2 border-t border-white/10 p-3">
      {!online && (
        <p className="text-xs text-amber-300">{t('im.chats.offline')}</p>
      )}
      <ActionError error={error} />
      <div className="flex flex-wrap items-center gap-2">
        <label
          className={`${buttonClass} ${pending || recording ? 'pointer-events-none opacity-40' : 'cursor-pointer'}`}
        >
          {t('im.workbench.attach')}
          <input
            aria-label={t('im.workbench.attach')}
            className="sr-only"
            type="file"
            disabled={pending || recording}
            onChange={(e) => {
              const selected = e.target.files?.[0];
              e.target.value = '';
              if (selected) {
                if (selected.size > 100 * 1024 * 1024) {
                  setError(t('im.workbench.fileLimit'));
                  return;
                }
                setFile(selected);
              }
            }}
          />
        </label>
        <button
          className={buttonClass}
          disabled={pending || !!file}
          onClick={() => void record()}
        >
          {recording
            ? `${t('im.workbench.stopAndSend')} (${seconds}s)`
            : t('im.workbench.recordVoice')}
        </button>
        {recording && (
          <button
            className={buttonClass}
            disabled={pending}
            onClick={() => {
              recorder.current?.cancel();
              recorder.current = null;
              setRecording(false);
            }}
          >
            {t('im.workbench.cancel')}
          </button>
        )}
        <button
          className={buttonClass}
          disabled={pending || recording}
          onClick={() => setLocationOpen((v) => !v)}
        >
          {t('im.workbench.location')}
        </button>
      </div>
      {file && (
        <div className="flex items-center gap-2 text-xs">
          <span className="min-w-0 truncate">
            {file.name} · {(file.size / 1024).toFixed(1)} KB
          </span>
          <button
            className={buttonClass}
            disabled={pending}
            onClick={() => setFile(null)}
          >
            {t('im.workbench.cancel')}
          </button>
        </div>
      )}
      {locationOpen && (
        <div className="space-y-2 rounded-lg border border-white/10 p-2">
          <label className="block text-xs">
            {t('im.workbench.place')}
            <input
              className={inputClass}
              value={place}
              maxLength={100}
              onChange={(e) => setPlace(e.target.value)}
            />
          </label>
          <div className="flex gap-2">
            <input
              className={inputClass}
              inputMode="decimal"
              aria-label={t('im.workbench.latitude')}
              placeholder={t('im.workbench.latitude')}
              value={latitude}
              onChange={(e) => setLatitude(e.target.value)}
            />
            <input
              className={inputClass}
              inputMode="decimal"
              aria-label={t('im.workbench.longitude')}
              placeholder={t('im.workbench.longitude')}
              value={longitude}
              onChange={(e) => setLongitude(e.target.value)}
            />
          </div>
          <button
            className={buttonClass}
            disabled={pending}
            onClick={() => void sendLocation()}
          >
            {t('im.chats.send')}
          </button>
        </div>
      )}
      <form
        className="flex items-end gap-2"
        onSubmit={(e) => {
          e.preventDefault();
          void send();
        }}
      >
        <textarea
          className={`${inputClass} max-h-32 resize-y`}
          aria-label={t('im.chats.inputPlaceholder')}
          placeholder={t('im.chats.inputPlaceholder')}
          maxLength={2000}
          rows={2}
          value={draft}
          disabled={pending || recording}
          onChange={(e) => {
            dirty.current = true;
            setDraft(e.target.value);
            im?.conversations.typing(view.conversation_key);
          }}
          onKeyDown={(e) => {
            if (
              e.key === 'Enter' &&
              !e.shiftKey &&
              !e.nativeEvent.isComposing
            ) {
              e.preventDefault();
              void send();
            }
          }}
        />
        <button
          className={`${buttonClass} shrink-0 whitespace-nowrap`}
          disabled={pending || recording || (!file && !draft.trim())}
        >
          {t(pending ? 'im.workbench.working' : 'im.chats.send')}
        </button>
      </form>
    </div>
  );
}
