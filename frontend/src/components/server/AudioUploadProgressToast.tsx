'use client';

import { useEffect } from 'react';
import { TOAST_DURATION_MS } from '@/lib/toast';
import { listen } from '@tauri-apps/api/event';
import { toast } from 'sonner';
import { t } from '@/i18n';

interface AudioUploadProgressPayload {
  meetingId: string;
  /** 0-100 */
  progress: number;
  done: boolean;
  error: string | null;
}

const toastId = (meetingId: string) => `audio-upload-${meetingId}`;

/**
 * Listens for `audio-upload-progress` (emitted by Rust while the recording is
 * uploaded to the server after stop) and shows a single, updating toast per meeting.
 */
export function AudioUploadProgressToast() {
  useEffect(() => {
    let disposed = false;
    let unlisten: (() => void) | undefined;

    listen<AudioUploadProgressPayload>('audio-upload-progress', (event) => {
      const { meetingId, progress, done, error } = event.payload;
      const id = toastId(meetingId);

      if (error) {
        toast.error(t('server.upload.failed'), {
          id,
          description: error,
        });
        return;
      }

      if (done) {
        toast.success(t('server.upload.done'), { id });
        return;
      }

      const pct = Math.max(0, Math.min(100, Math.round(progress ?? 0)));
      // Loading toasts ignore the global default; each progress update restarts the timer.
      toast.loading(t('server.upload.progress', { pct }), {
        id,
        duration: TOAST_DURATION_MS,
      });
    })
      .then((fn) => {
        if (disposed) fn();
        else unlisten = fn;
      })
      .catch((err) => console.error('[AudioUploadProgressToast] Failed to listen:', err));

    return () => {
      disposed = true;
      unlisten?.();
    };
  }, []);

  return null;
}
