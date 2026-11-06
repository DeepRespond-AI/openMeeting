import { describe, expect, test } from 'bun:test';
import { renderToStaticMarkup } from 'react-dom/server';
import { transcriptEmptyState, type RecordingSnapshot, type TranscriptEmptyState } from '../../src/lib/meeting-processing';
import { MeetingTranscriptList } from '../../src/components/meeting-details/MeetingTranscriptList';
import { t } from '../../src/i18n';

const snapshot = (status: string): RecordingSnapshot => ({ data: { status, error: null, message: null, jobId: 'test' }, error: null });
describe('meeting processing and transcript empty results', () => {
  for (const status of ['queued', 'running']) test(`${status} is not no-speech when local sync is finished`, () => {
    expect(transcriptEmptyState(snapshot(status), false, false)).toBe('processing');
  });
  for (const status of ['completed', 'none']) test(`${status} allows an empty result only after refresh and sync`, () => {
    expect(transcriptEmptyState(snapshot(status), false, false)).toBe('empty');
    expect(transcriptEmptyState(snapshot(status), true, false)).toBe('processing');
    expect(transcriptEmptyState(snapshot(status), false, true)).toBe('processing');
    expect(transcriptEmptyState(snapshot(status), null, false)).toBe('checking');
  });
  test('unknown and unreadable status never asserts no speech', () => {
    expect(transcriptEmptyState(null, false, false)).toBe('checking');
    expect(transcriptEmptyState(snapshot('future-state'), false, false)).toBe('checking');
    expect(transcriptEmptyState({ data: null, error: '503' }, false, false)).toBe('unavailable');
  });
  for (const status of ['failed', 'cancelled']) test(`${status} is a failure, not a no-speech result`, () => {
    expect(transcriptEmptyState(snapshot(status), false, false)).toBe('failed');
  });
  for (const mode of ['checking', 'processing', 'failed', 'unavailable', 'empty'] as TranscriptEmptyState[]) test(`renders ${mode} accurately`, () => {
    const html = renderToStaticMarkup(<MeetingTranscriptList segments={[]} emptyState={mode} />);
    expect(html).toContain(`data-state="${mode}"`);
    expect(html.includes(t('meeting.transcript.emptyHint'))).toBe(mode === 'empty');
  });
});
