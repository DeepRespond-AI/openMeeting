import { useState, useEffect, useCallback, useRef } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { listen, UnlistenFn } from '@tauri-apps/api/event';
import Analytics from '@/lib/analytics';
import { applyPinnedSummaryLanguageToMeeting } from '@/lib/summary-language-preferences';
import { toast } from 'sonner';
import { t } from '@/i18n';

export interface AudioFileInfo {
  path: string;
  filename: string;
  duration_seconds: number;
  size_bytes: number;
  format: string;
}

export interface ImportProgress {
  stage: string;
  progress_percentage: number;
  message: string;
}

export interface ImportResult {
  meeting_id: string;
  title: string;
  segments_count: number;
  duration_seconds: number;
}

/** The file reached the server; transcription continues in the background. */
export interface ImportUploaded {
  meeting_id: string;
  title: string;
}

/** Background transcription of an uploaded file failed (the server removed the meeting). */
export interface ImportFailed {
  meeting_id: string;
  title: string;
  error: string;
}

export interface ImportError {
  error: string;
}

/** Dialog state: only validation and the upload happen in the dialog. */
export type ImportStatus = 'idle' | 'validating' | 'uploading' | 'uploaded' | 'error';

export interface UseImportAudioOptions {
  /** Upload finished — the dialog can close. */
  onUploaded?: (result: ImportUploaded) => void;
  /** Upload (or starting it) failed. */
  onError?: (error: string) => void;
  /** Background transcription finished (fires even after the dialog closed). */
  onTranscribed?: (result: ImportResult) => void;
  /** Background transcription failed (fires even after the dialog closed). */
  onTranscribeFailed?: (result: ImportFailed) => void;
}

export interface UseImportAudioReturn {
  status: ImportStatus;
  fileInfo: AudioFileInfo | null;
  progress: ImportProgress | null;
  error: string | null;
  isProcessing: boolean;
  isBusy: boolean;
  selectFile: () => Promise<AudioFileInfo | null>;
  validateFile: (path: string) => Promise<AudioFileInfo | null>;
  startImport: (
    sourcePath: string,
    title: string,
    language?: string | null,
    model?: string | null,
    provider?: string | null
  ) => Promise<void>;
  cancelImport: () => Promise<void>;
  reset: () => void;
}

export function useImportAudio({
  onUploaded,
  onError,
  onTranscribed,
  onTranscribeFailed,
}: UseImportAudioOptions = {}): UseImportAudioReturn {
  const [status, setStatus] = useState<ImportStatus>('idle');
  const [fileInfo, setFileInfo] = useState<AudioFileInfo | null>(null);
  const [progress, setProgress] = useState<ImportProgress | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Stable refs for callbacks to avoid listener re-registration on every render
  const onUploadedRef = useRef(onUploaded);
  const onErrorRef = useRef(onError);
  const onTranscribedRef = useRef(onTranscribed);
  const onTranscribeFailedRef = useRef(onTranscribeFailed);
  useEffect(() => { onUploadedRef.current = onUploaded; }, [onUploaded]);
  useEffect(() => { onErrorRef.current = onError; }, [onError]);
  useEffect(() => { onTranscribedRef.current = onTranscribed; }, [onTranscribed]);
  useEffect(() => { onTranscribeFailedRef.current = onTranscribeFailed; }, [onTranscribeFailed]);

  // Cancellation guard: prevents late upload events from updating state after cancel
  const isCancelledRef = useRef(false);

  // Set up event listeners (registered once, use refs for callbacks)
  useEffect(() => {
    let disposed = false;
    const unlisteners: UnlistenFn[] = [];
    const register = <T,>(event: string, handler: (payload: T) => void) => {
      listen<T>(event, (e) => handler(e.payload)).then((unlisten) => {
        if (disposed) unlisten();
        else unlisteners.push(unlisten);
      });
    };

    // Upload phase (shown in the dialog)
    register<ImportProgress>('import-progress', (payload) => {
      if (isCancelledRef.current) return;
      setProgress(payload);
      setStatus('uploading');
    });

    register<ImportUploaded>('import-uploaded', async (payload) => {
      if (isCancelledRef.current) return;
      setStatus('uploaded');
      setProgress(null);
      onUploadedRef.current?.(payload);
      try {
        await applyPinnedSummaryLanguageToMeeting(payload.meeting_id);
      } catch (error) {
        console.warn('Failed to apply pinned summary language to imported meeting:', error);
        toast.warning(t('importAudio.toast.languageNotApplied'), {
          description: t('importAudio.toast.languageNotAppliedDetail'),
        });
      }
    });

    register<ImportError>('import-error', async (payload) => {
      if (isCancelledRef.current) return;
      setStatus('error');
      setError(payload.error);
      onErrorRef.current?.(payload.error);
      await Analytics.trackError('import_audio_failed', payload.error);
    });

    // Background transcription (the dialog is usually closed by now)
    register<ImportResult>('import-complete', async (payload) => {
      onTranscribedRef.current?.(payload);
      await Analytics.track('import_audio_completed', {
        success: 'true',
        duration_seconds: payload.duration_seconds.toString(),
        segments_count: payload.segments_count.toString()
      });
    });

    register<ImportFailed>('import-failed', async (payload) => {
      onTranscribeFailedRef.current?.(payload);
      await Analytics.trackError('import_audio_failed', payload.error);
    });

    return () => {
      disposed = true;
      unlisteners.forEach((unlisten) => unlisten());
    };
  }, []);

  // Select file using native file dialog
  const selectFile = useCallback(async (): Promise<AudioFileInfo | null> => {
    setStatus('validating');
    setError(null);

    try {
      const result = await invoke<AudioFileInfo | null>('select_and_validate_audio_command');
      if (result) {
        setFileInfo(result);
        setStatus('idle');
        return result;
      } else {
        // User cancelled
        setStatus('idle');
        return null;
      }
    } catch (err: any) {
      setStatus('error');
      const errorMsg = typeof err === 'string' ? err : (err?.message || String(err) || t('importAudio.errors.validateFailed'));
      setError(errorMsg);
      onErrorRef.current?.(errorMsg);
      return null;
    }
  }, []);

  // Validate a file from a given path (for drag-drop)
  const validateFile = useCallback(async (path: string): Promise<AudioFileInfo | null> => {
    setStatus('validating');
    setError(null);

    try {
      const result = await invoke<AudioFileInfo>('validate_audio_file_command', { path });
      setFileInfo(result);
      setStatus('idle');
      return result;
    } catch (err: any) {
      setStatus('error');
      const errorMsg = typeof err === 'string' ? err : (err?.message || String(err) || t('importAudio.errors.validateFailed'));
      setError(errorMsg);
      onErrorRef.current?.(errorMsg);
      return null;
    }
  }, []);

  // Start the import process
  const startImport = useCallback(
    async (
      sourcePath: string,
      title: string,
      language?: string | null,
      model?: string | null,
      provider?: string | null
    ) => {
      isCancelledRef.current = false;
      setStatus('uploading');
      setError(null);
      setProgress(null);

      try {
        if (fileInfo) {
          await Analytics.track('import_audio_started', {
            file_size_bytes: fileInfo.size_bytes.toString(),
            duration_seconds: fileInfo.duration_seconds.toString(),
            language: language || 'auto',
            model_provider: provider || '',
            model_name: model || ''
          });
        }

        await invoke('start_import_audio_command', {
          sourcePath,
          title,
          language: language || null,
          model: model || null,
          provider: provider || null,
        });
      } catch (err: any) {
        setStatus('error');
        const errorMsg = typeof err === 'string' ? err : (err?.message || String(err) || t('importAudio.errors.startFailed'));
        setError(errorMsg);

        await Analytics.trackError('import_audio_failed', errorMsg);

        onErrorRef.current?.(errorMsg);
      }
    },
    [fileInfo]
  );

  // Cancel ongoing import
  const cancelImport = useCallback(async () => {
    isCancelledRef.current = true;
    try {
      await invoke('cancel_import_command');
      setStatus('idle');
      setProgress(null);
    } catch (err: any) {
      console.error('Failed to cancel import:', err);
    }
  }, []);

  // Reset all state
  const reset = useCallback(() => {
    isCancelledRef.current = false;
    setStatus('idle');
    setFileInfo(null);
    setProgress(null);
    setError(null);
  }, []);

  return {
    status,
    fileInfo,
    progress,
    error,
    isProcessing: status === 'uploading',
    isBusy: status === 'uploading' || status === 'validating',
    selectFile,
    validateFile,
    startImport,
    cancelImport,
    reset,
  };
}
