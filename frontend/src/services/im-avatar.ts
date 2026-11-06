import type { DRTauriClient } from '@deeprespond/im-tauri';

export const AVATAR_MAX_BYTES = 5 * 1024 * 1024;
export const AVATAR_TYPES = ['image/png', 'image/jpeg', 'image/webp'];

/** The SDK owns preprocessing, native upload, profile storage and me.changed. */
export async function saveImAvatar(client: DRTauriClient, file: File, signal: AbortSignal, progress: (percent: number | null) => void, saving: () => void) {
  const uploaded = await client.files.upload(file, {
    purpose: 'user_avatar', kind: 'image', signal,
    onProgress: (loaded, total) => progress(total ? Math.round(loaded / total * 100) : null),
  });
  if (signal.aborted) throw new DOMException('Avatar upload cancelled', 'AbortError');
  saving();
  await client.users.updateMe({ avatar_url: uploaded.url });
}
