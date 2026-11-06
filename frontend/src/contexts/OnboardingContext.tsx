'use client';

import React, { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react';
import { invoke } from '@tauri-apps/api/core';
import type { PermissionStatus, OnboardingPermissions } from '@/types/onboarding';

/**
 * Onboarding flow (thin client):
 *   Step 1: Welcome
 *   Step 2: Server address
 *   Step 3: Phone-number sign in / sign up
 *   Step 4: Permissions (macOS only)
 *
 * No local models or database setup are needed any more: the server does
 * transcription, summaries and storage.
 */
const MAX_STEP = 3;

interface OnboardingStatus {
  version: string;
  completed: boolean;
  current_step: number;
  // Legacy field from the local-model era; tolerated on read, written as "not_required".
  model_status?: unknown;
  last_updated: string;
}

interface OnboardingContextType {
  currentStep: number;
  // Permissions
  permissions: OnboardingPermissions;
  permissionsSkipped: boolean;
  // Navigation
  goToStep: (step: number) => void;
  goNext: () => void;
  goPrevious: () => void;
  setPermissionStatus: (permission: keyof OnboardingPermissions, status: PermissionStatus) => void;
  setPermissionsSkipped: (skipped: boolean) => void;
  completeOnboarding: () => Promise<void>;
}

const OnboardingContext = createContext<OnboardingContextType | undefined>(undefined);

export function OnboardingProvider({ children }: { children: React.ReactNode }) {
  const [currentStep, setCurrentStep] = useState(1);
  const [completed, setCompleted] = useState(false);

  // Permissions state
  const [permissions, setPermissions] = useState<OnboardingPermissions>({
    microphone: 'not_determined',
    systemAudio: 'not_determined',
    screenRecording: 'not_determined',
  });
  const [permissionsSkipped, setPermissionsSkipped] = useState(false);

  const saveTimeoutRef = useRef<NodeJS.Timeout>();
  const isCompletingRef = useRef(false);

  useEffect(() => {
    const loadOnboardingStatus = async () => {
      try {
        const status = await invoke<OnboardingStatus | null>('get_onboarding_status');
        if (status) {
          setCompleted(!!status.completed);
          const step = Number(status.current_step) || 1;
          setCurrentStep(Math.max(1, Math.min(step, MAX_STEP)));
        }
      } catch (error) {
        console.error('[OnboardingContext] Failed to load onboarding status:', error);
      }
    };
    loadOnboardingStatus();
  }, []);

  const saveOnboardingStatus = useCallback(async (step: number, isCompleted: boolean) => {
    if (isCompletingRef.current) return;
    try {
      await invoke('save_onboarding_status_cmd', {
        status: {
          version: '2.0',
          completed: isCompleted,
          current_step: step,
          model_status: {
            parakeet: 'not_required',
            summary: 'not_required',
          },
          last_updated: new Date().toISOString(),
        },
      });
    } catch (error) {
      console.error('[OnboardingContext] Failed to save onboarding status:', error);
    }
  }, []);

  // Auto-save progress (debounced)
  useEffect(() => {
    if (saveTimeoutRef.current) clearTimeout(saveTimeoutRef.current);
    if (completed || isCompletingRef.current) return;

    saveTimeoutRef.current = setTimeout(() => {
      void saveOnboardingStatus(currentStep, completed);
    }, 1000);

    return () => {
      if (saveTimeoutRef.current) clearTimeout(saveTimeoutRef.current);
    };
  }, [currentStep, completed, saveOnboardingStatus]);

  const completeOnboarding = useCallback(async () => {
    try {
      isCompletingRef.current = true;
      if (saveTimeoutRef.current) {
        clearTimeout(saveTimeoutRef.current);
        saveTimeoutRef.current = undefined;
      }
      // The summary model is chosen on the server; the `model` arg is kept only for
      // compatibility with the existing command signature.
      await invoke('complete_onboarding', { model: '' });
      setCompleted(true);
    } catch (error) {
      console.error('[OnboardingContext] Failed to complete onboarding:', error);
      throw error;
    } finally {
      isCompletingRef.current = false;
    }
  }, []);

  const setPermissionStatus = useCallback((permission: keyof OnboardingPermissions, status: PermissionStatus) => {
    setPermissions((prev: OnboardingPermissions) => ({
      ...prev,
      [permission]: status,
    }));
  }, []);

  const goToStep = useCallback((step: number) => {
    setCurrentStep(Math.max(1, Math.min(step, MAX_STEP)));
  }, []);

  const goNext = useCallback(() => {
    setCurrentStep((prev: number) => Math.min(prev + 1, MAX_STEP));
  }, []);

  const goPrevious = useCallback(() => {
    setCurrentStep((prev: number) => Math.max(prev - 1, 1));
  }, []);

  return (
    <OnboardingContext.Provider
      value={{
        currentStep,
        permissions,
        permissionsSkipped,
        goToStep,
        goNext,
        goPrevious,
        setPermissionStatus,
        setPermissionsSkipped,
        completeOnboarding,
      }}
    >
      {children}
    </OnboardingContext.Provider>
  );
}

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  if (!context) {
    throw new Error('useOnboarding must be used within OnboardingProvider');
  }
  return context;
}
