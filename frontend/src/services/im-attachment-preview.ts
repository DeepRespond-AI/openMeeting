import type { DRTauriClient, MessageView } from '@deeprespond/im-tauri';
import { appCacheDir, join } from '@tauri-apps/api/path';
import { readTextFile, remove } from '@tauri-apps/plugin-fs';

const LIMIT = 30 * 1024 * 1024;

/** A generic file message may still contain playable media. Never execute files. */
export function attachmentPreviewKind(message: Pick<MessageView, 'type' | 'body'>): 'image' | 'video' | 'voice' | 'text' | null {
  if (message.type === 'image' || message.type === 'video' || message.type === 'voice') return message.type;
  if (message.type !== 'file') return null;
  const ext = typeof message.body?.name === 'string' ? message.body.name.split('.').pop()?.toLowerCase() : '';
  if (ext && ['png', 'jpg', 'jpeg', 'webp', 'gif', 'avif', 'bmp'].includes(ext)) return 'image';
  if (ext && ['mp4', 'webm', 'mov', 'm4v'].includes(ext)) return 'video';
  if (ext && ['wav', 'mp3', 'ogg', 'opus', 'aac', 'm4a'].includes(ext)) return 'voice';
  if (ext && ['txt', 'md', 'csv', 'json', 'log'].includes(ext)) return 'text';
  return null;
}

/** SDK media messages may omit a filename; format describes the uploaded bytes. */
export function previewExtension(message: Pick<MessageView, 'type' | 'body'>) {
  const suffix = typeof message.body?.name === 'string' ? message.body.name.split('.').pop()?.toLowerCase() : '';
  const format = typeof message.body?.format === 'string' ? message.body.format.toLowerCase() : '';
  const allowed = message.type === 'image' ? ['png','jpg','jpeg','webp','gif','avif','bmp','heic']
    : message.type === 'video' ? ['mp4','webm','mov','m4v'] : ['wav','mp3','webm','ogg','opus','aac','m4a'];
  return [format,suffix].find(value => value && allowed.includes(value))
    || (message.type === 'image' ? 'png' : message.type === 'video' ? 'mp4' : 'webm');
}

/** Use the SDK's authenticated resolver and Rust transport, as downloads do.
 * Keep previews in the SDK cache, whose native protocol grants scoped reading.
 * Never open an OSS URL in the WebView or put previews in the Downloads folder. */
export async function previewAttachment(
  client: DRTauriClient,
  message: MessageView,
  controller: AbortController,
  progress: (percent: number | null) => void,
) {
  const url = message.body?.url;
  if (typeof url !== 'string' || !client.files.isFileUrl(url)) throw new Error('Invalid attachment');
  const kind = attachmentPreviewKind(message);
  if (!kind) throw new Error('Invalid preview type');
  const limit = kind === 'text' ? 1024 * 1024 : LIMIT;
  if (kind === 'text' && Number(message.body?.size) > 1024 * 1024) throw new Error('Text preview exceeds 1 MB');
  if (Number(message.body?.size) > LIMIT) throw new Error('Preview exceeds 30 MB');
  // Preserve common media suffixes for the SDK local protocol's MIME lookup.
  // Only a fixed extension allowlist reaches the generated cache filename.
  const ext = kind === 'text' ? 'txt' : previewExtension({ ...message, type: kind });
  const path = await join(await appCacheDir(), 'deeprespond_im', `openmeeting-preview-${crypto.randomUUID()}.${ext}`);
  const release = () => remove(path).catch(() => {});
  let oversized = false;
  try {
    const saved = await client.desktop.download({ message }, {
      saveTo: path, conflict: 'overwrite', signal: controller.signal,
      onProgress: (loaded, total) => {
        if (loaded > limit || (total !== null && total > limit)) {
          oversized = true;
          controller.abort();
        }
        progress(total ? Math.round(loaded / total * 100) : null);
      },
    });
    if (oversized || saved.size > limit) throw new Error(kind === 'text' ? 'Text preview exceeds 1 MB' : 'Preview exceeds 30 MB');
    if (controller.signal.aborted) throw new Error('Preview cancelled');
    const text = kind === 'text' ? await readTextFile(saved.path) : undefined;
    if (controller.signal.aborted) throw new Error('Preview cancelled');
    return { src: client.desktop.fileUrl(saved.path), text, release };
  } catch (error) {
    await release();
    if (oversized) throw new Error(kind === 'text' ? 'Text preview exceeds 1 MB' : 'Preview exceeds 30 MB');
    throw error;
  }
}
