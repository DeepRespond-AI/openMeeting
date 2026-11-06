import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  Upload,
  Globe,
  Loader2,
  AlertCircle,
  CheckCircle2,
  X,
  FileAudio,
  Clock,
  HardDrive,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import { Button } from '../ui/button';
import { LimitedInput } from '../ui/limited-input';
import { limitText, MEETING_TITLE_MAX } from '@/lib/field-limits';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select';
import { toast } from 'sonner';
import { useConfig } from '@/contexts/ConfigContext';
import { useImportAudio, ImportFailed, ImportResult, ImportUploaded } from '@/hooks/useImportAudio';
import { useRouter } from 'next/navigation';
import { useSidebar } from '../sidebar/SidebarProvider';
import { LANGUAGES } from '@/constants/languages';
import { getAudioFormatsDisplayList } from '@/constants/audioFormats';
import { useI18n } from '@/i18n';
import { cn } from '@/lib/utils';
import { languageLabel } from '@/hooks/meeting-details/languageLabels';


interface ImportAudioDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  preselectedFile?: string | null;
  onComplete?: () => void;
}

function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  return `${minutes}:${secs.toString().padStart(2, '0')}`;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
}

export function ImportAudioDialog({
  open,
  onOpenChange,
  preselectedFile,
  onComplete,
}: ImportAudioDialogProps) {
  const router = useRouter();
  const { refetchMeetings } = useSidebar();
  const { selectedLanguage } = useConfig();
  const { t, locale } = useI18n();

  const [title, setTitle] = useState('');
  const [selectedLang, setSelectedLang] = useState(selectedLanguage || 'auto');
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [titleModifiedByUser, setTitleModifiedByUser] = useState(false);

  // Always start as false — represents "dialog has not yet been opened".
  // Do NOT initialize from the `open` prop: if the component mounts with open=true
  // (e.g. drag-drop path), we still need the initialization effect to run.
  const prevOpenRef = useRef(false);

  // The upload is all the user waits for: close the dialog and open the new meeting,
  // whose transcript appears once the server has transcribed it in the background.
  const handleUploaded = useCallback((result: ImportUploaded) => {
    toast.success(t('importAudio.toast.uploaded'), { description: t('importAudio.toast.uploadedDetail') });
    refetchMeetings();
    onComplete?.();
    onOpenChange(false);
    router.push(`/meeting-details?id=${result.meeting_id}`);
  }, [router, refetchMeetings, onComplete, onOpenChange, t]);

  const handleTranscribed = useCallback((result: ImportResult) => {
    toast.success(t('importAudio.toast.complete', { title: result.title, n: result.segments_count }));
    refetchMeetings();
  }, [refetchMeetings, t]);

  // The server removes the meeting of a failed import; leave its page if it is open.
  const handleTranscribeFailed = useCallback((result: ImportFailed) => {
    toast.error(t('importAudio.toast.transcribeFailed', { title: result.title }), { description: result.error });
    refetchMeetings();
    if (new URLSearchParams(window.location.search).get('id') === result.meeting_id) {
      router.replace('/meetings');
    }
  }, [router, refetchMeetings, t]);

  const handleImportError = useCallback((error: string) => {
    toast.error(t('importAudio.toast.failed'), { description: error });
  }, [t]);

  const {
    status,
    fileInfo,
    progress,
    error,
    isProcessing,
    isBusy,
    selectFile,
    validateFile,
    startImport,
    cancelImport,
    reset,
  } = useImportAudio({
    onUploaded: handleUploaded,
    onError: handleImportError,
    onTranscribed: handleTranscribed,
    onTranscribeFailed: handleTranscribeFailed,
  });

  // Reset state only when dialog transitions from closed to open
  // This prevents re-initialization when config changes while dialog is already open (Bug #4 & #5)
  useEffect(() => {
    const wasOpen = prevOpenRef.current;
    prevOpenRef.current = open;

    // Only initialize when transitioning from closed (false) to open (true)
    if (open && !wasOpen) {
      reset();
      setTitle('');
      setTitleModifiedByUser(false);
      setSelectedLang(selectedLanguage || 'auto');
      setShowAdvanced(false);

      // Validate preselected file if provided
      if (preselectedFile) {
        validateFile(preselectedFile).then((info) => {
          if (info) {
            setTitle(info.filename);
          }
        });
      }
    }
  }, [open, preselectedFile, selectedLanguage, reset, validateFile]);

  // Update title when fileInfo changes
  useEffect(() => {
    if (fileInfo && !title && !titleModifiedByUser) {
      setTitle(limitText(fileInfo.filename, MEETING_TITLE_MAX));
    }
  }, [fileInfo, title, titleModifiedByUser]);

  const handleSelectFile = async () => {
    const info = await selectFile();
    if (info) {
      setTitle(limitText(info.filename, MEETING_TITLE_MAX));
    }
  };

  const handleStartImport = async () => {
    if (!fileInfo) return;

    await startImport(
      fileInfo.path,
      title.trim() || limitText(fileInfo.filename, MEETING_TITLE_MAX),
      selectedLang === 'auto' ? null : selectedLang,
      // The server picks the transcription model.
      null,
      null
    );
  };

  const handleCancel = async () => {
    if (isProcessing) {
      await cancelImport();
      toast.info(t('importAudio.toast.cancelled'));
    }
    onOpenChange(false);
  };

  // Prevent closing during processing
  const handleOpenChange = (newOpen: boolean) => {
    if (!newOpen && isProcessing) {
      return;
    }
    onOpenChange(newOpen);
  };

  const handleEscapeKeyDown = (event: KeyboardEvent) => {
    if (isProcessing) {
      event.preventDefault();
    }
  };

  const handleInteractOutside = (event: Event) => {
    if (isProcessing) {
      event.preventDefault();
    }
  };

  const uploadPct = Math.min(100, Math.round(progress?.progress_percentage ?? 0));
  const uploadSent = uploadPct >= 100;

  const iconCircle = (tone: 'primary' | 'destructive' | 'success') => cn(
    'flex h-8 w-8 shrink-0 items-center justify-center rounded-full',
    tone === 'primary' && 'bg-accent text-primary',
    tone === 'destructive' && 'bg-destructive/10 text-destructive',
    tone === 'success' && 'bg-success/10 text-success',
  );

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent
        className="rounded-xl border-border bg-card shadow-elevated sm:max-w-[520px] sm:rounded-xl"
        onEscapeKeyDown={handleEscapeKeyDown}
        onInteractOutside={handleInteractOutside}
      >
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2.5 text-base font-semibold">
            {isProcessing ? (
              <>
                <span className={iconCircle('primary')}><Loader2 className="h-4 w-4 animate-spin" /></span>
                {t('importAudio.importing')}
              </>
            ) : error ? (
              <>
                <span className={iconCircle('destructive')}><AlertCircle className="h-4 w-4" /></span>
                {t('importAudio.failed')}
              </>
            ) : status === 'uploaded' ? (
              <>
                <span className={iconCircle('success')}><CheckCircle2 className="h-4 w-4" /></span>
                {t('importAudio.uploaded')}
              </>
            ) : (
              <>
                <span className={iconCircle('primary')}><Upload className="h-4 w-4" /></span>
                {t('importAudio.title')}
              </>
            )}
          </DialogTitle>
          <DialogDescription>
            {isProcessing
              ? t('importAudio.uploadingHint')
              : error
              ? t('importAudio.errorDescription')
              : t('importAudio.description')}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {/* File selection / info */}
          {!isProcessing && !error && (
            <>
              {fileInfo ? (
                <div className="space-y-4 rounded-xl border border-border bg-muted/40 p-4">
                  <div className="flex items-start gap-3">
                    <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-accent text-primary">
                      <FileAudio className="h-5 w-5" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate font-medium text-foreground" title={fileInfo.filename}>{fileInfo.filename}</p>
                      <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <Clock className="h-3.5 w-3.5" />
                          {formatDuration(fileInfo.duration_seconds)}
                        </span>
                        <span className="flex items-center gap-1">
                          <HardDrive className="h-3.5 w-3.5" />
                          {formatFileSize(fileInfo.size_bytes)}
                        </span>
                        <span className="rounded-full bg-primary/10 px-2 py-0.5 font-medium text-primary">{fileInfo.format}</span>
                      </div>
                    </div>
                    <Button variant="ghost" size="sm" onClick={handleSelectFile} className="shrink-0 rounded-lg text-primary hover:text-primary">
                      {t('importAudio.file.chooseAnother')}
                    </Button>
                  </div>

                  {/* Editable title */}
                  <div className="space-y-1.5">
                    <label htmlFor="import-title" className="text-sm font-medium text-foreground">
                      {t('importAudio.file.meetingTitle')}
                    </label>
                    <LimitedInput
                      id="import-title"
                      maxLength={MEETING_TITLE_MAX}
                      className="rounded-lg bg-card"
                      value={title}
                      onChange={(e) => {
                        setTitle(e.target.value);
                        setTitleModifiedByUser(true);
                      }}
                      placeholder={t('importAudio.file.titlePlaceholder')}
                    />
                  </div>
                </div>
              ) : (
                <button
                  type="button"
                  onClick={handleSelectFile}
                  disabled={status === 'validating'}
                  className="group flex w-full flex-col items-center rounded-xl border-2 border-dashed border-border bg-muted/30 px-6 py-10 text-center transition-colors hover:border-primary/50 hover:bg-accent/50 disabled:cursor-wait"
                >
                  <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-accent text-primary transition-transform group-hover:scale-105">
                    {status === 'validating' ? <Loader2 className="h-6 w-6 animate-spin" /> : <FileAudio className="h-6 w-6" />}
                  </div>
                  <p className="text-sm font-semibold text-foreground">
                    {status === 'validating' ? t('importAudio.dropzone.validating') : t('importAudio.dropzone.title')}
                  </p>
                  <p className="mt-1 text-xs text-muted-foreground">{t('importAudio.dropzone.hint')}</p>
                  <p className="mt-3 text-[11px] uppercase tracking-wide text-muted-foreground/80">{getAudioFormatsDisplayList()}</p>
                </button>
              )}

              {/* Advanced options (collapsible) */}
              {fileInfo && (
                <div className="rounded-xl border border-border">
                  <button
                    type="button"
                    onClick={() => setShowAdvanced(!showAdvanced)}
                    className="flex w-full items-center justify-between rounded-xl px-4 py-3 text-sm font-medium text-foreground hover:bg-muted/50"
                  >
                    <span>{t('importAudio.advanced.toggle')}</span>
                    {showAdvanced ? (
                      <ChevronUp className="h-4 w-4 text-muted-foreground" />
                    ) : (
                      <ChevronDown className="h-4 w-4 text-muted-foreground" />
                    )}
                  </button>

                  {showAdvanced && (
                    <div className="space-y-2 border-t border-border px-4 pb-4 pt-3">
                      {/* Language selector (the server decides the transcription model) */}
                      <label className="flex items-center gap-2 text-sm font-medium text-foreground">
                        <Globe className="h-4 w-4 text-muted-foreground" />
                        {t('importAudio.advanced.language')}
                      </label>
                      <Select value={selectedLang} onValueChange={setSelectedLang}>
                        <SelectTrigger className="w-full rounded-lg">
                          <SelectValue placeholder={t('importAudio.advanced.languagePlaceholder')} />
                        </SelectTrigger>
                        <SelectContent className="max-h-60">
                          {LANGUAGES.map((lang) => (
                            <SelectItem key={lang.code} value={lang.code}>
                              {languageLabel(lang.code, locale, lang.name)}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      <p className="text-xs text-muted-foreground">{t('importAudio.advanced.languageHint')}</p>
                    </div>
                  )}
                </div>
              )}
            </>
          )}

          {/* Progress display */}
          {isProcessing && (
            <div className="space-y-2 rounded-lg bg-muted/60 p-4">
              <div className="flex justify-between text-xs text-muted-foreground">
                <span className="min-w-0 truncate" title={fileInfo?.filename}>
                  {uploadSent ? t('importAudio.submitting') : fileInfo?.filename ?? t('importAudio.uploadStage')}
                </span>
                {!uploadSent && <span className="shrink-0 font-medium tabular-nums text-foreground">{uploadPct}%</span>}
              </div>
              <div className="h-2 w-full overflow-hidden rounded-full bg-secondary">
                <div
                  className={cn(
                    'h-full rounded-full bg-primary transition-all duration-300 ease-out',
                    // Every byte is sent; waiting for the server to accept the file.
                    uploadSent && 'animate-pulse',
                  )}
                  style={{ width: `${uploadPct}%` }}
                />
              </div>
            </div>
          )}

          {/* Error display */}
          {error && (
            <div role="alert" className="rounded-lg border border-destructive/20 bg-destructive/10 p-3">
              <p className="break-words text-sm text-destructive">{error}</p>
            </div>
          )}
        </div>

        <DialogFooter className="gap-3">
          {!isProcessing && !error && (
            <>
              <Button variant="outline" className="rounded-lg" onClick={() => onOpenChange(false)}>
                {t('common.actions.cancel')}
              </Button>
              <Button className="rounded-lg" onClick={handleStartImport} disabled={!fileInfo}>
                <Upload className="h-4 w-4" />
                {t('importAudio.start')}
              </Button>
            </>
          )}
          {isProcessing && (
            <Button variant="outline" className="rounded-lg" onClick={handleCancel}>
              <X className="h-4 w-4" />
              {t('common.actions.cancel')}
            </Button>
          )}
          {error && (
            <>
              <Button variant="outline" className="rounded-lg" onClick={() => onOpenChange(false)}>
                {t('common.actions.close')}
              </Button>
              <Button onClick={reset} className="rounded-lg">
                {t('importAudio.tryAgain')}
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
