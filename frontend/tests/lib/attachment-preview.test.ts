import { expect, mock, test } from 'bun:test';
const removed: string[] = [];
mock.module('@tauri-apps/api/path', () => ({ appCacheDir: async () => '/cache', join: async (...p: string[]) => p.join('/') }));
mock.module('@tauri-apps/plugin-fs', () => ({ remove: async (p: string) => { removed.push(p); }, readTextFile: async () => '<script>not executed</script>\nhello' }));
const { attachmentPreviewKind, previewAttachment } = await import('../../src/services/im-attachment-preview');
const message = (name: string, size = 3) => ({type:'file',body:{name,size,url:'im://file'}} as any);
const client: any = {files:{isFileUrl:(url: string)=>url==='im://file'},desktop:{download:async (_: any, opts: any)=>({path:opts.saveTo,size:3}),fileUrl:(path: string)=>`native://${path}`}};
test('safe preview allowlist recognizes media and text but never HTML or executables', () => {
  expect(attachmentPreviewKind(message('clip.MP4'))).toBe('video');
  expect(attachmentPreviewKind(message('notes.md'))).toBe('text');
  expect(attachmentPreviewKind(message('page.html'))).toBeNull();
  expect(attachmentPreviewKind(message('program.exe'))).toBeNull();
});
test('text previews use native authenticated download and release their cache', async () => {
  const result = await previewAttachment(client, message('notes.txt'), new AbortController(), () => {});
  expect(result.text).toContain('<script>not executed</script>');
  expect(result.src).toStartWith('native:///cache/deeprespond_im/');
  await result.release(); expect(removed.at(-1)).toEndWith('.txt');
});
test('oversize and untrusted attachment references are rejected', async () => {
  await expect(previewAttachment(client, message('notes.txt', 1048577), new AbortController(), () => {})).rejects.toThrow('1 MB');
  await expect(previewAttachment(client, {...message('clip.mp4'),body:{url:'https://untrusted'}}, new AbortController(), () => {})).rejects.toThrow('Invalid attachment');
  const abort = new AbortController();
  const streaming = {...client,desktop:{...client.desktop,download:async (_: any, options: any) => {
    options.onProgress(1048577, null);
    throw Error('Request aborted');
  }}};
  await expect(previewAttachment(streaming, message('unknown-size.txt',0), abort, () => {})).rejects.toThrow('1 MB');
  expect(abort.signal.aborted).toBe(true);
});
