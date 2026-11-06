import { useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { invoke as invokeTauri } from '@tauri-apps/api/core';
import { toast } from 'sonner';
import Analytics from '@/lib/analytics';
import { CurrentMeeting, useSidebar } from '@/components/sidebar/SidebarProvider';
import { t } from '@/i18n';
import { MEETING_TITLE_MAX, textLength } from '@/lib/field-limits';

interface UseMeetingOperationsProps {
  meeting: any;
  /** Applies a new title locally (page + sidebar) once it has been saved. */
  onTitleChanged?: (title: string) => void;
}

export function useMeetingOperations({
  meeting,
  onTitleChanged,
}: UseMeetingOperationsProps) {
  const router = useRouter();
  const { meetings, setMeetings, setCurrentMeeting } = useSidebar();

  // Open meeting folder in file explorer
  const handleOpenMeetingFolder = useCallback(async () => {
    try {
      await invokeTauri('open_meeting_folder', { meetingId: meeting.id });
    } catch (error) {
      console.error('Failed to open meeting folder:', error);
      toast.error(t('meeting.folder.openFailed'), {
        description: typeof error === 'string' ? error : error instanceof Error ? error.message : undefined,
      });
    }
  }, [meeting.id]);

  // Rename the meeting. Returns true when the new title was saved.
  const handleRenameMeeting = useCallback(async (rawTitle: string): Promise<boolean> => {
    const title = rawTitle.trim();
    if (textLength(title) > MEETING_TITLE_MAX) {
      toast.error(t('common.errors.textTooLong', { max: MEETING_TITLE_MAX }));
      return false;
    }
    if (!title) {
      toast.error(t('meeting.header.titleEmpty'));
      return false;
    }
    try {
      await invokeTauri('api_save_meeting_title', { meetingId: meeting.id, title });
      onTitleChanged?.(title);
      Analytics.trackButtonClick('edit_meeting_title', 'meeting_details');
      toast.success(t('meeting.header.titleSaved'));
      return true;
    } catch (error) {
      console.error('Failed to update meeting title:', error);
      toast.error(t('meeting.header.titleSaveFailed'), {
        description: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }, [meeting.id, onTitleChanged]);

  // Delete the meeting and go back home. Returns true on success.
  const handleDeleteMeeting = useCallback(async (): Promise<boolean> => {
    try {
      await invokeTauri('api_delete_meeting', { meetingId: meeting.id });
      setMeetings(meetings.filter((m: CurrentMeeting) => m.id !== meeting.id));
      Analytics.trackMeetingDeleted(meeting.id);
      toast.success(t('meeting.delete.success'), { description: t('meeting.delete.successDetail') });
      setCurrentMeeting({ id: 'intro-call', title: '+ New Call' });
      router.push('/');
      return true;
    } catch (error) {
      console.error('Failed to delete meeting:', error);
      toast.error(t('meeting.delete.failed'), {
        description: error instanceof Error ? error.message : String(error),
      });
      return false;
    }
  }, [meeting.id, meetings, router, setCurrentMeeting, setMeetings]);

  return {
    handleOpenMeetingFolder,
    handleRenameMeeting,
    handleDeleteMeeting,
  };
}
