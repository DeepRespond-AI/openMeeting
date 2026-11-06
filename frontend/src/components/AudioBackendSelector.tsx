import React, { useState, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { Info } from 'lucide-react';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

export interface BackendInfo {
  id: string;
  name: string;
  description: string;
}

interface AudioBackendSelectorProps {
  currentBackend?: string;
  onBackendChange?: (backend: string) => void;
  disabled?: boolean;
}

export function AudioBackendSelector({
  currentBackend: propBackend,
  onBackendChange,
  disabled = false,
}: AudioBackendSelectorProps) {
  const [backends, setBackends] = useState<BackendInfo[]>([]);
  const [currentBackend, setCurrentBackend] = useState<string>('coreaudio');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showTooltip, setShowTooltip] = useState(false);
  const t = useT();

  // Load available backends and current selection
  useEffect(() => {
    const loadBackends = async () => {
      try {
        setLoading(true);
        setError(null);

        // Get backend info (includes name and description)
        const backendInfo = await invoke<BackendInfo[]>('get_audio_backend_info');
        setBackends(backendInfo);

        // Get current backend if not provided via props
        if (!propBackend) {
          const current = await invoke<string>('get_current_audio_backend');
          setCurrentBackend(current);
        } else {
          setCurrentBackend(propBackend);
        }
      } catch (err) {
        console.error('Failed to load audio backends:', err);
        setError(t('settings.audioBackend.loadFailed'));
      } finally {
        setLoading(false);
      }
    };

    loadBackends();
  }, [propBackend]);

  // Handle backend selection
  const handleBackendChange = async (backendId: string) => {
    try {
      setError(null);
      await invoke('set_audio_backend', { backend: backendId });
      setCurrentBackend(backendId);

      // Notify parent component
      if (onBackendChange) {
        onBackendChange(backendId);
      }

      console.log(`Audio backend changed to: ${backendId}`);
    } catch (err) {
      console.error('Failed to set audio backend:', err);
      setError(t('settings.audioBackend.changeFailed'));
    }
  };

  // Only show selector if there are multiple backends
  if (loading) {
    return (
      <div className="animate-pulse">
        <div className="h-4 bg-muted rounded w-32 mb-2"></div>
        <div className="h-10 bg-muted rounded-lg"></div>
      </div>
    );
  }

  // Hide if only one backend available
  if (backends.length <= 1) {
    return null;
  }

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        <label className="text-sm font-medium text-foreground">
          {t('settings.audioBackend.label')}
        </label>
        <div className="relative">
          <button
            type="button"
            aria-label={t('settings.audioBackend.methodsTitle')}
            onMouseEnter={() => setShowTooltip(true)}
            onMouseLeave={() => setShowTooltip(false)}
            onFocus={() => setShowTooltip(true)}
            onBlur={() => setShowTooltip(false)}
            className="text-muted-foreground hover:text-foreground transition-colors"
          >
            <Info className="h-4 w-4" />
          </button>
          {showTooltip && (
            <div className="absolute z-10 left-6 top-0 w-64 p-3 text-xs bg-foreground text-background rounded-lg shadow-card">
              <p className="font-semibold mb-1">{t('settings.audioBackend.methodsTitle')}</p>
              <ul className="space-y-1">
                {backends.map((backend) => (
                  <li key={backend.id}>
                    <span className="font-medium">{backend.name}:</span> {backend.description}
                  </li>
                ))}
              </ul>
              <p className="mt-2 opacity-75">{t('settings.audioBackend.tryHint')}</p>
            </div>
          )}
        </div>
      </div>

      {error && (
        <div className="rounded-lg bg-destructive/10 p-2 text-xs text-destructive">
          {error}
        </div>
      )}

      <div className="space-y-2">
        {backends.map((backend) => {
          // Disable Core Audio option
          const isCoreAudio = backend.id === 'screencapturekit';
          const isDisabled = disabled || isCoreAudio;
          const isActive = currentBackend === backend.id;

          return (
            <label
              key={backend.id}
              className={cn(
                'flex items-start p-3 border rounded-lg transition-colors',
                isActive ? 'border-primary bg-accent' : 'border-border bg-card hover:border-primary/40',
                isDisabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer',
              )}
            >
              <input
                type="radio"
                name="audioBackend"
                value={backend.id}
                checked={isActive}
                onChange={() => handleBackendChange(backend.id)}
                disabled={isDisabled}
                className="mt-1 h-4 w-4 accent-primary"
              />
              <div className="ml-3 flex-1 min-w-0">
                <div className="flex items-center justify-between gap-2">
                  <span className="text-sm font-medium text-foreground">
                    {backend.name}
                  </span>
                  {isActive && (
                    <span className="rounded-full bg-primary/10 px-2 py-0.5 text-xs font-medium text-primary">
                      {t('settings.audioBackend.active')}
                    </span>
                  )}
                  {isCoreAudio && (
                    <span className="rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-muted-foreground">
                      {t('settings.audioBackend.disabled')}
                    </span>
                  )}
                </div>
                <p className="mt-1 text-xs text-muted-foreground">{backend.description}</p>
              </div>
            </label>
          );
        })}
      </div>

      <ul className="text-xs text-muted-foreground space-y-1 list-disc pl-4">
        <li>{t('settings.audioBackend.notes.systemOnly')}</li>
        <li>{t('settings.audioBackend.notes.micDefault')}</li>
        <li>{t('settings.audioBackend.notes.newSessions')}</li>
      </ul>
    </div>
  );
}
