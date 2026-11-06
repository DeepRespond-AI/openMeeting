'use client';

import { useState, useEffect } from 'react';
import { ChevronDown, Globe, Lock, Mic, Upload } from 'lucide-react';
import { RecordingControls } from '@/components/RecordingControls';
import { useSidebar } from '@/components/sidebar/SidebarProvider';
import { usePermissionCheck } from '@/hooks/usePermissionCheck';
import { useRecordingState, RecordingStatus } from '@/contexts/RecordingStateContext';
import { useTranscripts } from '@/contexts/TranscriptContext';
import { useConfig } from '@/contexts/ConfigContext';
import { useImportDialog } from '@/contexts/ImportDialogContext';
import { Button } from '@/components/ui/button';
import { StatusOverlays } from '@/app/_components/StatusOverlays';
import Analytics from '@/lib/analytics';
import { SettingsModals } from '../_components/SettingsModal';
import { TranscriptPanel } from '../_components/TranscriptPanel';
import { useModalState } from '@/hooks/useModalState';
import { useRecordingStateSync } from '@/hooks/useRecordingStateSync';
import { useRecordingStart } from '@/hooks/useRecordingStart';
import { useRecordingStop } from '@/hooks/useRecordingStop';
import { useI18n } from '@/i18n';
import { cn } from '@/lib/utils';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { RecordingStatusChip } from '@/components/RecordingStatusBar';
import { DeviceSelection } from '@/components/DeviceSelection';
import { LanguageSelection, transcriptionLanguageLabel } from '@/components/LanguageSelection';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';

const WAVEFORM_BARS = 7;
const restingBars = () => Array.from({ length: WAVEFORM_BARS }, () => '4px');

/** Strips the " (input)" / " (output)" suffix the device selector stores. */
function deviceLabel(value: string | null): string | null {
  if (!value) return null;
  return value.replace(/ \((input|output)\)$/i, '');
}

/** Standalone recording page (V2): idle = centered card, live = transcript + control dock. */
export default function RecordPage() {
  const { t, locale } = useI18n();
  // Local page state (not moved to contexts)
  const [isRecording, setIsRecordingState] = useState(false);
  const [barHeights, setBarHeights] = useState<string[]>(restingBars);

  // Use contexts for state management
  const { meetingTitle } = useTranscripts();
  const { selectedDevices, setSelectedDevices, selectedLanguage, setSelectedLanguage, betaFeatures } = useConfig();
  const { openImportDialog } = useImportDialog();
  const recordingState = useRecordingState();

  // Extract status from global state
  const { status, isStopping, isProcessing, isSaving, statusMessage } = recordingState;

  // Hooks
  const { hasMicrophone } = usePermissionCheck();
  const { setIsMeetingActive } = useSidebar();
  const { modals, messages, showModal, hideModal } = useModalState();
  const { isRecordingDisabled, setIsRecordingDisabled } = useRecordingStateSync(isRecording, setIsRecordingState, setIsMeetingActive);
  const { handleRecordingStart } = useRecordingStart(isRecording, setIsRecordingState, showModal);

  // Get handleRecordingStop function and setIsStopping (state comes from global context)
  const { handleRecordingStop, setIsStopping } = useRecordingStop(
    setIsRecordingState,
    setIsRecordingDisabled
  );

  useEffect(() => {
    // Track page view
    Analytics.trackPageView('record');
  }, []);

  // Live waveform animation while recording
  useEffect(() => {
    if (recordingState.isRecording) {
      const interval = setInterval(() => {
        setBarHeights(prev => prev.map((_, i) => {
          // Taller in the middle for a natural waveform silhouette
          const center = 1 - Math.abs(i - (WAVEFORM_BARS - 1) / 2) / WAVEFORM_BARS;
          return `${Math.round(6 + Math.random() * 22 * center)}px`;
        }));
      }, 300);

      return () => clearInterval(interval);
    }
    setBarHeights(restingBars());
  }, [recordingState.isRecording]);

  // A new recording session always starts without a user-typed name.
  // Computed values using global status
  const isProcessingStop = status === RecordingStatus.PROCESSING_TRANSCRIPTS || isProcessing;
  const isWrappingUp = status === RecordingStatus.STOPPING
    || status === RecordingStatus.PROCESSING_TRANSCRIPTS
    || status === RecordingStatus.SAVING;
  const hasLiveMeeting = recordingState.isRecording || isWrappingUp;
  const showControls = (hasMicrophone || recordingState.isRecording)
    && status !== RecordingStatus.PROCESSING_TRANSCRIPTS
    && status !== RecordingStatus.SAVING;
  const devicesLocked = recordingState.isRecording;

  const micName = deviceLabel(selectedDevices.micDevice);
  const deviceChipLabel = micName ? t('home.chips.micOnly', { name: micName }) : t('home.chips.defaultDevices');
  const languageChipLabel = transcriptionLanguageLabel(selectedLanguage, locale, t);

  const chipClass = cn(
    'inline-flex max-w-full items-center gap-2 rounded-full border border-border bg-card px-3 py-1.5 text-sm text-foreground',
    'transition-colors hover:bg-accent hover:text-accent-foreground data-[state=open]:bg-accent data-[state=open]:text-accent-foreground',
  );

  const emptyState = (
    <div className="flex max-w-md flex-col items-center">
      <div className="mb-5 flex h-20 w-20 items-center justify-center rounded-full bg-accent">
        <BrandLogo size={44} />
      </div>
      <h2 className="text-xl font-semibold text-foreground">{t('home.empty.title')}</h2>
      <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{t('home.empty.description')}</p>
      <p className="mt-3 text-xs text-muted-foreground">{t('home.empty.deviceHint')}</p>
    </div>
  );

  /* ---------- Idle view: centered card per the V2 record prototype ---------- */
  if (!hasLiveMeeting) {
    return (
      <div className="flex h-full min-h-0 flex-col bg-background">
        <SettingsModals modals={modals} messages={messages} onClose={hideModal} />

        <div className="min-h-0 flex-1 overflow-y-auto custom-scrollbar p-4 sm:p-6">
          <div className="rise mx-auto flex min-h-full w-full max-w-xl flex-col items-center justify-center gap-6 py-6 text-center sm:gap-8">
            <div className="flex flex-col items-center">
              <div className="mb-5 flex h-20 w-20 items-center justify-center rounded-full bg-accent">
                <BrandLogo size={44} />
              </div>
              <h2 className="text-xl font-semibold text-foreground">{t('home.empty.title')}</h2>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">{t('home.empty.description')}</p>
              <p className="mt-3 text-xs text-muted-foreground">{t('home.empty.deviceHint')}</p>
            </div>

            <RecordingControls
              isRecording={recordingState.isRecording}
              onRecordingStop={(callApi = true) => handleRecordingStop(callApi)}
              onRecordingStart={handleRecordingStart}
              onTranscriptReceived={() => { }} // Not actually used by RecordingControls
              onStopInitiated={() => setIsStopping(true)}
              barHeights={barHeights}
              onTranscriptionError={(message) => {
                showModal('errorAlert', message);
              }}
              isRecordingDisabled={isRecordingDisabled}
              isParentProcessing={isProcessingStop}
              selectedDevices={selectedDevices}
              meetingName={meetingTitle}
            />

            <div className="flex flex-wrap items-center justify-center gap-3">
              <Popover>
                <PopoverTrigger asChild>
                  <button type="button" className={chipClass} title={t('home.chips.devices')}>
                    <Mic className="h-4 w-4 shrink-0 text-primary" />
                    <span className="max-w-[220px] truncate">{deviceChipLabel}</span>
                    <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                  </button>
                </PopoverTrigger>
                <PopoverContent side="top" align="center" className="w-[min(380px,calc(100vw-2rem))] rounded-xl p-4 shadow-elevated">
                  <DeviceSelection
                    selectedDevices={selectedDevices}
                    onDeviceChange={setSelectedDevices}
                    disabled={devicesLocked}
                  />
                </PopoverContent>
              </Popover>

              <Popover>
                <PopoverTrigger asChild>
                  <button type="button" className={chipClass} title={t('home.chips.language')}>
                    <Globe className="h-4 w-4 shrink-0 text-primary" />
                    <span className="max-w-[180px] truncate">{languageChipLabel}</span>
                    <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                  </button>
                </PopoverTrigger>
                <PopoverContent side="top" align="center" className="w-[min(360px,calc(100vw-2rem))] rounded-xl p-4 shadow-elevated">
                  <LanguageSelection
                    selectedLanguage={selectedLanguage}
                    onLanguageChange={setSelectedLanguage}
                    disabled={devicesLocked}
                  />
                </PopoverContent>
              </Popover>

              {betaFeatures.importAndRetranscribe && (
                <Button variant="outline" size="sm" className="rounded-full" onClick={() => openImportDialog()}>
                  <Upload className="h-4 w-4" />
                  {t('nav.primary.importAudio')}
                </Button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  /* ---------- Live view: transcript panel + control dock ---------- */
  return (
    <div className="flex h-full min-h-0 min-w-0 flex-col gap-3 bg-background p-3 sm:gap-4 sm:p-6">
      {/* All Modals supported*/}
      <SettingsModals modals={modals} messages={messages} onClose={hideModal} />

      {/* Live transcript card */}
      <TranscriptPanel
        className="flex-1"
        isProcessingStop={isProcessingStop}
        isStopping={isStopping}
        emptyState={emptyState}
        headerAction={<RecordingStatusChip />}
      />

      {/* Control dock: devices · record control · language */}
      <div className="grid shrink-0 grid-cols-1 items-center gap-3 rounded-xl border border-border bg-card p-3 shadow-card sm:grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] sm:gap-4 sm:px-5 sm:py-4 [&>div]:min-w-0">
        <div className="flex min-w-0 justify-start">
          <Popover>
            <PopoverTrigger asChild>
              <button type="button" className={chipClass} title={t('home.chips.devices')}>
                <Mic className="h-4 w-4 shrink-0 text-primary" />
                <span className="truncate">{deviceChipLabel}</span>
                {devicesLocked ? (
                  <Lock className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                ) : (
                  <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                )}
              </button>
            </PopoverTrigger>
            <PopoverContent side="top" align="start" className="w-[min(380px,calc(100vw-2rem))] rounded-xl p-4 shadow-elevated">
              {devicesLocked && (
                <p className="mb-3 flex items-center gap-1.5 text-xs text-muted-foreground">
                  <Lock className="h-3.5 w-3.5" />
                  {t('home.chips.lockedWhileRecording')}
                </p>
              )}
              <DeviceSelection
                selectedDevices={selectedDevices}
                onDeviceChange={setSelectedDevices}
                disabled={devicesLocked}
              />
            </PopoverContent>
          </Popover>
        </div>

        <div className="flex flex-col items-center">
          {showControls ? (
            <RecordingControls
              isRecording={recordingState.isRecording}
              onRecordingStop={(callApi = true) => handleRecordingStop(callApi)}
              onRecordingStart={handleRecordingStart}
              onTranscriptReceived={() => { }} // Not actually used by RecordingControls
              onStopInitiated={() => setIsStopping(true)}
              barHeights={barHeights}
              onTranscriptionError={(message) => {
                showModal('errorAlert', message);
              }}
              isRecordingDisabled={false}
              isParentProcessing={isProcessingStop}
              selectedDevices={selectedDevices}
              meetingName={meetingTitle}
            />
          ) : (
            /* Status - Processing and Saving */
            <StatusOverlays
              isProcessing={status === RecordingStatus.PROCESSING_TRANSCRIPTS && !recordingState.isRecording}
              isSaving={status === RecordingStatus.SAVING}
              detail={statusMessage}
            />
          )}
        </div>

        <div className="flex min-w-0 justify-end">
          <Popover>
            <PopoverTrigger asChild>
              <button type="button" className={chipClass} title={t('home.chips.language')}>
                <Globe className="h-4 w-4 shrink-0 text-primary" />
                <span className="truncate">{languageChipLabel}</span>
                {devicesLocked ? (
                  <Lock className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                ) : (
                  <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                )}
              </button>
            </PopoverTrigger>
            <PopoverContent side="top" align="end" className="w-[min(360px,calc(100vw-2rem))] rounded-xl p-4 shadow-elevated">
              {devicesLocked && (
                <p className="mb-3 flex items-center gap-1.5 text-xs text-muted-foreground">
                  <Lock className="h-3.5 w-3.5" />
                  {t('home.chips.lockedWhileRecording')}
                </p>
              )}
              <LanguageSelection
                selectedLanguage={selectedLanguage}
                onLanguageChange={setSelectedLanguage}
                disabled={devicesLocked}
              />
            </PopoverContent>
          </Popover>
        </div>
      </div>
    </div>
  );
}
