import { useState, useEffect, useCallback, useRef } from 'react';
import { useTranscripts } from '@/contexts/TranscriptContext';
import { useSidebar } from '@/components/sidebar/SidebarProvider';
import { useConfig } from '@/contexts/ConfigContext';
import { useRecordingState, RecordingStatus } from '@/contexts/RecordingStateContext';
import { recordingService } from '@/services/recordingService';
import Analytics from '@/lib/analytics';
import { showRecordingNotification } from '@/lib/recordingNotification';
import { describeServerProblem, getServerStatus } from '@/lib/server';
import { toast } from 'sonner';
import { t } from '@/i18n';
import { MEETING_TITLE_OVERRIDE_KEY } from '@/hooks/useRecordingStop';

const TRANSCRIPTION_RUNTIME_START_ERROR_CODE = 'TRANSCRIPTION_RUNTIME_INITIALIZATION_FAILED';

const isTranscriptionRuntimeStartError = (error: unknown) =>
  String(error) === TRANSCRIPTION_RUNTIME_START_ERROR_CODE;

interface UseRecordingStartReturn {
  handleRecordingStart: () => Promise<void>;
  isAutoStarting: boolean;
}

/**
 * Custom hook for managing recording start lifecycle.
 * Handles both manual start (button click) and auto-start (from sidebar navigation).
 *
 * Features:
 * - Meeting title generation (format: Meeting DD_MM_YY_HH_MM_SS)
 * - Transcript clearing on start
 * - Analytics tracking
 * - Recording notification display
 * - Auto-start from sidebar via sessionStorage flag
 */
export function useRecordingStart(
  isRecording: boolean,
  setIsRecording: (value: boolean) => void,
  showModal?: (name: 'modelSelector', message?: string) => void
): UseRecordingStartReturn {
  const [isAutoStarting, setIsAutoStarting] = useState(false);

  // Synchronous latch: a rapid double-click re-enters handleRecordingStart
  // before any state update lands, so an async/state guard can't stop it.
  const isStartingRef = useRef(false);

  const { clearTranscripts, setMeetingTitle } = useTranscripts();
  const { setIsMeetingActive } = useSidebar();
  const { selectedDevices } = useConfig();
  const { setStatus } = useRecordingState();

  // Generate meeting title with timestamp
  const generateMeetingTitle = useCallback(() => {
    const now = new Date();
    const day = String(now.getDate()).padStart(2, '0');
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const year = String(now.getFullYear()).slice(-2);
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    // A new meeting starts: drop any name the user typed for the previous one.
    try {
      sessionStorage.removeItem(MEETING_TITLE_OVERRIDE_KEY);
    } catch {
      /* storage unavailable */
    }
    return t('recording.meetingTitle.generated', { date: `${day}_${month}_${year}_${hours}_${minutes}_${seconds}` });
  }, []);

  /**
   * Recording needs a reachable, authenticated server with a ready STT model.
   * Returns true when recording may start; otherwise informs the user and returns false.
   */
  const checkServerReady = useCallback(async (source: string): Promise<boolean> => {
    let problem: string | null;
    try {
      const status = await getServerStatus();
      problem = describeServerProblem(status, 'stt');
    } catch (error) {
      console.error('Failed to get server status:', error);
      problem = t('recording.errors.serverStatusFailed');
    }
    if (!problem) return true;

    toast.error(t('recording.errors.startFailed'), {
      description: problem,
    });
    showModal?.('modelSelector', problem);
    Analytics.trackButtonClick('start_recording_blocked_server', source);
    return false;
  }, [showModal]);

  // Handle manual recording start (from button click)
  const handleRecordingStart = useCallback(async () => {
    if (isStartingRef.current) {
      console.log('handleRecordingStart ignored - start already in progress');
      return;
    }
    isStartingRef.current = true;
    try {
      console.log('handleRecordingStart called - checking server status');

      // Recording requires a connected server with a ready STT model.
      if (!(await checkServerReady('home_page'))) {
        setStatus(RecordingStatus.IDLE);
        return;
      }

      console.log('Server ready - setting up meeting title and state');

      const randomTitle = generateMeetingTitle();
      setMeetingTitle(randomTitle);

      // Set STARTING status before initiating backend recording
      setStatus(RecordingStatus.STARTING, t('recording.status.initializing'));

      // Start the actual backend recording
      console.log('Starting backend recording with meeting:', randomTitle);
      await recordingService.startRecordingWithDevices(
        selectedDevices?.micDevice || null,
        selectedDevices?.systemDevice || null,
        randomTitle
      );
      console.log('Backend recording started successfully');

      // Update state after successful backend start
      // Note: RECORDING status will be set by RecordingStateContext event listener
      console.log('Setting isRecordingState to true');
      setIsRecording(true); // This will also update the sidebar via the useEffect
      clearTranscripts(); // Clear previous transcripts when starting new recording
      setIsMeetingActive(true);
      Analytics.trackButtonClick('start_recording', 'home_page');

      // Show recording notification if enabled
      await showRecordingNotification();
    } catch (error) {
      console.error('Failed to start recording:', error);
      const errorMsg = error instanceof Error ? error.message : String(error);

      // A racing second start that lost to a live recording must not clobber
      // the running recording's state. The winning start is live, so reflect
      // RECORDING here — leaving STARTING latched would keep the Stop button
      // disabled forever, since it's gated on isStartingRecording.
      if (errorMsg.includes('already in progress')) {
        console.warn('Start rejected because recording is already active - leaving live recording state untouched');
        setStatus(RecordingStatus.RECORDING);
        Analytics.trackButtonClick('start_recording_error', 'home_page');
        return;
      }

      const isRuntimeError = isTranscriptionRuntimeStartError(error);
      if (errorMsg.includes('Recording start timed out')) {
        toast.error(t('recording.errors.startTimedOut'));
      }

      setStatus(RecordingStatus.ERROR, isRuntimeError
        ? t('recording.errors.runtimeInit')
        : errorMsg);
      setIsRecording(false); // Reset state on error
      Analytics.trackButtonClick('start_recording_error', 'home_page');
      if (isRuntimeError) return;
      // Re-throw so RecordingControls can handle device-specific errors
      throw error;
    } finally {
      isStartingRef.current = false;
    }
  }, [generateMeetingTitle, setMeetingTitle, setIsRecording, clearTranscripts, setIsMeetingActive, checkServerReady, selectedDevices, setStatus]);

  // Check for autoStartRecording flag and start recording automatically
  useEffect(() => {
    const checkAutoStartRecording = async () => {
      if (typeof window !== 'undefined') {
        const shouldAutoStart = sessionStorage.getItem('autoStartRecording');
        if (shouldAutoStart === 'true' && !isRecording && !isAutoStarting) {
          console.log('Auto-starting recording from navigation...');
          setIsAutoStarting(true);
          sessionStorage.removeItem('autoStartRecording'); // Clear the flag

          // Recording requires a connected server with a ready STT model.
          if (!(await checkServerReady('sidebar_auto'))) {
            setStatus(RecordingStatus.IDLE);
            setIsAutoStarting(false);
            return;
          }

          // Start the actual backend recording
          try {
            // Generate meeting title
            const generatedMeetingTitle = generateMeetingTitle();

            // Set STARTING status before initiating backend recording
            setStatus(RecordingStatus.STARTING, t('recording.status.initializing'));

            console.log('Auto-starting backend recording with meeting:', generatedMeetingTitle);
            const result = await recordingService.startRecordingWithDevices(
              selectedDevices?.micDevice || null,
              selectedDevices?.systemDevice || null,
              generatedMeetingTitle
            );
            console.log('Auto-start backend recording result:', result);

            // Update UI state after successful backend start
            // Note: RECORDING status will be set by RecordingStateContext event listener
            setMeetingTitle(generatedMeetingTitle);
            setIsRecording(true);
            clearTranscripts();
            setIsMeetingActive(true);
            Analytics.trackButtonClick('start_recording', 'sidebar_auto');

            // Show recording notification if enabled
            await showRecordingNotification();
          } catch (error) {
            console.error('Failed to auto-start recording:', error);
            const errorMsg = error instanceof Error ? error.message : String(error);
            if (errorMsg.includes('already in progress')) {
              // Benign race — another start won and is live; skip ERROR/alert.
              setStatus(RecordingStatus.RECORDING);
            } else {
              const isRuntimeError = isTranscriptionRuntimeStartError(error);
              setStatus(RecordingStatus.ERROR, isRuntimeError
                ? t('recording.errors.runtimeInit')
                : errorMsg);
              if (!isRuntimeError) {
                toast.error(t('recording.errors.startFailed'), { description: errorMsg });
              }
            }
            Analytics.trackButtonClick('start_recording_error', 'sidebar_auto');
          } finally {
            setIsAutoStarting(false);
          }
        }
      }
    };

    checkAutoStartRecording();
  }, [
    isRecording,
    isAutoStarting,
    selectedDevices,
    generateMeetingTitle,
    setMeetingTitle,
    setIsRecording,
    clearTranscripts,
    setIsMeetingActive,
    checkServerReady,
    setStatus,
  ]);

  // Listen for direct recording trigger from sidebar when already on home page
  useEffect(() => {
    const handleDirectStart = async () => {
      if (isRecording || isAutoStarting) {
        console.log('Recording already in progress, ignoring direct start event');
        return;
      }

      console.log('Direct start from sidebar - checking server status');
      setIsAutoStarting(true);

      // Recording requires a connected server with a ready STT model.
      if (!(await checkServerReady('sidebar_direct'))) {
        setStatus(RecordingStatus.IDLE);
        setIsAutoStarting(false);
        return;
      }

      try {
        // Generate meeting title
        const generatedMeetingTitle = generateMeetingTitle();

        // Set STARTING status before initiating backend recording
        setStatus(RecordingStatus.STARTING, t('recording.status.initializing'));

        console.log('Starting backend recording with meeting:', generatedMeetingTitle);
        const result = await recordingService.startRecordingWithDevices(
          selectedDevices?.micDevice || null,
          selectedDevices?.systemDevice || null,
          generatedMeetingTitle
        );
        console.log('Backend recording result:', result);

        // Update UI state after successful backend start
        // Note: RECORDING status will be set by RecordingStateContext event listener
        setMeetingTitle(generatedMeetingTitle);
        setIsRecording(true);
        clearTranscripts();
        setIsMeetingActive(true);
        Analytics.trackButtonClick('start_recording', 'sidebar_direct');

        // Show recording notification if enabled
        await showRecordingNotification();
      } catch (error) {
        console.error('Failed to start recording from sidebar:', error);
        const errorMsg = error instanceof Error ? error.message : String(error);
        if (errorMsg.includes('already in progress')) {
          // Benign race — another start won and is live; skip ERROR/alert.
          setStatus(RecordingStatus.RECORDING);
        } else {
          const isRuntimeError = isTranscriptionRuntimeStartError(error);
          setStatus(RecordingStatus.ERROR, isRuntimeError
            ? t('recording.errors.runtimeInit')
            : errorMsg);
          if (!isRuntimeError) {
            toast.error(t('recording.errors.startFailed'), { description: errorMsg });
          }
        }
        Analytics.trackButtonClick('start_recording_error', 'sidebar_direct');
      } finally {
        setIsAutoStarting(false);
      }
    };

    window.addEventListener('start-recording-from-sidebar', handleDirectStart);

    return () => {
      window.removeEventListener('start-recording-from-sidebar', handleDirectStart);
    };
  }, [
    isRecording,
    isAutoStarting,
    selectedDevices,
    generateMeetingTitle,
    setMeetingTitle,
    setIsRecording,
    clearTranscripts,
    setIsMeetingActive,
    checkServerReady,
    setStatus,
  ]);

  return {
    handleRecordingStart,
    isAutoStarting,
  };
}
