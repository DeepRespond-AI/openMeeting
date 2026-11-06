import React, { useState, useEffect, useRef } from 'react';
import { RefreshCw, Globe, Loader2, AlertCircle, X } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import { Button } from '../ui/button';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select';
import { invoke } from '@tauri-apps/api/core';
import { listen, UnlistenFn } from '@tauri-apps/api/event';
import { toast } from 'sonner';
import { useConfig } from '@/contexts/ConfigContext';
import { LANGUAGES } from '@/constants/languages';
import Analytics from '@/lib/analytics';
import { useI18n } from '@/i18n';
import { languageLabel } from '@/hooks/meeting-details/languageLabels';

interface RetranscribeDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  meetingId: string;
  /** Local recording folder if one exists; server meetings pass null (the server uses its stored audio). */
  meetingFolderPath: string | null;
  onComplete?: () => void;
}

interface RetranscriptionProgress {
  meeting_id: string;
  stage: string;
  progress_percentage: number;
  message: string;
}

interface RetranscriptionResult {
  meeting_id: string;
  segments_count: number;
  duration_seconds: number;
  language: string | null;
}

interface RetranscriptionError {
  meeting_id: string;
  error: string;
}

export function RetranscribeDialog({
  open,
  onOpenChange,
  meetingId,
  meetingFolderPath,
  onComplete,
}: RetranscribeDialogProps) {
  const { selectedLanguage } = useConfig();
  const { t, locale } = useI18n();
  const [isProcessing, setIsProcessing] = useState(false);
  const [progress, setProgress] = useState<RetranscriptionProgress | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [selectedLang, setSelectedLang] = useState(selectedLanguage || 'auto');

  // Stable refs for callbacks to avoid listener re-registration
  const onCompleteRef = useRef(onComplete);
  const onOpenChangeRef = useRef(onOpenChange);
  useEffect(() => { onCompleteRef.current = onComplete; }, [onComplete]);
  useEffect(() => { onOpenChangeRef.current = onOpenChange; }, [onOpenChange]);

  // Track previous open state to only reset on closed→open transition
  const prevOpenRef = useRef(false);

  // Reset state only when dialog transitions from closed to open
  // This prevents re-initialization when config changes while dialog is already open
  useEffect(() => {
    const wasOpen = prevOpenRef.current;
    prevOpenRef.current = open;

    if (open && !wasOpen) {
      setIsProcessing(false);
      setProgress(null);
      setError(null);
      setSelectedLang(selectedLanguage || 'auto');
    }
  }, [open, selectedLanguage]);

  // Listen for retranscription events
  useEffect(() => {
    if (!open) return;

    const unlisteners: UnlistenFn[] = [];
    const cleanedUpRef = { current: false };

    const setupListeners = async () => {
      // Progress events
      const unlistenProgress = await listen<RetranscriptionProgress>(
        'retranscription-progress',
        (event) => {
          if (event.payload.meeting_id === meetingId) {
            setProgress(event.payload);
          }
        }
      );
      if (cleanedUpRef.current) {
        unlistenProgress();
        return;
      }
      unlisteners.push(unlistenProgress);

      // Completion event
      const unlistenComplete = await listen<RetranscriptionResult>(
        'retranscription-complete',
        async (event) => {
          if (event.payload.meeting_id === meetingId) {
            await Analytics.track('enhance_transcript_completed', {
              success: 'true',
              duration_seconds: event.payload.duration_seconds.toString(),
              segments_count: event.payload.segments_count.toString()
            });

            setIsProcessing(false);
            toast.success(t('meeting.retranscribe.complete', { n: event.payload.segments_count }));
            onCompleteRef.current?.();
            onOpenChangeRef.current(false);
          }
        }
      );
      if (cleanedUpRef.current) {
        unlistenComplete();
        unlisteners.forEach(u => u());
        return;
      }
      unlisteners.push(unlistenComplete);

      // Error event
      const unlistenError = await listen<RetranscriptionError>(
        'retranscription-error',
        async (event) => {
          if (event.payload.meeting_id === meetingId) {
            await Analytics.trackError('enhance_transcript_failed', event.payload.error);

            setIsProcessing(false);
            setError(event.payload.error);
          }
        }
      );
      if (cleanedUpRef.current) {
        unlistenError();
        unlisteners.forEach(u => u());
        return;
      }
      unlisteners.push(unlistenError);
    };

    setupListeners();

    return () => {
      cleanedUpRef.current = true;
      unlisteners.forEach((unlisten) => unlisten());
    };
  }, [open, meetingId, t]);

  const handleStartRetranscription = async () => {
    setIsProcessing(true);
    setError(null);
    setProgress(null);

    try {
      const languageToSend = selectedLang === 'auto' ? null : selectedLang;
      await Analytics.track('enhance_transcript_started', {
        language: selectedLang === 'auto' ? 'auto' : selectedLang,
        model_provider: 'server',
        model_name: ''
      });

      // The server re-transcribes its stored audio with its active STT model;
      // model/provider are decided server-side.
      await invoke('start_retranscription_command', {
        meetingId,
        meetingFolderPath: meetingFolderPath ?? '',
        language: languageToSend,
        model: null,
        provider: null,
      });
    } catch (err: any) {
      setIsProcessing(false);
      const errorMsg = typeof err === 'string' ? err : (err?.message || String(err));
      setError(errorMsg);

      await Analytics.trackError('enhance_transcript_failed', errorMsg);
    }
  };

  const handleCancel = async () => {
    if (isProcessing) {
      try {
        await invoke('cancel_retranscription_command');
        setIsProcessing(false);
        setProgress(null);
        toast.info(t('meeting.retranscribe.cancelled'));
      } catch (err) {
        console.error('Failed to cancel retranscription:', err);
      }
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

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent
        className="rounded-xl border-border bg-card shadow-elevated sm:max-w-[460px] sm:rounded-xl"
        onEscapeKeyDown={handleEscapeKeyDown}
        onInteractOutside={handleInteractOutside}
      >
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2.5 text-base font-semibold">
            {isProcessing ? (
              <>
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-accent text-primary">
                  <Loader2 className="h-4 w-4 animate-spin" />
                </span>
                {t('meeting.retranscribe.running')}
              </>
            ) : error ? (
              <>
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-destructive/10 text-destructive">
                  <AlertCircle className="h-4 w-4" />
                </span>
                {t('meeting.retranscribe.failed')}
              </>
            ) : (
              <>
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-accent text-primary">
                  <RefreshCw className="h-4 w-4" />
                </span>
                {t('meeting.retranscribe.title')}
              </>
            )}
          </DialogTitle>
          <DialogDescription>
            {isProcessing
              ? progress?.message || t('meeting.retranscribe.runningDescription')
              : error
                ? t('meeting.retranscribe.failedDescription')
                : t('meeting.retranscribe.description')}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-2">
          {!isProcessing && !error && (
            <div className="space-y-2">
              <label className="flex items-center gap-2 text-sm font-medium text-foreground">
                <Globe className="h-4 w-4 text-muted-foreground" />
                {t('meeting.retranscribe.language')}
              </label>
              <Select value={selectedLang} onValueChange={setSelectedLang}>
                <SelectTrigger className="w-full rounded-lg">
                  <SelectValue placeholder={t('meeting.retranscribe.languagePlaceholder')} />
                </SelectTrigger>
                <SelectContent className="max-h-60">
                  {LANGUAGES.map((lang) => (
                    <SelectItem key={lang.code} value={lang.code}>
                      {languageLabel(lang.code, locale, lang.name)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <p className="text-xs text-muted-foreground">{t('meeting.retranscribe.hint')}</p>
            </div>
          )}

          {isProcessing && progress && (
            <div className="space-y-2 rounded-lg bg-muted/60 p-4">
              <div className="flex justify-between text-xs text-muted-foreground">
                <span>{progress.stage}</span>
                <span className="tabular-nums font-medium text-foreground">{Math.round(progress.progress_percentage)}%</span>
              </div>
              <div className="h-2 w-full overflow-hidden rounded-full bg-secondary">
                <div
                  className="h-full rounded-full bg-primary transition-all duration-300 ease-out"
                  style={{ width: `${Math.min(progress.progress_percentage, 100)}%` }}
                />
              </div>
              <p className="text-center text-sm text-muted-foreground">{progress.message}</p>
            </div>
          )}

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
              <Button className="rounded-lg" onClick={handleStartRetranscription}>
                <RefreshCw className="h-4 w-4" />
                {t('meeting.retranscribe.start')}
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
              <Button
                onClick={() => {
                  setError(null);
                  setProgress(null);
                }}
                className="rounded-lg"
              >
                {t('meeting.retranscribe.tryAgain')}
              </Button>
            </>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
