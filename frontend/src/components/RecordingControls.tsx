'use client';

import { invoke } from '@tauri-apps/api/core';
import { appDataDir } from '@tauri-apps/api/path';
import { useCallback, useEffect, useState, useRef } from 'react';
import { Play, Pause, Square, Mic, AlertCircle, X, Loader2 } from 'lucide-react';
import { ProcessRequest, SummaryResponse } from '@/types/summary';
import { listen } from '@tauri-apps/api/event';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import Analytics from '@/lib/analytics';
import { useRecordingState } from '@/contexts/RecordingStateContext';
import type { TranscriptionErrorPayload } from '@/services/transcriptService';
import { toast } from 'sonner';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { LiveWaveform } from './AudioLevelMeter';

interface RecordingControlsProps {
  isRecording: boolean;
  barHeights: string[];
  onRecordingStop: (callApi?: boolean) => void;
  onRecordingStart: () => void;
  onTranscriptReceived: (summary: SummaryResponse) => void;
  onTranscriptionError?: (message: string) => void;
  onStopInitiated?: () => void; // Called immediately when stop button is clicked
  isRecordingDisabled: boolean;
  isParentProcessing: boolean;
  selectedDevices?: {
    micDevice: string | null;
    systemDevice: string | null;
  };
  meetingName?: string;
}

export const RecordingControls: React.FC<RecordingControlsProps> = ({
  isRecording,
  barHeights,
  onRecordingStop,
  onRecordingStart,
  onTranscriptReceived,
  onTranscriptionError,
  onStopInitiated,
  isRecordingDisabled,
  isParentProcessing,
  selectedDevices,
  meetingName,
}) => {
  // Use global recording state context for pause state (syncs with tray operations)
  const t = useT();
  const recordingState = useRecordingState();
  const isPaused = recordingState.isPaused;
  const isStartingRecording = recordingState.isStartingRecording;

  const [showPlayback, setShowPlayback] = useState(false);
  const [recordingPath, setRecordingPath] = useState<string | null>(null);
  const [transcript, setTranscript] = useState<string>('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [isStarting, setIsStarting] = useState(false);
  const [isStopping, setIsStopping] = useState(false);
  const [isPausing, setIsPausing] = useState(false);
  const [isResuming, setIsResuming] = useState(false);
  const MIN_RECORDING_DURATION = 2000; // 2 seconds minimum recording time
  const [transcriptionErrors, setTranscriptionErrors] = useState(0);
  const [isValidatingModel, setIsValidatingModel] = useState(false);
  const [speechDetected, setSpeechDetected] = useState(false);
  const [deviceError, setDeviceError] = useState<{ title: string, message: string } | null>(null);

  useEffect(() => {
    const checkTauri = async () => {
      try {
        const result = await invoke('is_recording');
        console.log('Tauri is initialized and ready, is_recording result:', result);
      } catch (error) {
        console.error('Tauri initialization error:', error);
        toast.error(t('recording.errors.initFailed'));
      }
    };
    checkTauri();
  }, []);

  const handleStartRecording = useCallback(async () => {
    if (isStarting || isValidatingModel || isStartingRecording) return;
    console.log('Starting recording...');
    console.log('Selected devices:', selectedDevices);
    console.log('Meeting name:', meetingName);
    console.log('Current isRecording state:', isRecording);

    setShowPlayback(false);
    setTranscript(''); // Clear any previous transcript
    setSpeechDetected(false); // Reset speech detection on new recording

    try {
      // Call the validation callback which will:
      // 1. Check if model is ready
      // 2. Show appropriate toast/modal
      // 3. Call backend if valid
      // 4. Update UI state
      await onRecordingStart();
    } catch (error) {
      console.error('Failed to start recording:', error);
      console.error('Error details:', {
        message: error instanceof Error ? error.message : String(error),
        name: error instanceof Error ? error.name : 'Unknown',
        stack: error instanceof Error ? error.stack : undefined
      });

      // Parse error message to provide user-friendly feedback
      const errorMsg = error instanceof Error ? error.message : String(error);

      // Check for device-related errors
      if (errorMsg.includes('microphone') || errorMsg.includes('mic') || errorMsg.includes('input')) {
        setDeviceError({
          title: t('recording.deviceErrors.micTitle'),
          message: t('recording.deviceErrors.micBody')
        });
      } else if (errorMsg.includes('system audio') || errorMsg.includes('speaker') || errorMsg.includes('output')) {
        setDeviceError({
          title: t('recording.deviceErrors.systemTitle'),
          message: t('recording.deviceErrors.systemBody')
        });
      } else if (errorMsg.includes('permission')) {
        setDeviceError({
          title: t('recording.deviceErrors.permissionTitle'),
          message: t('recording.deviceErrors.permissionBody')
        });
      } else {
        setDeviceError({
          title: t('recording.deviceErrors.genericTitle'),
          message: t('recording.deviceErrors.genericBody')
        });
      }
    }
  }, [onRecordingStart, isStarting, isValidatingModel, isStartingRecording, selectedDevices, meetingName, isRecording, t]);

  const stopRecordingAction = useCallback(async () => {
    console.log('Executing stop recording...');
    try {
      setIsProcessing(true);
      const dataDir = await appDataDir();
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const savePath = `${dataDir}/recording-${timestamp}.wav`;
      console.log('Saving recording to:', savePath);
      console.log('About to call stop_recording command');
      const result = await invoke('stop_recording', {
        args: {
          save_path: savePath
        }
      });
      console.log('stop_recording command completed successfully:', result);
      setRecordingPath(savePath);
      // setShowPlayback(true);
      setIsProcessing(false);
      // Track successful transcription
      Analytics.trackTranscriptionSuccess();
      onRecordingStop(true);
    } catch (error) {
      console.error('Failed to stop recording:', error);
      if (error instanceof Error) {
        console.error('Error details:', {
          message: error.message,
          name: error.name,
          stack: error.stack,
        });
        if (error.message.includes('No recording in progress')) {
          return;
        }
      } else if (typeof error === 'string' && error.includes('No recording in progress')) {
        return;
      } else if (error && typeof error === 'object' && 'toString' in error) {
        if (error.toString().includes('No recording in progress')) {
          return;
        }
      }
      setIsProcessing(false);
      onRecordingStop(false);
    } finally {
      setIsStopping(false);
    }
  }, [onRecordingStop]);

  const handleStopRecording = useCallback(async () => {
    console.log('handleStopRecording called - isRecording:', isRecording, 'isStarting:', isStarting, 'isStopping:', isStopping, 'isStartingRecording:', isStartingRecording);
    if (!isRecording || isStarting || isStopping || isStartingRecording) {
      console.log('Early return from handleStopRecording due to state check');
      return;
    }

    console.log('Stopping recording...');

    // Notify parent immediately (for UI state updates)
    onStopInitiated?.();

    setIsStopping(true);

    // Immediately trigger the stop action
    await stopRecordingAction();
  }, [isRecording, isStarting, isStopping, isStartingRecording, stopRecordingAction, onStopInitiated]);

  const handlePauseRecording = useCallback(async () => {
    if (!isRecording || isPaused || isPausing) return;

    console.log('Pausing recording...');
    setIsPausing(true);

    try {
      await invoke('pause_recording');
      // isPaused state now managed by RecordingStateContext via events
      console.log('Recording paused successfully');
    } catch (error) {
      console.error('Failed to pause recording:', error);
      toast.error(t('recording.errors.pauseFailed'));
    } finally {
      setIsPausing(false);
    }
  }, [isRecording, isPaused, isPausing, t]);

  const handleResumeRecording = useCallback(async () => {
    if (!isRecording || !isPaused || isResuming) return;

    console.log('Resuming recording...');
    setIsResuming(true);

    try {
      await invoke('resume_recording');
      // isPaused state now managed by RecordingStateContext via events
      console.log('Recording resumed successfully');
    } catch (error) {
      console.error('Failed to resume recording:', error);
      toast.error(t('recording.errors.resumeFailed'));
    } finally {
      setIsResuming(false);
    }
  }, [isRecording, isPaused, isResuming, t]);

  useEffect(() => {
    return () => {
      // Cleanup on unmount if needed
    };
  }, []);

  useEffect(() => {
    console.log('Setting up recording event listeners');
    let unsubscribes: (() => void)[] = [];

    const setupListeners = async () => {
      try {
        // Transcript error listener - handles both regular and actionable errors
        const transcriptErrorUnsubscribe = await listen('transcript-error', (event) => {
          console.log('transcript-error event received:', event);
          console.error('Transcription error received:', event.payload);
          const errorMessage = event.payload as string;

          Analytics.trackTranscriptionError(errorMessage);
          console.log('Tracked transcription error:', errorMessage);

          setTranscriptionErrors(prev => {
            const newCount = prev + 1;
            console.log('Transcription error count incremented:', newCount);
            return newCount;
          });
          setIsProcessing(false);
          console.log('Calling onRecordingStop(false) due to transcript error');
          onRecordingStop(false);
          if (onTranscriptionError) {
            onTranscriptionError(errorMessage);
          }
        });

        // Transcription error listener - handles structured error objects with actionable flag
        const transcriptionErrorUnsubscribe = await listen<TranscriptionErrorPayload>('transcription-error', (event) => {
          console.log('transcription-error event received:', event);
          console.error('Transcription error received:', event.payload);

          const errorMessage = event.payload.userMessage || event.payload.error;

          Analytics.trackTranscriptionError(errorMessage);
          console.log('Tracked transcription error:', errorMessage);

          setTranscriptionErrors(prev => {
            const newCount = prev + 1;
            console.log('Transcription error count incremented:', newCount);
            return newCount;
          });
          setIsProcessing(false);

          if (event.payload.phase === 'active') {
            console.log('Calling onRecordingStop(false) due to active transcription error');
            onRecordingStop(false);
          }

          // For actionable errors (like model loading failures), the main page will handle showing the model selector
          // For regular errors, they are handled by useModalState global listener which shows a toast
        });

        // Pause/Resume events are now handled by RecordingStateContext
        // No need for duplicate listeners here

        // Speech detected listener - for UX feedback when VAD detects speech
        const speechDetectedUnsubscribe = await listen('speech-detected', (event) => {
          console.log('speech-detected event received:', event);
          setSpeechDetected(true);
        });

        unsubscribes = [
          transcriptErrorUnsubscribe,
          transcriptionErrorUnsubscribe,
          speechDetectedUnsubscribe
        ];
        console.log('Recording event listeners set up successfully');
      } catch (error) {
        console.error('Failed to set up recording event listeners:', error);
      }
    };

    setupListeners();

    return () => {
      console.log('Cleaning up recording event listeners');
      unsubscribes.forEach(unsubscribe => {
        if (unsubscribe && typeof unsubscribe === 'function') {
          unsubscribe();
        }
      });
    };
  }, [onRecordingStop, onTranscriptionError]);

  const startBusy = isStarting || isProcessing || isValidatingModel || isStartingRecording;
  const pauseBusy = isPausing || isResuming || isStopping;
  const stopBusy = isStopping || isPausing || isResuming || isStartingRecording;

  return (
    <TooltipProvider>
      <div className="relative flex flex-col items-center">
        {isProcessing && !isParentProcessing ? (
          <div className="flex h-16 items-center gap-2 text-sm text-muted-foreground">
            <Loader2 className="h-5 w-5 animate-spin text-primary" />
            <span>{t('recording.controls.processing')}</span>
          </div>
        ) : !isRecording ? (
          // Idle: one big brand-blue record button
          <Tooltip>
            <TooltipTrigger asChild>
              <button
                type="button"
                onClick={() => {
                  Analytics.trackButtonClick('start_recording', 'recording_controls');
                  handleStartRecording();
                }}
                disabled={startBusy || isRecordingDisabled}
                aria-label={t('recording.controls.start')}
                className={cn(
                  'group relative flex h-16 w-16 items-center justify-center rounded-full text-primary-foreground transition-all',
                  'focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-ring/30',
                  startBusy || isRecordingDisabled
                    ? 'cursor-not-allowed bg-muted-foreground/40'
                    : 'bg-brand-gradient shadow-glow hover:scale-105 hover:brightness-110 active:scale-95',
                )}
              >
                {!(startBusy || isRecordingDisabled) && (
                  <span className="absolute inset-0 rounded-full bg-primary/30 animate-ping [animation-duration:2.4s]" aria-hidden="true" />
                )}
                {isValidatingModel || isStartingRecording ? (
                  <Loader2 className="relative h-6 w-6 animate-spin" />
                ) : (
                  <Mic className="relative h-7 w-7" />
                )}
              </button>
            </TooltipTrigger>
            <TooltipContent>
              <p>{t('recording.controls.start')}</p>
            </TooltipContent>
          </Tooltip>
        ) : (
          // Recording: pause/resume + red stop + live waveform
          <div className="flex items-center gap-4">
            <Tooltip>
              <TooltipTrigger asChild>
                <button
                  type="button"
                  onClick={() => {
                    if (isPaused) {
                      Analytics.trackButtonClick('resume_recording', 'recording_controls');
                      handleResumeRecording();
                    } else {
                      Analytics.trackButtonClick('pause_recording', 'recording_controls');
                      handlePauseRecording();
                    }
                  }}
                  disabled={pauseBusy}
                  aria-label={isPaused ? t('recording.controls.resume') : t('recording.controls.pause')}
                  className={cn(
                    'relative flex h-11 w-11 items-center justify-center rounded-full border transition-colors',
                    'focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-ring/20',
                    pauseBusy
                      ? 'cursor-not-allowed border-border bg-muted text-muted-foreground'
                      : isPaused
                        ? 'border-primary/30 bg-accent text-primary hover:bg-accent/80'
                        : 'border-border bg-card text-foreground hover:bg-muted',
                  )}
                >
                  {isPausing || isResuming ? (
                    <Loader2 className="h-4 w-4 animate-spin" />
                  ) : isPaused ? (
                    <Play className="h-4 w-4 translate-x-px" />
                  ) : (
                    <Pause className="h-4 w-4" />
                  )}
                </button>
              </TooltipTrigger>
              <TooltipContent>
                <p>
                  {isPausing
                    ? t('recording.controls.pausing')
                    : isResuming
                      ? t('recording.controls.resuming')
                      : isPaused
                        ? t('recording.controls.resume')
                        : t('recording.controls.pause')}
                </p>
              </TooltipContent>
            </Tooltip>

            <Tooltip>
              <TooltipTrigger asChild>
                <button
                  type="button"
                  onClick={() => {
                    Analytics.trackButtonClick('stop_recording', 'recording_controls');
                    handleStopRecording();
                  }}
                  disabled={stopBusy}
                  aria-label={t('recording.controls.stop')}
                  className={cn(
                    'relative flex h-16 w-16 items-center justify-center rounded-full text-destructive-foreground transition-all',
                    'focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-destructive/30',
                    stopBusy
                      ? 'cursor-not-allowed bg-muted-foreground/40'
                      : 'bg-destructive shadow-[0_8px_24px_rgba(220,38,38,0.30)] hover:scale-105 active:scale-95',
                  )}
                >
                  {!stopBusy && !isPaused && (
                    <span className="absolute -inset-1.5 rounded-full border-2 border-destructive/30 animate-pulse" aria-hidden="true" />
                  )}
                  {isStopping ? (
                    <Loader2 className="relative h-6 w-6 animate-spin" />
                  ) : (
                    <Square className="relative h-5 w-5 fill-current" />
                  )}
                </button>
              </TooltipTrigger>
              <TooltipContent>
                <p>{isStopping ? t('recording.controls.stopping') : t('recording.controls.stop')}</p>
              </TooltipContent>
            </Tooltip>

            <LiveWaveform barHeights={barHeights} active={isRecording} paused={isPaused} />
          </div>
        )}

        {/* Validation status */}
        {isValidatingModel && (
          <p className="mt-2 text-xs text-muted-foreground">{t('recording.controls.validating')}</p>
        )}

        {/* Device error card, floating above the control dock */}
        {deviceError && (
          <div
            role="alert"
            className="absolute bottom-full left-1/2 z-20 mb-4 w-[min(380px,calc(100vw-2rem))] -translate-x-1/2 rounded-xl border border-destructive/30 bg-card p-4 shadow-elevated"
          >
            <button
              type="button"
              onClick={() => setDeviceError(null)}
              className="absolute right-3 top-3 rounded-md p-1 text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
              aria-label={t('recording.controls.closeAlert')}
            >
              <X className="h-4 w-4" />
            </button>
            <div className="flex gap-3 pr-6">
              <AlertCircle className="mt-0.5 h-5 w-5 shrink-0 text-destructive" />
              <div className="min-w-0">
                <p className="text-sm font-semibold text-foreground">{deviceError.title}</p>
                <div className="mt-1.5 space-y-0.5 text-sm text-muted-foreground">
                  {deviceError.message.split('\n').map((line, i) => (
                    <p key={i} className={i > 0 ? 'pl-1' : ''}>
                      {line}
                    </p>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </TooltipProvider>
  );
};
