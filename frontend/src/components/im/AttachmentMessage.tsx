'use client';
import { useCallback, useEffect, useRef, useState } from 'react';
import { useDRClient } from '@deeprespond/im-web-react';
import type { MessageView } from '@deeprespond/im-web';
import { useIm } from '@/contexts/IMContext';
import { useT } from '@/i18n';
import { Dialog, DialogContent, DialogTitle } from '@/components/ui/dialog';
import { ActionError, buttonClass, useImAction } from './useImAction';
import { attachmentPreviewKind, previewAttachment } from '@/services/im-attachment-preview';
import { FileText, ImageIcon, Play, Music2, Loader2, Expand, Download, RotateCw } from 'lucide-react';

const stopMedia = (element: HTMLMediaElement | null) => {
  if (element) { element.pause(); element.removeAttribute('src'); element.load(); }
};

/** Inline media uses the same authenticated native cache as attachment previews. */
export default function AttachmentMessage({ message }: { message: MessageView }) {
  const t = useT(), im = useDRClient(), { client } = useIm();
  const { pending, error, run, setError } = useImAction();
  const body = message.body ?? {}, kind = attachmentPreviewKind(message);
  const visual = kind === 'image' || kind === 'video';
  const name = typeof body.name === 'string' ? body.name : t(`im.workbench.type_${kind === 'text' || !kind ? 'file' : kind}`);
  const url = typeof body.url === 'string' ? body.url : '';
  const [src, setSrc] = useState(''), [text, setText] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(false), [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState<number | null>(null);
  const host = useRef<HTMLDivElement>(null), video = useRef<HTMLVideoElement | null>(null);
  const dialogVideo = useRef<HTMLVideoElement | null>(null), dialogAudio = useRef<HTMLAudioElement | null>(null);
  const bindVideo = useCallback((element: HTMLVideoElement | null) => {
    if (video.current !== element) stopMedia(video.current); video.current = element;
  }, []);
  const bindDialogVideo = useCallback((element: HTMLVideoElement | null) => {
    if (dialogVideo.current !== element) stopMedia(dialogVideo.current); dialogVideo.current = element;
  }, []);
  const bindDialogAudio = useCallback((element: HTMLAudioElement | null) => {
    if (dialogAudio.current !== element) stopMedia(dialogAudio.current); dialogAudio.current = element;
  }, []);
  const release = useRef<(() => void) | null>(null), controller = useRef<AbortController | null>(null);
  const epoch = useRef(0), resumeAt = useRef(0);
  const loadRef = useRef<(open?: boolean) => Promise<unknown>>(() => Promise.resolve());
  useEffect(() => {
    const element = host.current;
    if (!visual || !client || !im || !element) return;
    // A long history must not download every attachment on mount.
    if (!('IntersectionObserver' in window)) { void loadRef.current(); return; }
    const observer = new IntersectionObserver(entries => {
      if (entries.some(entry => entry.isIntersecting)) { observer.disconnect(); void loadRef.current(); }
    });
    observer.observe(element);
    return () => observer.disconnect();
  }, [visual, client, im]);
  useEffect(() => {
    return () => {
      ++epoch.current; controller.current?.abort();
      stopMedia(video.current); stopMedia(dialogVideo.current); stopMedia(dialogAudio.current);
      release.current?.(); release.current = null;
    };
  }, []);
  const load = (open = false) => run(async () => {
    if (!client || !im || !url || !im.files.isFileUrl(url)) throw Error(t('im.workbench.invalidAttachment'));
    if (Number(body.size) > 30 * 1024 * 1024) throw Error(t('im.workbench.previewLimit'));
    if (kind === 'text' && Number(body.size) > 1024 * 1024) throw Error(t('im.workbench.textPreviewLimit'));
    if (src) { if (open) setExpanded(true); return; }
    const generation = ++epoch.current, abort = new AbortController();
    controller.current = abort; setProgress(0);
    try {
      const loaded = await previewAttachment(client, message, abort, setProgress);
      if (generation !== epoch.current) { loaded.release(); return; }
      release.current = loaded.release; setSrc(loaded.src); setText(loaded.text ?? null);
      if (open) setExpanded(true);
    } catch (failure) {
      if (abort.signal.aborted && !(failure instanceof Error && /exceeds/.test(failure.message))) return;
      if (failure instanceof Error && failure.message === 'Text preview exceeds 1 MB') throw Error(t('im.workbench.textPreviewLimit'));
      if (failure instanceof Error && failure.message === 'Preview exceeds 30 MB') throw Error(t('im.workbench.previewLimit'));
      throw failure;
    } finally { if (controller.current === abort) controller.current = null; setProgress(null); }
  });
  loadRef.current = load;
  const download = () => run(async () => {
    if (!client) return;
    const abort = new AbortController(); controller.current = abort; setProgress(0);
    try { await client.desktop.download({ message }, { signal: abort.signal,
      onProgress: (loaded, total) => setProgress(total ? Math.round(loaded / total * 100) : null) }); }
    finally { if (controller.current === abort) controller.current = null; setProgress(null); }
  });
  const changeExpanded = (open: boolean) => {
    if (open) { resumeAt.current = video.current?.currentTime ?? 0; video.current?.pause(); }
    else {
      dialogVideo.current?.pause(); dialogAudio.current?.pause();
      if (!visual) { ++epoch.current; controller.current?.abort(); release.current?.(); release.current = null; setSrc(''); setText(null); }
    }
    setExpanded(open);
  };
  const mediaError = () => {
    video.current?.pause(); setPlaying(false); release.current?.(); release.current = null;
    setSrc(''); setError(t('im.workbench.invalidAttachment'));
  };
  const play = async () => {
    try { await video.current?.play(); } catch { setError(t('im.workbench.invalidAttachment')); }
  };
  const Icon = kind === 'video' ? Play : kind === 'image' ? ImageIcon : kind === 'voice' ? Music2 : FileText;
  const type = kind === 'text' || !kind ? 'file' : kind;
  return <div ref={host} data-testid="attachment-message" className={`max-w-full space-y-2 ${visual ? 'w-[260px]' : ''}`}>
    {visual ? <div className="relative overflow-hidden rounded-xl border border-border/70 bg-background/60">
      {src ? kind === 'image' ? <button type="button" className="block w-full cursor-zoom-in focus-visible:outline focus-visible:outline-2 focus-visible:outline-primary"
        aria-label={t('im.workbench.viewImage', { name })} onClick={() => changeExpanded(true)}>
        <img src={src} alt={name} className="max-h-64 w-full object-contain" onError={mediaError} />
      </button> : <div className="relative bg-black">
        <video ref={bindVideo} src={src} controls={playing} playsInline preload="auto" aria-label={name}
          className="aspect-video max-h-64 w-full object-contain" onPlay={() => setPlaying(true)} onError={mediaError} />
        {!playing && <button type="button" aria-label={t('im.workbench.playVideo', { name })} onClick={() => void play()}
          className="absolute inset-0 flex items-center justify-center bg-black/15 text-white hover:bg-black/25 focus-visible:outline focus-visible:outline-2 focus-visible:outline-primary">
          <span className="flex h-12 w-12 items-center justify-center rounded-full bg-black/65 shadow-elevated"><Play className="ml-0.5 h-6 w-6 fill-current" /></span>
        </button>}
        <button type="button" aria-label={t('im.workbench.expandVideo')} title={t('im.workbench.expandVideo')} onClick={() => changeExpanded(true)}
          className="absolute right-2 top-2 rounded-full bg-black/65 p-2 text-white hover:bg-black/85"><Expand className="h-4 w-4" /></button>
      </div> : <div className="flex aspect-video items-center justify-center gap-2 text-muted-foreground">
        {pending ? <><Loader2 className="h-5 w-5 animate-spin" /><span role="status" className="text-xs">{t('im.workbench.loading')}{progress !== null ? ` ${progress}%` : ''}</span></>
          : <button type="button" disabled={!client} onClick={() => void load()} aria-label={t('im.workbench.retryMedia')}
            className="flex min-h-16 items-center gap-2 rounded-lg px-3 text-xs hover:bg-accent disabled:opacity-50"><RotateCw className="h-4 w-4" />{t('im.workbench.retryMedia')}</button>}
      </div>}
      <div className="flex min-w-0 items-center gap-2 border-t border-border/50 px-2.5 py-2">
        <span className="min-w-0 flex-1 truncate text-[11px] text-muted-foreground" title={name}>{name}</span>
        <button type="button" disabled={pending || !client} onClick={() => void download()} aria-label={t('im.workbench.download')} title={t('im.workbench.download')}
          className="shrink-0 rounded-md p-1 text-muted-foreground hover:bg-accent hover:text-foreground disabled:opacity-40"><Download className="h-4 w-4" /></button>
      </div>
    </div> : <>
      <button type="button" aria-label={kind ? `${t('im.workbench.preview')}: ${name}` : t('im.workbench.downloadOnly')}
        disabled={pending || !client} onClick={() => void (kind ? load(true) : download())}
        className="flex w-full min-w-0 items-center gap-3 rounded-xl border border-border/70 bg-background/40 p-3 text-left hover:bg-accent disabled:opacity-50">
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"><Icon className="h-5 w-5" /></span>
        <span className="min-w-0 flex-1"><span className="block break-words text-xs font-medium [overflow-wrap:anywhere]">{name}</span>
          <span className="mt-1 block text-[10px] text-muted-foreground">{t(`im.workbench.type_${type}`)}{typeof body.size === 'number' ? ` · ${(body.size / 1024).toFixed(1)} KB` : ''}</span>
        </span>
      </button>
      <div className="flex flex-wrap gap-2">
        {kind && <button className={buttonClass} disabled={pending || !client} onClick={() => void load(true)}>{t('im.workbench.preview')}</button>}
        <button className={buttonClass} disabled={pending || !client} onClick={() => void download()}>{t('im.workbench.download')}</button>
      </div>
    </>}
    {pending && <button className={buttonClass} onClick={() => controller.current?.abort()}>{t('im.workbench.cancel')}</button>}
    {(!visual || src) && progress !== null && <p role="status" className="text-xs">{progress}%</p>}
    <ActionError error={error} />
    <Dialog open={expanded} onOpenChange={changeExpanded}>
      <DialogContent className="max-h-[90vh] w-[calc(100%-2rem)] max-w-3xl overflow-y-auto bg-card">
        <DialogTitle className="break-words pr-8 [overflow-wrap:anywhere]">{name}</DialogTitle>
        <ActionError error={error} />
        {src && (kind === 'text' ? <pre className="max-h-[65vh] overflow-auto whitespace-pre-wrap rounded-lg bg-muted p-3 text-sm [overflow-wrap:anywhere]">{text}</pre>
          : kind === 'image' ? <img src={src} alt={name} className="max-h-[70vh] max-w-full object-contain" onError={mediaError} />
          : kind === 'video' ? <video ref={bindDialogVideo} src={src} controls playsInline className="max-h-[70vh] w-full" onLoadedMetadata={event => { event.currentTarget.currentTime = resumeAt.current; }} onError={mediaError} />
          : <audio ref={bindDialogAudio} src={src} controls className="max-w-full" onError={mediaError} />)}
      </DialogContent>
    </Dialog>
  </div>;
}
