"use client";
import { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { MeetingSummary, SummaryProcessResponse } from '@/types';
import Analytics from '@/lib/analytics';
import { TranscriptPanel } from '@/components/meeting-details/TranscriptPanel';
import { SummaryPanel } from '@/components/meeting-details/SummaryPanel';
import { MeetingDetailsTabs, type MeetingDetailsTab } from '@/components/meeting-details/MeetingDetailsTabs';
import { MeetingHeader } from '@/components/meeting-details/MeetingHeader';
import { MeetingAudioPlayer } from '@/components/meeting-details/MeetingAudioPlayer';
import { MeetingAudioProvider } from '@/components/meeting-details/MeetingAudioContext';
import type { TranscriptEmptyState } from '@/lib/meeting-processing';

// Custom hooks
import { useMeetingData } from '@/hooks/meeting-details/useMeetingData';
import { useSummaryGeneration } from '@/hooks/meeting-details/useSummaryGeneration';
import { useCopyOperations } from '@/hooks/meeting-details/useCopyOperations';
import { useMeetingOperations } from '@/hooks/meeting-details/useMeetingOperations';
import { useOptionalServer } from '@/contexts/ServerContext';

export default function PageContent({
  meeting,
  summaryData,
  initialSummary,
  shouldAutoGenerate = false,
  onAutoGenerateComplete,
  onMeetingUpdated,
  onRefetchTranscripts,
  isSyncing = false,
  transcriptState,
  // Pagination props for efficient transcript loading
  segments,
  hasMore,
  isLoadingMore,
  totalCount,
  loadedCount,
  onLoadMore,
}: {
  meeting: any;
  summaryData: MeetingSummary | null;
  initialSummary: SummaryProcessResponse | null;
  shouldAutoGenerate?: boolean;
  onAutoGenerateComplete?: () => void;
  onMeetingUpdated?: () => Promise<void>;
  onRefetchTranscripts?: () => Promise<void>;
  /** Background work for this meeting is still running (see `recording_sync_pending`). */
  isSyncing?: boolean;
  transcriptState?: TranscriptEmptyState;
  // Pagination props
  segments?: any[];
  hasMore?: boolean;
  isLoadingMore?: boolean;
  totalCount?: number;
  loadedCount?: number;
  onLoadMore?: () => void;
}) {
  console.log('📄 PAGE CONTENT: Initializing with data:', {
    meetingId: meeting.id,
    summaryDataKeys: summaryData ? Object.keys(summaryData) : null,
    transcriptsCount: meeting.transcripts?.length
  });

  // State
  const [customPrompt, setCustomPrompt] = useState<string>('');
  const isRecording = false;
  const [activeTab, setActiveTab] = useState<MeetingDetailsTab>('info');

  const autoSwitchedSummaryMeetingIdsRef = useRef(new Set<string>());
  const manuallySelectedTabMeetingIdsRef = useRef(new Set<string>());
  const autoGenerationStartedMeetingIdRef = useRef<string | null>(null);

  // Server LLM capability (the server picks the summary model)
  const server = useOptionalServer();
  const llm = server?.capabilities?.llm ?? null;

  // Custom hooks
  const meetingData = useMeetingData({ meeting, summaryData, onMeetingUpdated });

  const summaryGeneration = useSummaryGeneration({
    initialSummary,
    meeting,
    transcripts: meetingData.transcripts,
    llm,
    onMeetingUpdated,
    updateMeetingTitle: meetingData.updateMeetingTitle,
    setAiSummary: meetingData.setAiSummary,
  });

  const copyOperations = useCopyOperations({
    meeting,
    transcripts: meetingData.transcripts,
    meetingTitle: meetingData.meetingTitle,
    aiSummary: meetingData.aiSummary,
    blockNoteSummaryRef: meetingData.blockNoteSummaryRef,
  });

  const meetingOperations = useMeetingOperations({
    meeting,
    onTitleChanged: meetingData.updateMeetingTitle,
  });

  // Track page view
  useEffect(() => {
    Analytics.trackPageView('meeting_details');
  }, []);

  useEffect(() => {
    if (
      // A summary exists, or one is being generated (e.g. automatically after recording):
      // show the summary tab so its progress is visible.
      (meetingData.aiSummary || summaryGeneration.summaryStatus !== 'idle')
      && !autoSwitchedSummaryMeetingIdsRef.current.has(meeting.id)
      && !manuallySelectedTabMeetingIdsRef.current.has(meeting.id)
    ) {
      autoSwitchedSummaryMeetingIdsRef.current.add(meeting.id);
      setActiveTab('summary');
    }
  }, [meeting.id, meetingData.aiSummary, summaryGeneration.summaryStatus]);

  // Auto-generate once the meeting transcripts are loaded.
  useEffect(() => {
    if (
      !shouldAutoGenerate
      || meeting.can_manage === false
      || summaryGeneration.summaryStatus !== 'idle'
      || meetingData.transcripts.length === 0
      || autoGenerationStartedMeetingIdRef.current === meeting.id
    ) {
      return;
    }

    autoGenerationStartedMeetingIdRef.current = meeting.id;
    console.log('🤖 Auto-generating summary with the server LLM...');
    onAutoGenerateComplete?.();
    void summaryGeneration.handleGenerateSummary('');
  }, [
    shouldAutoGenerate,
    meeting.id,
    meetingData.transcripts.length,
    summaryGeneration.handleGenerateSummary,
    summaryGeneration.summaryStatus,
    onAutoGenerateComplete,
  ]);

  const hasRecording = !!meeting.id && (!!meeting.has_audio || !!meeting.folder_path);
  const segmentCount = totalCount ?? meetingData.transcripts.length;

  return (
    <MeetingAudioProvider>
      <motion.div
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.25, ease: 'easeOut' }}
        className="flex min-h-0 min-w-0 flex-1 flex-col gap-3 bg-background p-3 sm:gap-4 sm:p-6"
      >
        <div className="mx-auto flex min-h-0 min-w-0 w-full max-w-5xl flex-1">
          <MeetingDetailsTabs
            activeTab={activeTab}
            info={
              <>
                <MeetingHeader
                  readOnly={meeting.can_manage === false}
                  meetingId={meeting.id}
                  title={meetingData.meetingTitle}
                  createdAt={meeting.created_at}
                  durationSeconds={meeting.audio_duration ?? null}
                  segmentCount={segmentCount}
                  meetingFolderPath={meeting.folder_path}
                  hasAudio={!!meeting.has_audio}
                  onRename={meetingOperations.handleRenameMeeting}
                  onCopyTranscript={copyOperations.handleCopyTranscript}
                  onExport={copyOperations.handleExportMarkdown}
                  onOpenFolder={meetingOperations.handleOpenMeetingFolder}
                  onDelete={meetingOperations.handleDeleteMeeting}
                  onRefetchTranscripts={onRefetchTranscripts}
                />
                {/* Only the cloud-download action fetches and caches recording bytes. */}
                {hasRecording && <MeetingAudioPlayer meetingId={meeting.id} />}
              </>
            }
            onTabChange={(tab) => {
              manuallySelectedTabMeetingIdsRef.current.add(meeting.id);
              setActiveTab(tab);
            }}
            transcript={
              <TranscriptPanel
                readOnly={meeting.can_manage === false}
                transcripts={meetingData.transcripts}
                customPrompt={customPrompt}
                onPromptChange={setCustomPrompt}
                onCopyTranscript={copyOperations.handleCopyTranscript}
                isRecording={isRecording}
                isProcessing={isSyncing}
                emptyState={transcriptState}
                usePagination={true}
                segments={segments}
                hasMore={hasMore}
                isLoadingMore={isLoadingMore}
                totalCount={totalCount}
                loadedCount={loadedCount}
                onLoadMore={onLoadMore}
              />
            }
            summary={
              <SummaryPanel
                readOnly={meeting.can_manage === false}
                meeting={meeting}
                meetingTitle={meetingData.meetingTitle}
                summaryRef={meetingData.blockNoteSummaryRef}
                isSaving={meetingData.isSaving}
                isSummaryDirty={meetingData.isSummaryDirty}
                onSaveAll={meetingData.saveAllChanges}
                onCopySummary={copyOperations.handleCopySummary}
                aiSummary={meetingData.aiSummary}
                summaryStatus={summaryGeneration.summaryStatus}
                transcripts={meetingData.transcripts}
                llm={llm}
                onGenerateSummary={summaryGeneration.handleGenerateSummary}
                onStopGeneration={summaryGeneration.handleStopGeneration}
                customPrompt={customPrompt}
                onSaveSummary={meetingData.handleSaveSummary}
                onSummaryChange={meetingData.handleSummaryChange}
                onDirtyChange={meetingData.setIsSummaryDirty}
                summaryError={summaryGeneration.summaryError}
                onRegenerateSummary={summaryGeneration.handleRegenerateSummary}
                getSummaryStatusMessage={summaryGeneration.getSummaryStatusMessage}
              />
            }
          />
        </div>
      </motion.div>
    </MeetingAudioProvider>
  );
}
