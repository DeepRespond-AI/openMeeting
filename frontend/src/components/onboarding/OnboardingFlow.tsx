import React, { useEffect } from 'react';
import { useOnboarding } from '@/contexts/OnboardingContext';
import {
  WelcomeStep,
  PermissionsStep,
  AccountStep,
} from './steps';

interface OnboardingFlowProps {
  onComplete: () => void;
}

export function OnboardingFlow({ onComplete }: OnboardingFlowProps) {
  const { currentStep } = useOnboarding();
  const [isMac, setIsMac] = React.useState(false);

  useEffect(() => {
    // Check if running on macOS
    const checkPlatform = async () => {
      try {
        // Dynamic import to avoid SSR issues if any
        const { platform } = await import('@tauri-apps/plugin-os');
        setIsMac(platform() === 'macos');
      } catch (e) {
        console.error('Failed to detect platform:', e);
        // Fallback
        setIsMac(navigator.userAgent.includes('Mac'));
      }
    };
    checkPlatform();
  }, []);

  // Onboarding Flow (thin client - no local models; the server is built in):
  // Step 1: Welcome
  // Step 2: Phone-number sign in / sign up
  // Step 3: Permissions - Request mic + system audio (macOS only)
  // A step saved by an older build that had a server step may be past the last step: show the
  // account step then, so the user is never left on an empty screen.

  return (
    <div className="onboarding-flow">
      {currentStep === 1 && <WelcomeStep />}
      {(currentStep === 2 || (currentStep >= 3 && !isMac)) && <AccountStep />}
      {currentStep >= 3 && isMac && <PermissionsStep />}
    </div>
  );
}
