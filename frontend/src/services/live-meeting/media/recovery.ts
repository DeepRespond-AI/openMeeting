import type { LiveMeetingApi } from '../api';

export class MediaReleaseTimeout extends Error {}

/** Bound SDK/IPC waits even when the underlying API has no AbortSignal. */
export async function rtcWait<T>(pending: Promise<T>, signal: AbortSignal, deadline: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  let cancel: () => void = () => {};
  try {
    return await new Promise<T>((resolve, reject) => {
      cancel = () => reject(new Error('RTC operation cancelled'));
      pending.then(resolve, reject);
      timer = setTimeout(() => reject(new MediaReleaseTimeout()), Math.max(0, deadline - Date.now()));
      signal.addEventListener('abort', cancel, {once:true});
      if (signal.aborted) cancel();
    });
  } finally {
    clearTimeout(timer);
    signal.removeEventListener('abort', cancel);
  }
}

/** No replacement ticket is requested before the platform confirms release. */
export async function recoverRoomRtc(api: LiveMeetingApi, roomId: string, sessionId: string, signal: AbortSignal) {
  if (!api.recoverRoomMedia || !api.getRoomMedia) throw new Error('RTC recovery is unavailable');
  const deadline = Date.now() + 20_000;
  while (!signal.aborted) {
    if (Date.now() >= deadline) throw new MediaReleaseTimeout();
    const result = await rtcWait(api.recoverRoomMedia(roomId, sessionId), signal, deadline);
    if (result.released === true) {
      if (signal.aborted) throw new Error('RTC operation cancelled');
      return rtcWait(api.getRoomMedia(roomId), signal, deadline);
    }
    await rtcWait(new Promise<void>(resolve => setTimeout(resolve, 500)), signal, deadline);
  }
  throw new Error('RTC operation cancelled');
}
