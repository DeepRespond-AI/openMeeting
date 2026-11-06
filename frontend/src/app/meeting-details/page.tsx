"use client"
import { useSidebar } from "@/components/sidebar/SidebarProvider";
import { useState, useEffect, useCallback, useRef, Suspense } from "react";
import { MeetingSummary, SummaryProcessResponse, Transcript } from "@/types";
import PageContent from "./page-content";
import RoomRecordingStatus from '@/components/meeting-details/RoomRecordingStatus';
import { useRouter, useSearchParams } from "next/navigation";
import Analytics from "@/lib/analytics";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { AlertCircle, ArrowLeft, Loader2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { t as translate, useT } from "@/i18n";
import { useConfig } from "@/contexts/ConfigContext";
import { usePaginatedTranscripts } from "@/hooks/usePaginatedTranscripts";
import { parseSummaryContent } from "@/lib/summary-content";
import { describeServerProblem, getServerStatus } from "@/lib/server";
import { toast } from "sonner";
import { transcriptEmptyState, type RecordingSnapshot } from '@/lib/meeting-processing';

interface MeetingDetailsResponse {
  can_manage?: boolean;
  id: string;
  title: string;
  created_at: string;
  updated_at: string;
  transcripts: Transcript[];
  folder_path?: string | null;
  has_audio?: boolean;
  audio_duration?: number | null;
}

function LoadingState() {
  const t = useT();
  return (
    <div className="flex h-screen flex-col items-center justify-center gap-3 bg-background text-sm text-muted-foreground">
      <Loader2 className="h-6 w-6 animate-spin text-primary" />
      {t('meeting.page.loading')}
    </div>
  );
}

function MeetingDetailsContent() {
  const searchParams = useSearchParams();
  const meetingId = searchParams.get('id');
  const source = searchParams.get('source'); // Check if navigated from recording
  const { setCurrentMeeting, refetchMeetings } = useSidebar();
  const { isAutoSummary } = useConfig(); // Get auto-summary toggle state
  const router = useRouter();
  const t = useT();
  const [meetingDetails, setMeetingDetails] = useState<MeetingDetailsResponse | null>(null);
  const [summaryResponse, setSummaryResponse] = useState<SummaryProcessResponse | null>(null);
  const [meetingSummary, setMeetingSummary] = useState<MeetingSummary | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [shouldAutoGenerate, setShouldAutoGenerate] = useState<boolean>(false);
  const [hasCheckedAutoGen, setHasCheckedAutoGen] = useState<boolean>(false);
  const selectedMeeting = useRef({ id: meetingId });
  if (selectedMeeting.current.id !== meetingId) selectedMeeting.current = { id: meetingId };
  const recordingRefreshVersion = useRef(0);
  const [recordingSnapshot, setRecordingSnapshot] = useState<(RecordingSnapshot & { meetingId: string }) | null>(null);
  const [refreshingMeeting, setRefreshingMeeting] = useState<string | null>(null);

  // Use pagination hook for efficient transcript loading
  const {
    metadata,
    segments,
    transcripts,
    isLoading: isLoadingTranscripts,
    isLoadingMore,
    hasMore,
    totalCount,
    loadedCount,
    loadMore,
    refetch,
    error: transcriptError,
  } = usePaginatedTranscripts({ meetingId: meetingId || '' });

  // A meeting that was just recorded may still be syncing in the background (remaining
  // speech segments, recording upload), and an imported file may still be transcribing on
  // the server. null = unknown yet. When the sync finishes, reload
  // the transcripts so the last sentences show up; the automatic summary waits for it.
  const [syncPending, setSyncPending] = useState<boolean | null>(null);
  useEffect(() => {
    setSyncPending(null);
    if (!meetingId || meetingId === 'intro-call') return;
    let disposed = false;
    let unlisten: (() => void) | undefined;
    listen<{ meetingId: string }>('meeting-sync-finished', (event) => {
      if (disposed || event.payload.meetingId !== meetingId) return;
      setSyncPending(false);
      void refetch();
    }).then((fn) => {
      if (disposed) fn();
      else unlisten = fn;
    });
    invoke<boolean>('recording_sync_pending', { meetingId })
      .then((pending) => { if (!disposed) setSyncPending(pending === true); })
      .catch(() => { if (!disposed) setSyncPending(false); });
    return () => {
      disposed = true;
      unlisten?.();
    };
  }, [meetingId, refetch]);

  const refreshRecording = useCallback(async () => {
    if (!meetingId) return;
    const selection = selectedMeeting.current;
    const version = ++recordingRefreshVersion.current;
    const isCurrent = () => selectedMeeting.current === selection && recordingRefreshVersion.current === version;
    setRefreshingMeeting(meetingId);
    try {
      await Promise.all([
        refetch(),
        invoke<SummaryProcessResponse>('api_get_summary', { meetingId }).then(response => {
          if (!isCurrent()) return;
          setSummaryResponse(response);
          setMeetingSummary(parseSummaryContent(response.data));
        }).catch(() => {}),
      ]);
    } finally {
      if (isCurrent()) setRefreshingMeeting(null);
    }
  }, [meetingId, refetch]);

  const emptyState = transcriptEmptyState(
    recordingSnapshot?.meetingId === meetingId ? recordingSnapshot : null,
    syncPending,
    refreshingMeeting === meetingId || isLoadingTranscripts,
  );

  // Set up auto-generation. The server picks the LLM; we only check that it is ready.
  const setupAutoGeneration = useCallback(async () => {
    if (hasCheckedAutoGen) return; // Only check once

    // Only auto-generate if navigated from recording
    if (source !== 'recording') {
      console.log('Not from recording navigation, skipping auto-generation');
      setHasCheckedAutoGen(true);
      return;
    }

    // Respect user's auto-summary toggle preference
    if (!isAutoSummary) {
      console.log('Auto-summary is disabled in settings');
      setHasCheckedAutoGen(true);
      return;
    }

    try {
      const status = await getServerStatus();
      const problem = describeServerProblem(status, 'llm');
      if (problem) {
        console.log('Skipping auto-summary:', problem);
        toast.info(translate('meeting.autoSummary.skipped'), { description: problem });
      } else {
        setShouldAutoGenerate(true);
      }
    } catch (error) {
      console.error('❌ Failed to check server LLM status:', error);
    }

    setHasCheckedAutoGen(true);
  }, [hasCheckedAutoGen, source, isAutoSummary]);

  // Sync meeting metadata from pagination hook to meeting details state
  useEffect(() => {
    if (isLoadingTranscripts || !meetingId || meetingId === 'intro-call' || metadata?.id !== meetingId) {
      // Keep the current view until the selected meeting's first transcript page is ready.
      return;
    }

    if (metadata) {
      console.log('Meeting metadata loaded:', metadata);

      // Build meeting details from metadata and paginated transcripts
      setMeetingDetails({
        can_manage: metadata.can_manage,
        id: metadata.id,
        title: metadata.title,
        created_at: metadata.created_at,
        updated_at: metadata.updated_at,
        transcripts: transcripts, // Paginated transcripts from hook
        folder_path: metadata.folder_path ?? null, // Local copy (null for server meetings)
        has_audio: metadata.has_audio ?? !!metadata.folder_path,
        audio_duration: metadata.audio_duration ?? null,
      });

      // Sync with sidebar context
      setCurrentMeeting({ id: metadata.id, title: metadata.title });
    }
  }, [metadata, transcripts, meetingId, isLoadingTranscripts, setCurrentMeeting]);

  // Handle transcript loading errors
  useEffect(() => {
    if (transcriptError) {
      console.error('Error loading transcripts:', transcriptError);
      setError(transcriptError);
    }
  }, [transcriptError]);

  // Extract fetchMeetingDetails for use in child components (now refetches via hook)
  const fetchMeetingDetails = useCallback(async () => {
    if (!meetingId || meetingId === 'intro-call') {
      return;
    }

    // The usePaginatedTranscripts hook automatically refetches when meetingId changes
    // This function is kept for compatibility with onMeetingUpdated callback
    console.log('fetchMeetingDetails called - pagination hook will handle refetch');
  }, [meetingId]);

  // Reset states when meetingId changes (prevent race conditions)
  useEffect(() => {
    setMeetingDetails(null);
    setMeetingSummary(null);
    setSummaryResponse(null);
    setError(null);
    setIsLoading(true);
    // Reset auto-generation state to allow new meeting to be checked
    setHasCheckedAutoGen(false);
    setShouldAutoGenerate(false);
  }, [meetingId]);

  useEffect(() => {
    console.log('MeetingDetails useEffect triggered - meetingId:', meetingId);

    if (!meetingId || meetingId === 'intro-call') {
      console.warn('No valid meeting ID in URL - meetingId:', meetingId);
      setError(translate('meeting.page.notSelected'));
      setIsLoading(false);
      Analytics.trackPageView('meeting_details');
      return;
    }

    console.log('Valid meeting ID found, fetching details for:', meetingId);

    setMeetingDetails(null);
    setMeetingSummary(null);
    setSummaryResponse(null);
    setError(null);
    setIsLoading(true);

    let cancelled = false;
    const fetchMeetingSummary = async () => {
      try {
        const response = await invoke<SummaryProcessResponse>('api_get_summary', {
          meetingId,
        });
        if (cancelled) return;
        setSummaryResponse(response);
        const summary = parseSummaryContent(response.data);
        setMeetingSummary(response.status === 'idle' ? null : summary);
      } catch (error) {
        if (cancelled) return;
        console.error('FETCH SUMMARY: Error fetching meeting summary:', error);
        setMeetingSummary(null);
      }
    };

    const loadData = async () => {
      try {
        await fetchMeetingSummary();
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    };

    loadData();
    return () => { cancelled = true; };
  }, [meetingId]);

  // Auto-generation check: runs when meeting is loaded with no summary
  useEffect(() => {
    const checkAutoGen = async () => {
      // Only auto-generate if:
      // 1. We have meeting details
      // 2. No summary exists
      // 3. Meeting has transcripts
      // 4. Haven't checked yet
      if (
        meetingDetails && meetingDetails.can_manage !== false &&
        !isLoading &&
        emptyState === 'empty' &&
        summaryResponse?.status === 'idle' &&
        meetingSummary === null &&
        meetingDetails.transcripts &&
        meetingDetails.transcripts.length > 0 &&
        !hasCheckedAutoGen
      ) {
        console.log('No summary found, checking for auto-generation...');
        await setupAutoGeneration();
      }
    };

    checkAutoGen();
  }, [meetingDetails, meetingSummary, summaryResponse, isLoading, emptyState, hasCheckedAutoGen, setupAutoGeneration]);

  if (error) {
    return (
      <div className="flex h-screen items-center justify-center bg-background p-6">
        <div className="flex max-w-sm flex-col items-center rounded-xl border border-border bg-card p-8 text-center shadow-card">
          <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-destructive/10 text-destructive">
            <AlertCircle className="h-6 w-6" />
          </div>
          <h2 className="text-base font-semibold text-foreground">{t('meeting.page.errorTitle')}</h2>
          <p className="mt-1.5 text-sm text-muted-foreground">{error}</p>
          <Button className="mt-6 rounded-lg" onClick={() => router.push('/')}>
            <ArrowLeft className="h-4 w-4" />
            {t('meeting.page.backHome')}
          </Button>
        </div>
      </div>
    );
  }

  // Show loading spinner while initial data loads
  if (isLoading || !meetingDetails || meetingDetails.id !== meetingId) {
    return <LoadingState />;
  }

  return <div className="flex h-screen min-h-0 flex-col"><RoomRecordingStatus key={meetingId} readOnly={meetingDetails.can_manage === false} meetingId={meetingId!}
    onStatusChange={snapshot => setRecordingSnapshot({ ...snapshot, meetingId: meetingId! })}
    onComplete={() => void refreshRecording()} /><PageContent
    key={meetingId}
    initialSummary={summaryResponse}
    meeting={meetingDetails}
    summaryData={meetingSummary}
    shouldAutoGenerate={shouldAutoGenerate}
    onAutoGenerateComplete={() => setShouldAutoGenerate(false)}
    onMeetingUpdated={async () => {
      // Refetch meeting details to get updated title from backend
      await fetchMeetingDetails();
      // Refetch meetings list to update sidebar
      await refetchMeetings();
    }}
    onRefetchTranscripts={refetch}
    isSyncing={syncPending === true}
    transcriptState={emptyState}
    // Pagination props for efficient transcript loading
    segments={segments}
    hasMore={hasMore}
    isLoadingMore={isLoadingMore}
    totalCount={totalCount}
    loadedCount={loadedCount}
    onLoadMore={loadMore}
  /></div>;
}

export default function MeetingDetails() {
  return (
    <Suspense fallback={<LoadingState />}>
      <MeetingDetailsContent />
    </Suspense>
  );
}
