"use client";

import { memo, useCallback, useEffect, useMemo, useRef } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';
import { FileText, Loader2, Play } from 'lucide-react';
import type { TranscriptSegmentData } from '@/types';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { formatClock } from '@/hooks/meeting-details/languageLabels';
import { useMeetingAudio } from './MeetingAudioContext';
import type { TranscriptEmptyState } from '@/lib/meeting-processing';

interface MeetingTranscriptListProps {
  segments: TranscriptSegmentData[];
  hasMore?: boolean;
  isLoadingMore?: boolean;
  totalCount?: number;
  loadedCount?: number;
  onLoadMore?: () => void;
  /** Show a "transcribing in the background" state instead of the empty state. */
  isProcessing?: boolean;
  emptyState?: TranscriptEmptyState;
}

// Remove filler words so saved transcripts read cleanly (same rule as the live view).
const STOP_WORDS = ['uh', 'um', 'er', 'ah', 'hmm', 'hm', 'eh', 'oh'];
function cleanStopWords(text: string): string {
  let cleaned = text;
  for (const word of STOP_WORDS) {
    cleaned = cleaned.replace(new RegExp(`\\b${word}\\b[,\\s]*`, 'gi'), ' ');
  }
  return cleaned.replace(/\s+/g, ' ').trim();
}

function confidenceTone(confidence: number): string {
  if (confidence >= 0.8) return 'bg-success';
  if (confidence >= 0.4) return 'bg-warning';
  return 'bg-destructive';
}

const TranscriptRow = memo(function TranscriptRow({
  segment,
  active,
  canSeek,
  onSeek,
}: {
  segment: TranscriptSegmentData;
  active: boolean;
  canSeek: boolean;
  onSeek: (seconds: number) => void;
}) {
  const t = useT();
  const text = cleanStopWords(segment.text) || (segment.text.trim() === '' ? t('meeting.transcript.silence') : segment.text);
  const time = formatClock(segment.timestamp);
  const confidencePercent = segment.confidence !== undefined ? Math.round(segment.confidence * 100) : null;

  return (
    <div
      id={`segment-${segment.id}`}
      className={cn(
        'group flex items-start gap-3 rounded-lg px-3 py-2 transition-colors',
        active ? 'bg-accent' : 'hover:bg-muted/60',
      )}
    >
      <button
        type="button"
        disabled={!canSeek}
        onClick={() => onSeek(segment.timestamp)}
        title={canSeek ? t('meeting.transcript.playFrom', { time }) : undefined}
        aria-label={canSeek ? t('meeting.transcript.playFrom', { time }) : time}
        className={cn(
          'mt-0.5 inline-flex shrink-0 items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium tabular-nums transition-colors',
          active ? 'bg-primary text-primary-foreground' : 'bg-secondary text-muted-foreground',
          canSeek && !active && 'hover:bg-primary/10 hover:text-primary',
          !canSeek && 'cursor-default',
        )}
      >
        {canSeek && <Play className="hidden h-3 w-3 group-hover:inline" fill="currentColor" />}
        {time}
      </button>
      <p className={cn('min-w-0 flex-1 text-sm leading-relaxed', active ? 'text-accent-foreground' : 'text-foreground')}>
        {segment.speaker && <span className="mb-1 block break-words text-xs font-semibold text-primary">{segment.speaker}</span>}
        <span className="break-words">{text}</span>
      </p>
      {confidencePercent !== null && (
        <span
          className={cn('mt-2 h-1.5 w-1.5 shrink-0 rounded-full opacity-60', confidenceTone(segment.confidence!))}
          title={t('meeting.transcript.confidence', { percent: confidencePercent })}
          aria-label={t('meeting.transcript.confidence', { percent: confidencePercent })}
        />
      )}
    </div>
  );
});

/**
 * Saved-meeting transcript: virtualized, infinite-scroll paginated, with timestamps that seek
 * the recording and the row being played highlighted.
 */
export function MeetingTranscriptList({
  segments,
  hasMore = false,
  isLoadingMore = false,
  totalCount = 0,
  loadedCount = 0,
  onLoadMore,
  isProcessing = false,
  emptyState,
}: MeetingTranscriptListProps) {
  const t = useT();
  const audio = useMeetingAudio();
  const scrollRef = useRef<HTMLDivElement>(null);
  const loadMoreRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: segments.length,
    getScrollElement: () => scrollRef.current,
    estimateSize: () => 56,
    overscan: 10,
  });

  const playFrom = audio?.playFrom;
  const seek = useCallback((seconds: number) => playFrom?.(seconds), [playFrom]);

  // Index of the segment under the playhead (segments are ordered by start time).
  const activeIndex = useMemo(() => {
    if (!audio?.ready || (!audio.isPlaying && audio.currentTime === 0)) return -1;
    const now = audio.currentTime;
    let lo = 0;
    let hi = segments.length - 1;
    let found = -1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      if (segments[mid].timestamp <= now) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    if (found < 0) return -1;
    const seg = segments[found];
    const end = seg.endTime ?? segments[found + 1]?.timestamp ?? Infinity;
    return now < end ? found : -1;
  }, [audio?.ready, audio?.isPlaying, audio?.currentTime, segments]);

  // Keep the playing row in view while audio plays.
  const lastScrolledRef = useRef(-1);
  useEffect(() => {
    if (activeIndex < 0 || !audio?.isPlaying || activeIndex === lastScrolledRef.current) return;
    lastScrolledRef.current = activeIndex;
    virtualizer.scrollToIndex(activeIndex, { align: 'auto' });
  }, [activeIndex, audio?.isPlaying, virtualizer]);

  // Infinite scroll: observe the sentinel below the list.
  useEffect(() => {
    if (!onLoadMore || !hasMore || isLoadingMore || segments.length === 0) return;
    const el = loadMoreRef.current;
    if (!el) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) onLoadMore();
      },
      { root: scrollRef.current, rootMargin: '200px', threshold: 0 },
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [hasMore, isLoadingMore, onLoadMore, segments.length]);

  // Scroll fallback for fast scrolling past the sentinel.
  useEffect(() => {
    const el = scrollRef.current;
    if (!el || !onLoadMore || !hasMore || isLoadingMore) return;
    let ticking = false;
    const onScroll = () => {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        if (el.scrollHeight - el.scrollTop - el.clientHeight < 200) onLoadMore();
        ticking = false;
      });
    };
    el.addEventListener('scroll', onScroll, { passive: true });
    return () => el.removeEventListener('scroll', onScroll);
  }, [hasMore, isLoadingMore, onLoadMore]);

  const mode = emptyState ?? (isProcessing ? 'processing' : 'empty');
  if (segments.length === 0 && mode !== 'empty') {
    return (
      <div data-testid="transcript-empty-state" data-state={mode} role={mode === 'failed' || mode === 'unavailable' ? 'alert' : 'status'} className="flex h-full flex-col items-center justify-center p-8 text-center">
        <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-accent text-primary">
          {mode === 'checking' || mode === 'processing' ? <Loader2 className="h-5 w-5 animate-spin" /> : <FileText className="h-5 w-5" />}
        </div>
        <p className="text-sm font-medium text-foreground">{t(`meeting.transcript.${mode}`)}</p>
        <p className="mt-1 text-xs text-muted-foreground">{t(`meeting.transcript.${mode}Hint`)}</p>
      </div>
    );
  }

  if (segments.length === 0) {
    return (
      <div data-testid="transcript-empty-state" data-state="empty" className="flex h-full flex-col items-center justify-center p-8 text-center">
        <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-accent text-primary">
          <FileText className="h-5 w-5" />
        </div>
        <p className="text-sm font-medium text-foreground">{t('meeting.transcript.empty')}</p>
        <p className="mt-1 text-xs text-muted-foreground">{t('meeting.transcript.emptyHint')}</p>
      </div>
    );
  }

  const canSeek = !!audio?.ready;

  return (
    <div ref={scrollRef} className="h-full overflow-y-auto px-2 py-2">
      <div style={{ height: virtualizer.getTotalSize(), width: '100%', position: 'relative' }}>
        {virtualizer.getVirtualItems().map((row) => {
          const segment = segments[row.index];
          return (
            <div
              key={segment.id}
              data-index={row.index}
              ref={virtualizer.measureElement}
              style={{ position: 'absolute', top: 0, left: 0, width: '100%', transform: `translateY(${row.start}px)` }}
            >
              <TranscriptRow segment={segment} active={row.index === activeIndex} canSeek={canSeek} onSeek={seek} />
            </div>
          );
        })}
      </div>

      {(hasMore || isLoadingMore) && (
        <div ref={loadMoreRef} className="flex items-center justify-center py-4 text-xs text-muted-foreground">
          {isLoadingMore ? (
            <span className="inline-flex items-center gap-2">
              <Loader2 className="h-3.5 w-3.5 animate-spin text-primary" />
              {t('meeting.transcript.loadingMore')}
            </span>
          ) : totalCount > 0 ? (
            t('meeting.transcript.showing', { loaded: loadedCount, total: totalCount })
          ) : null}
        </div>
      )}
    </div>
  );
}
