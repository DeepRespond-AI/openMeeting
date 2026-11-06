import { meetingUi as defaults } from '../../../frontend/src/config/meeting-ui';
import type { MeetingUiConfig } from '../../../frontend/src/config/meeting-ui';

// Only webpack's explicit development fixture can load this override.
const disabled: string[] = typeof window === 'undefined' ? [] : (window as any).__meetingUiDisabled || [];
const config = { ...defaults };
for (const key of disabled) {
  if (Object.hasOwn(config, key)) config[key as keyof MeetingUiConfig] = false;
}
export const meetingUi = Object.freeze({ ...config, recording: config.recording && config.audio });
