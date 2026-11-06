/**
 * Live-meeting data-source factory (plan §5.5).
 *
 * `NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE=mock|real` flips every live-meeting surface at once.
 * Defaults to the real Phase 1 backend; mock remains an explicit demo option.
 */
import type { LiveMeetingApi, LiveMeetingEventBus, LiveMeetingUser } from './api';
import type { MediaClient } from './media/types';
import { MockLiveMeetingApi, type MockFailures } from './mock';
import { RealLiveMeetingApi } from './real';
import { MockMediaClient } from './media/mock';
import { ImChannelMediaClient } from './media/imChannel';

export * from './types';
export type { LiveMeetingApi, LiveMeetingEventBus, LiveMeetingUser } from './api';
export type { MediaClient, SignalQuality, MediaState, MediaTrack } from './media/types';

const source = process.env.NEXT_PUBLIC_LIVE_MEETING_DATA_SOURCE === 'mock' ? 'mock' : 'real';

const api: LiveMeetingApi & LiveMeetingEventBus = source === 'real' ? new RealLiveMeetingApi() : new MockLiveMeetingApi();

const media: MediaClient = source === 'real' ? new ImChannelMediaClient() : new MockMediaClient();

export function getLiveMeetingApi(): LiveMeetingApi & LiveMeetingEventBus {
  return api;
}

export function getMediaClient(): MediaClient {
  return media;
}

export function getLiveMeetingDataSource(): 'mock' | 'real' {
  return source;
}

/** Forward the logged-in user to the data layer (mock stamps host/self identity). */
export function setLiveMeetingUser(user: LiveMeetingUser | null): void {
  if (api instanceof MockLiveMeetingApi) api.setSelf(user);
}

/** Test hook: inject join failures into the mock to develop the error UIs. */
export function setLiveMeetingMockFailures(failures: MockFailures): void {
  if (api instanceof MockLiveMeetingApi) api.setFailures(failures);
}
