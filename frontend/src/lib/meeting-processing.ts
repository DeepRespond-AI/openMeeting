import type { RecordingStatus } from '@/services/live-meeting/recording';

export type RecordingSnapshot = { data: RecordingStatus | null; error: string | null };
export type TranscriptEmptyState = 'checking' | 'processing' | 'failed' | 'unavailable' | 'empty';

/** A zero-length first page is not a final no-speech result until work is confirmed idle. */
export function transcriptEmptyState(snapshot: RecordingSnapshot | null, syncPending: boolean | null, refreshing: boolean): TranscriptEmptyState {
  if (refreshing || syncPending === true) return 'processing';
  if (snapshot?.error) return 'unavailable';
  const status = snapshot?.data?.status;
  if (status === 'queued' || status === 'running') return 'processing';
  if (status === 'failed' || status === 'cancelled') return 'failed';
  if (syncPending === null || (status !== 'none' && status !== 'completed')) return 'checking';
  return 'empty';
}
