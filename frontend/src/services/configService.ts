/**
 * Configuration Service
 *
 * Handles client-side configuration Tauri calls. Model/provider configuration
 * now lives on the OpenMeeting server (see ServerContext / lib/server.ts).
 */

import { invoke } from '@tauri-apps/api/core';

export interface RecordingPreferences {
  preferred_mic_device: string | null;
  preferred_system_device: string | null;
}

export class ConfigService {
  /**
   * Get recording preferences (device preferences)
   */
  async getRecordingPreferences(): Promise<RecordingPreferences> {
    return invoke<RecordingPreferences>('get_recording_preferences');
  }
}

export const configService = new ConfigService();
