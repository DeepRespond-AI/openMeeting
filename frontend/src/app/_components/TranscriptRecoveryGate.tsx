'use client';

import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useRouter } from 'next/navigation';
import { useI18n } from '@/i18n';
import { useSidebar } from '@/components/sidebar/SidebarProvider';
import { useRecordingState, RecordingStatus } from '@/contexts/RecordingStateContext';
import { useTranscriptRecovery } from '@/hooks/useTranscriptRecovery';
import { TranscriptRecovery } from '@/components/transcript-recovery';
import { indexedDBService } from '@/services/indexedDBService';

/**
 * Always-mounted gate that runs the startup transcript-recovery checks and
 * shows the recovery dialog no matter which page is open. Extracted from the
 * old home page so the checks keep running at app launch after recording
 * moved to /record.
 */
export function TranscriptRecoveryGate() {
  const { t } = useI18n();
  const router = useRouter();
  const { refetchMeetings } = useSidebar();
  const recordingState = useRecordingState();
  const { status } = recordingState;

  const [showRecoveryDialog, setShowRecoveryDialog] = useState(false);

  const {
    recoverableMeetings,
    checkForRecoverableTranscripts,
    recoverMeeting,
    loadMeetingTranscripts,
    deleteRecoverableMeeting
  } = useTranscriptRecovery();

  // Startup recovery check
  useEffect(() => {
    const performStartupChecks = async () => {
      try {
        // Skip recovery check if currently recording or processing stop
        if (recordingState.isRecording ||
          status === RecordingStatus.STOPPING ||
          status === RecordingStatus.PROCESSING_TRANSCRIPTS ||
          status === RecordingStatus.SAVING) {
          console.log('Skipping recovery check - recording in progress or processing');
          return;
        }

        // 1. Clean up old meetings (7+ days)
        try {
          await indexedDBService.deleteOldMeetings(7);
        } catch (error) {
          console.warn('⚠️ Failed to clean up old meetings:', error);
        }

        // 2. Clean up saved meetings (24+ hours after save)
        try {
          await indexedDBService.deleteSavedMeetings(24);
        } catch (error) {
          console.warn('⚠️ Failed to clean up saved meetings:', error);
        }

        // 3. Always check for recoverable meetings on startup
        await checkForRecoverableTranscripts();
      } catch (error) {
        console.error('Failed to perform startup checks:', error);
      }
    };

    performStartupChecks();
  }, [checkForRecoverableTranscripts, recordingState.isRecording, status]);

  // Watch for recoverable meetings changes and show dialog once per session
  useEffect(() => {
    if (recoverableMeetings.length > 0) {
      const shownThisSession = sessionStorage.getItem('recovery_dialog_shown');
      if (!shownThisSession) {
        setShowRecoveryDialog(true);
        sessionStorage.setItem('recovery_dialog_shown', 'true');
      }
    }
  }, [recoverableMeetings]);

  // Handle recovery with toast notifications and navigation
  const handleRecovery = async (meetingId: string) => {
    try {
      const result = await recoverMeeting(meetingId);

      if (result.success) {
        toast.success(t('home.recovery.success'), {
          description: result.audioRecoveryStatus?.status === 'success'
            ? t('home.recovery.successWithAudio')
            : t('home.recovery.successNoAudio'),
          action: result.meetingId ? {
            label: t('home.recovery.viewMeeting'),
            onClick: () => {
              router.push(`/meeting-details?id=${result.meetingId}`);
            }
          } : undefined,
        });

        // Refresh the meetings list to show the newly recovered meeting
        await refetchMeetings();

        // If no more recoverable meetings, clear session flag so dialog can show again
        if (recoverableMeetings.length === 0) {
          sessionStorage.removeItem('recovery_dialog_shown');
        }

        // Auto-navigate after a short delay
        if (result.meetingId) {
          setTimeout(() => {
            router.push(`/meeting-details?id=${result.meetingId}`);
          }, 2000);
        }
      }
    } catch (error) {
      toast.error(t('home.recovery.failed'), {
        description: error instanceof Error ? error.message : t('common.status.unknown'),
      });
      throw error;
    }
  };

  // Handle dialog close - clear session flag if no meetings left
  const handleDialogClose = () => {
    setShowRecoveryDialog(false);
    if (recoverableMeetings.length === 0) {
      sessionStorage.removeItem('recovery_dialog_shown');
    }
  };

  return (
    <TranscriptRecovery
      isOpen={showRecoveryDialog}
      onClose={handleDialogClose}
      recoverableMeetings={recoverableMeetings}
      onRecover={handleRecovery}
      onDelete={deleteRecoverableMeeting}
      onLoadPreview={loadMeetingTranscripts}
    />
  );
}
