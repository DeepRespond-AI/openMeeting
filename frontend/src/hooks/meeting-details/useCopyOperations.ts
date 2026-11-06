import { useCallback, RefObject } from 'react';
import { MeetingSummary, Transcript } from '@/types';
import { BlockNoteSummaryViewRef } from '@/components/ai-summary/BlockNoteSummaryView';
import { toast } from 'sonner';
import Analytics from '@/lib/analytics';
import { invoke as invokeTauri } from '@tauri-apps/api/core';
import { hasVisibleSummaryContent } from '@/lib/summary-content';
import { getLocale, t } from '@/i18n';
import { formatClock } from './languageLabels';

const DATE_TIME: Intl.DateTimeFormatOptions = {
  year: 'numeric',
  month: 'long',
  day: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
};

// Recording-relative [MM:SS]; old transcripts without audio_start_time keep their wall-clock time.
function formatTranscriptTime(seconds: number | undefined, fallbackTimestamp: string): string {
  if (seconds === undefined) return fallbackTimestamp;
  const totalSecs = Math.floor(seconds);
  const mins = Math.floor(totalSecs / 60);
  const secs = totalSecs % 60;
  return `[${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}]`;
}

function transcriptLines(transcripts: Transcript[]): string {
  return transcripts
    .map(t => `${formatTranscriptTime(t.audio_start_time, t.timestamp)} ${t.speaker ? `${t.speaker}: ` : ''}${t.text}  `)
    .join('\n');
}

interface UseCopyOperationsProps {
  meeting: any;
  transcripts: Transcript[];
  meetingTitle: string;
  aiSummary: MeetingSummary | null;
  blockNoteSummaryRef: RefObject<BlockNoteSummaryViewRef>;
}

export function useCopyOperations({
  meeting,
  transcripts,
  meetingTitle,
  aiSummary,
  blockNoteSummaryRef,
}: UseCopyOperationsProps) {

  // Helper function to fetch ALL transcripts for copying (not just paginated data)
  const fetchAllTranscripts = useCallback(async (meetingId: string): Promise<Transcript[]> => {
    try {
      console.log('📊 Fetching all transcripts for copying:', meetingId);

      // First, get total count by fetching first page
      const firstPage = await invokeTauri('api_get_meeting_transcripts', {
        meetingId,
        limit: 1,
        offset: 0,
      }) as { transcripts: Transcript[]; total_count: number; has_more: boolean };

      const totalCount = firstPage.total_count;
      console.log(`📊 Total transcripts in database: ${totalCount}`);

      if (totalCount === 0) {
        return [];
      }

      // Fetch all transcripts in one call
      const allData = await invokeTauri('api_get_meeting_transcripts', {
        meetingId,
        limit: totalCount,
        offset: 0,
      }) as { transcripts: Transcript[]; total_count: number; has_more: boolean };

      console.log(`✅ Fetched ${allData.transcripts.length} transcripts from database for copying`);
      return allData.transcripts;
    } catch (error) {
      console.error('❌ Error fetching all transcripts:', error);
      toast.error(t('meeting.copy.transcriptFetchFailed'));
      return [];
    }
  }, []);

  // Copy transcript to clipboard
  const handleCopyTranscript = useCallback(async () => {
    // CHANGE: Fetch ALL transcripts from database, not from pagination state
    console.log('📊 Fetching all transcripts for copying...');
    const allTranscripts = await fetchAllTranscripts(meeting.id);

    if (!allTranscripts.length) {
      console.log('No transcripts available to copy');
      toast.error(t('meeting.copy.transcriptEmpty'));
      return;
    }

    console.log(`✅ Copying ${allTranscripts.length} transcripts to clipboard`);

    const header = `# ${t('meeting.copy.md.transcriptTitle', { title: meetingTitle ?? meeting.title })}\n\n`;
    const date = `**${t('meeting.copy.md.date')}:** ${new Date(meeting.created_at).toLocaleString(getLocale(), DATE_TIME)}\n\n`;
    const fullTranscript = transcriptLines(allTranscripts);

    await navigator.clipboard.writeText(header + date + fullTranscript);
    toast.success(t('meeting.copy.transcriptCopied'));

    // Track copy analytics
    const wordCount = allTranscripts
      .map(t => t.text.split(/\s+/).length)
      .reduce((a, b) => a + b, 0);

    await Analytics.trackCopy('transcript', {
      meeting_id: meeting.id,
      transcript_length: allTranscripts.length.toString(),
      word_count: wordCount.toString()
    });
  }, [meeting, meetingTitle, fetchAllTranscripts]);

  // Resolve the summary body as Markdown (BlockNote editor first, then stored markdown, then legacy JSON).
  const resolveSummaryMarkdown = useCallback(async (): Promise<string> => {
    let summaryMarkdown = '';

    if (blockNoteSummaryRef.current?.getMarkdown) {
      summaryMarkdown = await blockNoteSummaryRef.current.getMarkdown();
    }

    if (!summaryMarkdown && aiSummary && typeof aiSummary.markdown === 'string') {
      summaryMarkdown = aiSummary.markdown;
    }

    if (!summaryMarkdown && aiSummary) {
      summaryMarkdown = Object.entries(aiSummary)
        .filter(([key]) => key !== 'markdown' && key !== 'summary_json' && key !== '_section_order' && key !== 'MeetingName')
        .map(([, section]) => {
          if (section && typeof section === 'object' && 'title' in section && 'blocks' in section) {
            const sectionTitle = `## ${section.title}\n\n`;
            const sectionContent = section.blocks
              .map((block: any) => `- ${block.content}`)
              .join('\n');
            return sectionTitle + sectionContent;
          }
          return '';
        })
        .filter(s => s.trim())
        .join('\n\n');
    }

    return summaryMarkdown;
  }, [aiSummary, blockNoteSummaryRef]);

  // Copy summary to clipboard
  const handleCopySummary = useCallback(async () => {
    if (!hasVisibleSummaryContent(aiSummary)) {
      toast.error(t('meeting.copy.summaryEmpty'));
      return;
    }
    try {
      const summaryMarkdown = await resolveSummaryMarkdown();
      if (!summaryMarkdown.trim()) {
        console.error('No summary content available to copy');
        toast.error(t('meeting.copy.summaryEmpty'));
        return;
      }

      const locale = getLocale();
      const header = `# ${t('meeting.copy.md.summaryTitle', { title: meetingTitle })}\n\n`;
      const metadata = `**${t('meeting.copy.md.meetingId')}:** ${meeting.id}\n`
        + `**${t('meeting.copy.md.date')}:** ${new Date(meeting.created_at).toLocaleString(locale, DATE_TIME)}\n`
        + `**${t('meeting.copy.md.copiedOn')}:** ${new Date().toLocaleString(locale, DATE_TIME)}\n\n---\n\n`;

      await navigator.clipboard.writeText(header + metadata + summaryMarkdown);
      toast.success(t('meeting.copy.summaryCopied'));

      await Analytics.trackCopy('summary', {
        meeting_id: meeting.id,
        has_markdown: (!!aiSummary && 'markdown' in aiSummary).toString()
      });
    } catch (error) {
      console.error('Failed to copy summary:', error);
      toast.error(t('meeting.copy.summaryFailed'));
    }
  }, [aiSummary, meetingTitle, meeting, resolveSummaryMarkdown]);

  // Export the whole meeting (summary + transcript) as one Markdown document on the clipboard.
  // The webview has no file-save dialog wired up, so the clipboard is the export target.
  const handleExportMarkdown = useCallback(async (durationSeconds?: number | null) => {
    try {
      const allTranscripts = await fetchAllTranscripts(meeting.id);
      const summaryMarkdown = hasVisibleSummaryContent(aiSummary) ? (await resolveSummaryMarkdown()).trim() : '';
      if (!allTranscripts.length && !summaryMarkdown) {
        toast.error(t('meeting.copy.transcriptEmpty'));
        return;
      }

      const locale = getLocale();
      const lines = [
        `# ${t('meeting.copy.md.meetingTitle', { title: meetingTitle })}`,
        '',
        `**${t('meeting.copy.md.date')}:** ${new Date(meeting.created_at).toLocaleString(locale, DATE_TIME)}  `,
      ];
      if (durationSeconds && durationSeconds > 0) {
        lines.push(`**${t('meeting.copy.md.duration')}:** ${formatClock(durationSeconds)}  `);
      }
      lines.push(
        `**${t('meeting.copy.md.meetingId')}:** ${meeting.id}`,
        '',
        `## ${t('meeting.copy.md.summary')}`,
        '',
        summaryMarkdown || t('meeting.copy.md.noSummary'),
        '',
        `## ${t('meeting.copy.md.transcript')}`,
        '',
        transcriptLines(allTranscripts),
        '',
      );

      await navigator.clipboard.writeText(lines.join('\n'));
      toast.success(t('meeting.copy.exported'), { description: t('meeting.copy.exportedDetail') });
    } catch (error) {
      console.error('Failed to export meeting:', error);
      toast.error(t('meeting.copy.exportFailed'), {
        description: error instanceof Error ? error.message : String(error),
      });
    }
  }, [aiSummary, fetchAllTranscripts, meeting, meetingTitle, resolveSummaryMarkdown]);

  return {
    handleCopyTranscript,
    handleCopySummary,
    handleExportMarkdown,
  };
}
