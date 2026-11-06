"use client";
import { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { Bluetooth, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';

interface AudioOutputInfo {
  device_name: string;
  is_bluetooth: boolean;
  sample_rate: number | null;
  device_type: string;
}

interface BluetoothPlaybackWarningProps {
  /** Check interval in milliseconds (default: 5000ms / 5 seconds) */
  checkInterval?: number;
  /** Whether to show the warning (default: true for meeting playback pages) */
  enabled?: boolean;
}

export function BluetoothPlaybackWarning({
  checkInterval = 5000,
  enabled = true
}: BluetoothPlaybackWarningProps) {
  const t = useT();
  const [isBluetoothActive, setIsBluetoothActive] = useState(false);
  const [deviceName, setDeviceName] = useState<string>('');
  const [isDismissed, setIsDismissed] = useState(false);

  useEffect(() => {
    if (!enabled) return;

    const checkAudioOutput = async () => {
      try {
        const outputInfo = await invoke<AudioOutputInfo>('get_active_audio_output');

        if (outputInfo.is_bluetooth) {
          setIsBluetoothActive(true);
          setDeviceName(outputInfo.device_name);
        } else {
          setIsBluetoothActive(false);
          setIsDismissed(false); // Reset dismissal when switching to non-BT device
        }
      } catch (error) {
        console.error('Failed to check audio output device:', error);
        // Fail silently - don't show warning if we can't detect device
        setIsBluetoothActive(false);
      }
    };

    // Check immediately on mount
    checkAudioOutput();

    // Set up periodic checks
    const interval = setInterval(checkAudioOutput, checkInterval);

    return () => clearInterval(interval);
  }, [checkInterval, enabled]);

  // Don't show warning if Bluetooth not active, already dismissed, or not enabled
  if (!enabled || !isBluetoothActive || isDismissed) {
    return null;
  }

  return (
    <div
      className="mb-4 flex items-start gap-3 rounded-xl border border-warning/40 bg-warning/10 p-4 text-sm"
      role="alert"
      aria-live="polite"
    >
      <span className="mt-0.5 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-warning/15 text-warning">
        <Bluetooth className="h-4 w-4" />
      </span>
      <div className="min-w-0 flex-1">
        <h5 className="text-sm font-semibold text-foreground">
          {t('dialogs.bluetooth.title')}
        </h5>
        <div className="mt-1 space-y-1 leading-relaxed text-muted-foreground">
          <p className="break-words">
            {t('dialogs.bluetooth.usingDevice', { device: deviceName })}
          </p>
          <p>{t('dialogs.bluetooth.body')}</p>
        </div>
      </div>
      <Button
        variant="ghost"
        size="icon"
        onClick={() => setIsDismissed(true)}
        className="h-7 w-7 shrink-0 rounded-lg text-muted-foreground hover:text-foreground"
        aria-label={t('dialogs.bluetooth.dismiss')}
        title={t('dialogs.bluetooth.dismiss')}
      >
        <X className="h-4 w-4" />
      </Button>
    </div>
  );
}
