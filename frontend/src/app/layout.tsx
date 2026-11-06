'use client'

import './globals.css'
import { Source_Sans_3 } from 'next/font/google'
import { usePathname, useRouter } from 'next/navigation'
import NavRail from '@/components/nav-rail'
import ScheduledReminders from '@/components/live-meeting/ScheduledReminders'
import MeetingRecordNotifications from '@/components/live-meeting/MeetingRecordNotifications'
import MeetingSession from '@/components/live-meeting/MeetingSession'
import { SidebarProvider } from '@/components/sidebar/SidebarProvider'
import MainContent from '@/components/main-content'
import AnalyticsProvider from '@/components/AnalyticsProvider'
import { Toaster, toast } from 'sonner'
import { TOAST_DURATION_MS } from '@/lib/toast'
import { I18nProvider, t } from '@/i18n'
import "sonner/dist/styles.css"
import { Suspense, useState, useEffect, useCallback } from 'react'
import { listen, UnlistenFn } from '@tauri-apps/api/event'
import { invoke } from '@tauri-apps/api/core'
import { TooltipProvider } from '@/components/ui/tooltip'
import { RecordingStateProvider } from '@/contexts/RecordingStateContext'
import { TranscriptProvider } from '@/contexts/TranscriptContext'
import { ConfigProvider, useConfig } from '@/contexts/ConfigContext'
import { ServerProvider } from '@/contexts/ServerContext'
import { OnboardingProvider } from '@/contexts/OnboardingContext'
import { OnboardingFlow } from '@/components/onboarding'
import { AuthGate } from '@/components/auth/AuthGate'
import { ImProvider } from '@/contexts/IMContext'
import { loadBetaFeatures } from '@/types/betaFeatures'
import { AudioUploadProgressToast } from '@/components/server/AudioUploadProgressToast'
import { UpdateCheckProvider } from '@/components/UpdateCheckProvider'
import { RecordingPostProcessingProvider } from '@/contexts/RecordingPostProcessingProvider'
import { ImportAudioDialog, ImportDropOverlay } from '@/components/import-audio'
import { ImportDialogProvider } from '@/contexts/ImportDialogContext'
import { TranscriptRecoveryGate } from './_components/TranscriptRecoveryGate'
import { isAudioExtension, getAudioFormatsDisplayList } from '@/constants/audioFormats'


const sourceSans3 = Source_Sans_3({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-source-sans-3',
})

// Module-level component — stable reference across RootLayout re-renders.
// Defined here (not inside RootLayout) so React never sees a new function type
// on re-render, which would cause unmount/remount and break initialization logic.
function ConditionalImportDialog({
  showImportDialog,
  handleImportDialogClose,
  importFilePath,
}: {
  showImportDialog: boolean;
  handleImportDialogClose: (open: boolean) => void;
  importFilePath: string | null;
}) {
  const { betaFeatures } = useConfig();

  // Only mount ImportAudioDialog (and its hooks/listeners) when feature is enabled
  if (!betaFeatures.importAndRetranscribe) {
    return null;
  }

  return (
    <ImportAudioDialog
      open={showImportDialog}
      onOpenChange={handleImportDialogClose}
      preselectedFile={importFilePath}
    />
  );
}

// export { metadata } from './metadata'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const [showOnboarding, setShowOnboarding] = useState(false)
  const [onboardingCompleted, setOnboardingCompleted] = useState(false)
  const pathname = usePathname()
  const router = useRouter()

  // Import audio state
  const [showDropOverlay, setShowDropOverlay] = useState(false)
  const [showImportDialog, setShowImportDialog] = useState(false)
  const [importFilePath, setImportFilePath] = useState<string | null>(null)

  useEffect(() => {
    // Check onboarding status first
    invoke<{ completed: boolean } | null>('get_onboarding_status')
      .then((status) => {
        const isComplete = status?.completed ?? false
        setOnboardingCompleted(isComplete)

        if (!isComplete) {
          console.log('[Layout] Onboarding not completed, showing onboarding flow')
          setShowOnboarding(true)
        } else {
          console.log('[Layout] Onboarding completed, showing main app')
        }
      })
      .catch((error) => {
        console.error('[Layout] Failed to check onboarding status:', error)
        // Default to showing onboarding if we can't check
        setShowOnboarding(true)
        setOnboardingCompleted(false)
      })
  }, [])

  // Disable context menu in production
  useEffect(() => {
    if (process.env.NODE_ENV === 'production') {
      const handleContextMenu = (e: MouseEvent) => e.preventDefault();
      document.addEventListener('contextmenu', handleContextMenu);
      return () => document.removeEventListener('contextmenu', handleContextMenu);
    }
  }, []);
  useEffect(() => {
    // Listen for tray recording toggle request
    const unlisten = listen('request-recording-toggle', () => {
      console.log('[Layout] Received request-recording-toggle from tray');

      if (showOnboarding) {
        toast.error(t('nav.layout.finishSetupFirst'), {
          description: t('nav.layout.finishSetupDescription')
        });
      } else if (pathname === '/record') {
        // Record page is mounted - its useRecordingStart listens for this event
        console.log('[Layout] Forwarding to start-recording-from-sidebar');
        window.dispatchEvent(new CustomEvent('start-recording-from-sidebar'));
      } else {
        // Navigate to the record page; the auto-start flag is consumed on mount
        console.log('[Layout] Navigating to record page with auto-start flag');
        sessionStorage.setItem('autoStartRecording', 'true');
        router.push('/record');
      }
    });

    return () => {
      unlisten.then(fn => fn());
    };
  }, [showOnboarding, pathname, router]);

  // Handle file drop for audio import
  const handleFileDrop = useCallback((paths: string[]) => {
    // Check if beta features are enabled (read from localStorage directly since we're outside ConfigProvider)
    const betaFeatures = loadBetaFeatures();

    if (!betaFeatures.importAndRetranscribe) {
      toast.error(t('nav.layout.importDisabled'), {
        description: t('nav.layout.importDisabledDescription')
      });
      return;
    }

    // Find the first audio file
    const audioFile = paths.find(p => {
      const ext = p.split('.').pop()?.toLowerCase();
      return !!ext && isAudioExtension(ext);
    });

    if (audioFile) {
      console.log('[Layout] Audio file dropped:', audioFile);
      setImportFilePath(audioFile);
      setShowImportDialog(true);
    } else if (paths.length > 0) {
      toast.error(t('nav.layout.dropAudioFile'), {
        description: t('nav.layout.supportedFormats', { formats: getAudioFormatsDisplayList() })
      });
    }
  }, []);

  // Listen for drag-drop events
  useEffect(() => {
    if (showOnboarding) return; // Don't handle drops during onboarding

    const unlisteners: UnlistenFn[] = [];
    const cleanedUpRef = { current: false };

    const setupListeners = async () => {
      // Drag enter/over - show overlay only if beta feature is enabled
      const unlistenDragEnter = await listen('tauri://drag-enter', () => {
        if (loadBetaFeatures().importAndRetranscribe) {
          setShowDropOverlay(true);
        }
      });
      if (cleanedUpRef.current) {
        unlistenDragEnter();
        return;
      }
      unlisteners.push(unlistenDragEnter);

      // Drag leave - hide overlay
      const unlistenDragLeave = await listen('tauri://drag-leave', () => {
        setShowDropOverlay(false);
      });
      if (cleanedUpRef.current) {
        unlistenDragLeave();
        unlisteners.forEach(u => u());
        return;
      }
      unlisteners.push(unlistenDragLeave);

      // Drop - process files
      const unlistenDrop = await listen<{ paths: string[] }>('tauri://drag-drop', (event) => {
        setShowDropOverlay(false);
        handleFileDrop(event.payload.paths);
      });
      if (cleanedUpRef.current) {
        unlistenDrop();
        unlisteners.forEach(u => u());
        return;
      }
      unlisteners.push(unlistenDrop);
    };

    setupListeners();

    return () => {
      cleanedUpRef.current = true;
      unlisteners.forEach((unlisten) => unlisten());
    };
  }, [showOnboarding, handleFileDrop]);

  // Handle import dialog close
  const handleImportDialogClose = useCallback((open: boolean) => {
    setShowImportDialog(open);
    if (!open) {
      setImportFilePath(null);
    }
  }, []);

  // Handler for ImportDialogProvider - opens import dialog from any child component
  const handleOpenImportDialog = useCallback((filePath?: string | null) => {
    setImportFilePath(filePath ?? null);
    setShowImportDialog(true);
  }, []);

  const handleOnboardingComplete = () => {
    console.log('[Layout] Onboarding completed, reloading app')
    setShowOnboarding(false)
    setOnboardingCompleted(true)
    // Optionally reload the window to ensure all state is fresh
    window.location.reload()
  }

  return (
    <html lang="zh-CN">
      <body className={`${sourceSans3.variable} font-sans antialiased bg-background text-foreground`}>
        <I18nProvider>
        <AnalyticsProvider>
          <RecordingStateProvider>
            <TranscriptProvider>
              <ConfigProvider>
                <ServerProvider>
                  <ScheduledReminders />
                  <OnboardingProvider>
                    <UpdateCheckProvider>
                      <SidebarProvider>
                        <TooltipProvider>
                          <RecordingPostProcessingProvider>
                            <ImportDialogProvider onOpen={handleOpenImportDialog}>
                              {/* Startup transcript recovery (always-on, from the old home page) */}
                              <TranscriptRecoveryGate />

                              {/* Recording upload progress (after stop) */}
                              <AudioUploadProgressToast />

                              {/* Show onboarding or main app */}
                              {showOnboarding ? (
                                <OnboardingFlow onComplete={handleOnboardingComplete} />
                              ) : (
                                <AuthGate>
                                  <ImProvider>
                                    <MeetingRecordNotifications />
                                    <Suspense fallback={null}>
                                    <MeetingSession>
                                    <div className="relative z-[1] flex h-full min-h-0 min-w-0" hidden={pathname === '/room'}>
                                      {pathname !== '/room' && <>
                                      <NavRail />
                                      <MainContent>{children}</MainContent>
                                      </>}
                                    </div>
                                    </MeetingSession>
                                    </Suspense>
                                  </ImProvider>
                                </AuthGate>
                              )}
                              {/* Import audio overlay and dialog */}
                              <ImportDropOverlay visible={showDropOverlay} />
                              <ConditionalImportDialog
                                showImportDialog={showImportDialog}
                                handleImportDialogClose={handleImportDialogClose}
                                importFilePath={importFilePath}
                              />
                            </ImportDialogProvider>
                          </RecordingPostProcessingProvider>
                        </TooltipProvider>
                      </SidebarProvider>
                    </UpdateCheckProvider>
                  </OnboardingProvider>
                </ServerProvider>
              </ConfigProvider>
            </TranscriptProvider>
          </RecordingStateProvider>
        </AnalyticsProvider>
        </I18nProvider>

        {/* Keep notices clear of the room toolbar and the narrow navigation rail. */}
        <Toaster
          theme="dark"
          position="bottom-right"
          offset={{ bottom: pathname === '/room' ? 104 : 24, right: 24 }}
          mobileOffset={{ bottom: pathname === '/room' ? 140 : 16, left: pathname === '/room' ? 16 : 80, right: 16 }}
          duration={TOAST_DURATION_MS}
          richColors
          closeButton
          toastOptions={{ className: 'rounded-xl font-sans' }}
        />
      </body>
    </html>
  )
}
