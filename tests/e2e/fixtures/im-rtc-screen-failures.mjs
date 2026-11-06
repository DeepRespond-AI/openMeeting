/** Deterministic errors above the real SDK; never change deployed RTC configuration. */
export function withScreenFailures(handle, fixture) {
  const publish=handle.publishScreenTrack.bind(handle),refresh=handle.refresh.bind(handle);
  handle.publishScreenTrack=async(...args)=>{if(fixture.publishDenied){const error=Error('Fixture screen source forbidden');error.name='PublishTrackError';error.status=403;throw error;}if(fixture.publishError)throw Error('Fixture SDK publish failure');return publish(...args);};
  handle.refresh=async()=>{if(fixture.refreshError)throw Error('Fixture SDK refresh failure');return refresh();};
  return handle;
}
