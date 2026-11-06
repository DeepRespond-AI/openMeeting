import React from 'react';
import { AlertTriangle, Mic, Speaker, RefreshCw } from 'lucide-react';
import { invoke } from '@tauri-apps/api/core';
import { useIsLinux } from '@/hooks/usePlatform';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';

interface PermissionWarningProps {
  hasMicrophone: boolean;
  hasSystemAudio: boolean;
  onRecheck: () => void;
  isRechecking?: boolean;
}

export function PermissionWarning({
  hasMicrophone,
  hasSystemAudio,
  onRecheck,
  isRechecking = false
}: PermissionWarningProps) {
  const isLinux = useIsLinux();
  const t = useT();

  // Don't show on Linux - permission handling is not needed
  if (isLinux) {
    return null;
  }

  // Don't show if both permissions are granted
  if (hasMicrophone && hasSystemAudio) {
    return null;
  }

  const isMacOS = navigator.userAgent.includes('Mac');
  const appName = t('common.appName');

  const openMicrophoneSettings = async () => {
    if (isMacOS) {
      try {
        await invoke('open_system_settings', { preferencePane: 'Privacy_Microphone' });
      } catch (error) {
        console.error('Failed to open microphone settings:', error);
      }
    }
  };

  const openScreenRecordingSettings = async () => {
    if (isMacOS) {
      try {
        await invoke('open_system_settings', { preferencePane: 'Privacy_ScreenCapture' });
      } catch (error) {
        console.error('Failed to open screen recording settings:', error);
      }
    }
  };

  const title = !hasMicrophone && !hasSystemAudio
    ? t('dialogs.permission.bothRequired')
    : !hasMicrophone
      ? t('dialogs.permission.microphoneRequired')
      : t('dialogs.permission.systemAudioRequired');

  return (
    <div className="max-w-md mb-4 space-y-3">
      {/* Combined Permission Warning - Show when either permission is missing */}
      {(!hasMicrophone || !hasSystemAudio) && (
        <div
          role="alert"
          className="rounded-xl border border-warning/40 bg-warning/10 p-4 text-sm text-foreground"
        >
          <div className="flex items-start gap-3">
            <span className="mt-0.5 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-warning/15 text-warning">
              <AlertTriangle className="h-4 w-4" />
            </span>
            <div className="min-w-0 flex-1">
              <h5 className="flex items-center gap-2 text-sm font-semibold text-foreground">
                {!hasMicrophone && <Mic className="h-4 w-4 text-warning" />}
                {!hasSystemAudio && <Speaker className="h-4 w-4 text-warning" />}
                {title}
              </h5>

              <div className="mt-2 space-y-3 text-muted-foreground">
                {/* Microphone Warning */}
                {!hasMicrophone && (
                  <div className="space-y-2">
                    <p className="leading-relaxed">
                      {t('dialogs.permission.microphoneMissing', { app: appName })}
                    </p>
                    <div className="space-y-1 text-xs">
                      <p className="font-medium text-foreground">{t('dialogs.permission.pleaseCheck')}</p>
                      <ul className="list-disc list-inside ml-1 space-y-0.5">
                        <li>{t('dialogs.permission.checkConnected')}</li>
                        <li>{t('dialogs.permission.checkPermission')}</li>
                        <li>{t('dialogs.permission.checkExclusive')}</li>
                      </ul>
                    </div>
                  </div>
                )}

                {/* System Audio Warning */}
                {!hasSystemAudio && (
                  <div className="space-y-2">
                    <p className="leading-relaxed">
                      {hasMicrophone
                        ? t('dialogs.permission.systemAudioUnavailableMicOk')
                        : t('dialogs.permission.systemAudioAlsoUnavailable')}
                    </p>
                    {isMacOS && (
                      <div className="space-y-1 text-xs">
                        <p className="font-medium text-foreground">{t('dialogs.permission.macSystemAudioTitle')}</p>
                        <ul className="list-disc list-inside ml-1 space-y-0.5">
                          <li>{t('dialogs.permission.macStepVirtualDevice')}</li>
                          <li>{t('dialogs.permission.macStepScreenRecording', { app: appName })}</li>
                          <li>{t('dialogs.permission.macStepRouting')}</li>
                        </ul>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div className="mt-4 flex flex-wrap gap-2">
                {isMacOS && !hasMicrophone && (
                  <Button size="sm" className="rounded-lg" onClick={openMicrophoneSettings}>
                    <Mic className="h-4 w-4" />
                    {t('dialogs.permission.openMicrophoneSettings')}
                  </Button>
                )}
                {isMacOS && !hasSystemAudio && (
                  <Button size="sm" className="rounded-lg" onClick={openScreenRecordingSettings}>
                    <Speaker className="h-4 w-4" />
                    {t('dialogs.permission.openScreenRecordingSettings')}
                  </Button>
                )}
                <Button
                  size="sm"
                  variant="outline"
                  className="rounded-lg"
                  onClick={onRecheck}
                  disabled={isRechecking}
                >
                  <RefreshCw className={`h-4 w-4 ${isRechecking ? 'animate-spin' : ''}`} />
                  {t('dialogs.permission.recheck')}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
