'use client'

import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { toast } from 'sonner';
import { useRecordingState } from '@/contexts/RecordingStateContext';
import { t } from '@/i18n';
import {
  checkForUpdates as checkUpdate,
  installUpdate,
  markPrompted,
  shouldPrompt,
  UPDATE_CHECK_INITIAL_DELAY_MS,
  UPDATE_CHECK_INTERVAL_MS,
  type UpdateInfo,
  type UpdateProgress,
} from '@/services/updateService';
import { UpdateDialog } from '@/components/updates/UpdateDialog';
import { ForceUpdateGate } from '@/components/updates/ForceUpdateGate';

interface UpdateCheckContextType {
  updateInfo: UpdateInfo | null;
  isChecking: boolean;
  /** Manual check (Settings → About): reports "up to date" / failures with a toast. */
  checkForUpdates: () => Promise<void>;
}

const UpdateCheckContext = createContext<UpdateCheckContextType>({
  updateInfo: null,
  isChecking: false,
  checkForUpdates: async () => {},
});

const errorText = (error: unknown) => (error instanceof Error ? error.message : String(error));

/**
 * Checks the server for app updates shortly after start-up and every few hours. Optional
 * updates open a dialog (at most once a day per version); forced updates cover the whole app
 * (login screen included) with an update screen — held back while a recording is running.
 */
export function UpdateCheckProvider({ children }: { children: React.ReactNode }) {
  const { isRecording } = useRecordingState();
  const [updateInfo, setUpdateInfo] = useState<UpdateInfo | null>(null);
  const [isChecking, setIsChecking] = useState(false);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [installing, setInstalling] = useState(false);
  const [progress, setProgress] = useState<UpdateProgress | null>(null);
  const [installError, setInstallError] = useState<string | null>(null);
  const checkingRef = useRef(false);

  const runCheck = useCallback(async (manual: boolean) => {
    if (checkingRef.current) return;
    checkingRef.current = true;
    setIsChecking(true);
    try {
      const info = await checkUpdate();
      setUpdateInfo(info);
      if (!info.available || !info.version) {
        if (manual) toast.success(t('update.about.upToDate'));
        return;
      }
      if (info.force) return; // the gate takes over
      if (manual || shouldPrompt(info.version)) {
        markPrompted(info.version);
        setInstallError(null);
        setDialogOpen(true);
      }
    } catch (error) {
      console.warn('[Update] Check failed:', error);
      if (manual) toast.error(t('update.about.checkFailed'), { description: errorText(error) });
    } finally {
      checkingRef.current = false;
      setIsChecking(false);
    }
  }, []);

  useEffect(() => {
    const first = setTimeout(() => void runCheck(false), UPDATE_CHECK_INITIAL_DELAY_MS);
    const interval = setInterval(() => void runCheck(false), UPDATE_CHECK_INTERVAL_MS);
    return () => {
      clearTimeout(first);
      clearInterval(interval);
    };
  }, [runCheck]);

  const install = useCallback(async () => {
    setInstalling(true);
    setInstallError(null);
    setProgress(null);
    try {
      await installUpdate(setProgress);
      // The app restarts when the install succeeds.
    } catch (error) {
      setInstallError(errorText(error));
      setInstalling(false);
    }
  }, []);

  const checkForUpdates = useCallback(() => runCheck(true), [runCheck]);
  const forced = !!updateInfo?.available && updateInfo.force;

  return (
    <UpdateCheckContext.Provider value={{ updateInfo, isChecking, checkForUpdates }}>
      {children}
      {updateInfo?.available && !forced && (
        <UpdateDialog
          open={dialogOpen}
          info={updateInfo}
          installing={installing}
          progress={progress}
          error={installError}
          onInstall={install}
          onClose={() => setDialogOpen(false)}
        />
      )}
      {forced && !isRecording && (
        <ForceUpdateGate
          info={updateInfo}
          installing={installing}
          progress={progress}
          error={installError}
          onInstall={install}
        />
      )}
    </UpdateCheckContext.Provider>
  );
}

export function useUpdateCheckContext() {
  return useContext(UpdateCheckContext);
}
