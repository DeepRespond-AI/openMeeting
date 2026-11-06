'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import { getRecordingStatus, retryRecording } from '@/services/live-meeting/recording';
import { mapLiveError } from '@/services/live-meeting/real';
import type { RecordingSnapshot } from '@/lib/meeting-processing';
import { useT } from '@/i18n';

export default function RoomRecordingStatus({ meetingId, onComplete, onStatusChange, readOnly = false }: {
  meetingId: string; onComplete: () => void; onStatusChange?: (snapshot: RecordingSnapshot) => void; readOnly?: boolean;
}) {
  const t = useT();
  const [snapshot, setSnapshot] = useState<RecordingSnapshot>({ data: null, error: null });
  const [retrying, setRetrying] = useState(false);
  const last = useRef<string>();
  const generation = useRef(0);
  const request = useRef(0);
  const callbacks = useRef({ onComplete, onStatusChange });
  callbacks.current = { onComplete, onStatusChange };
  const publish = useCallback((value: RecordingSnapshot) => {
    setSnapshot(value);
    callbacks.current.onStatusChange?.(value);
  }, []);
  const refresh = useCallback(async (owner: number) => {
    const read = ++request.current;
    try {
      const value = await getRecordingStatus(meetingId);
      if (generation.current !== owner || request.current !== read) return;
      publish({ data: value, error: null });
      if (['completed', 'failed', 'cancelled'].includes(value.status) && last.current !== value.status) callbacks.current.onComplete();
      last.current = value.status;
    } catch (err) {
      if (generation.current === owner && request.current === read) publish({ data: null, error: mapLiveError(err).message });
    }
  }, [meetingId, publish]);
  useEffect(() => {
    const owner = ++generation.current;
    last.current = undefined;
    publish({ data: null, error: null });
    let timer: ReturnType<typeof setTimeout>;
    const poll = async () => {
      await refresh(owner);
      if (generation.current === owner) timer = setTimeout(() => void poll(), 2000);
    };
    void poll();
    return () => { generation.current++; clearTimeout(timer); };
  }, [refresh, publish]);
  const { data: state, error } = snapshot;
  const failed = state?.status === 'failed' || state?.status === 'cancelled';
  if (state?.status === 'none' && !error) return null;
  return <div data-testid="recording-job-status" role={error || failed ? 'alert' : 'status'} className="mx-4 mt-3 flex shrink-0 flex-wrap items-center gap-3 rounded-xl border border-border bg-card p-3 text-sm">
    <span className="min-w-0 flex-1 break-words">{error || (failed ? t('meeting.processing.failed', { error: state?.error || t('meeting.processing.cancelled') }) : state?.status === 'completed' ? t('meeting.shared.completed') : state?.message || t(state?.status === 'queued' || state?.status === 'running' ? 'meeting.transcript.processing' : 'meeting.transcript.checking'))}</span>
    {!readOnly && failed && <button disabled={retrying} className="rounded-lg bg-primary px-3 py-2 text-primary-foreground" onClick={async () => {
      const owner = generation.current;
      setRetrying(true);
      try {
        await retryRecording(meetingId);
        if (generation.current !== owner) return;
        last.current = undefined;
        await refresh(owner);
      } catch (err) {
        if (generation.current === owner) publish({ data: state, error: mapLiveError(err).message });
      } finally { if (generation.current === owner) setRetrying(false); }
    }}>{t(retrying ? 'meeting.processing.retrying' : 'meeting.processing.retry')}</button>}
  </div>;
}
