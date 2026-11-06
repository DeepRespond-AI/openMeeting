"use client";

import { MeetingSummary, Summary, Transcript } from '@/types';
import { BlockNoteSummaryView, BlockNoteSummaryViewRef } from '@/components/ai-summary/BlockNoteSummaryView';
import { EmptyStateSummary } from '@/components/EmptyStateSummary';
import type { LlmCapability } from '@/lib/server';
import { SummaryActionButton, SummaryGeneratorButtonGroup, chipButtonClass } from './SummaryGeneratorButtonGroup';
import { SummaryUpdaterButtonGroup } from './SummaryUpdaterButtonGroup';
import Analytics from '@/lib/analytics';
import { useEffect, useRef, useState, RefObject } from 'react';
import { toast } from 'sonner';
import { AlertCircle, Languages, ChevronDown, Loader2, Sparkles } from 'lucide-react';
import { Popover, PopoverTrigger, PopoverContent } from '@/components/ui/popover';
import { LanguagePickerPopover } from '@/components/LanguagePickerPopover';
import { useRecentLanguages } from '@/hooks/useRecentLanguages';
import { labelForCode } from '@/lib/summary-languages';
import {
  readMeetingSummaryLanguage,
  saveMeetingSummaryLanguage,
  SummaryLanguageStorage,
} from '@/lib/summary-language-preferences';
import { hasVisibleSummaryContent } from '@/lib/summary-content';
import { useI18n } from '@/i18n';
import { languageLabel } from '@/hooks/meeting-details/languageLabels';

interface SummaryPanelProps {
  readOnly?: boolean;
  meeting: {
    id: string;
    title: string;
    created_at: string;
  };
  meetingTitle: string;
  isSummaryDirty: boolean;
  summaryRef: RefObject<BlockNoteSummaryViewRef>;
  isSaving: boolean;
  onSaveAll: () => Promise<void>;
  onCopySummary: () => Promise<void>;
  aiSummary: MeetingSummary | null;
  summaryStatus: 'idle' | 'processing' | 'summarizing' | 'regenerating' | 'completed' | 'error';
  transcripts: Transcript[];
  /** Server LLM capability; null when unknown. */
  llm: LlmCapability | null;
  onGenerateSummary: (customPrompt: string) => Promise<void>;
  onStopGeneration: () => void;
  customPrompt: string;
  onSaveSummary: (summary: MeetingSummary) => Promise<void>;
  onSummaryChange: (summary: Summary) => void;
  onDirtyChange: (isDirty: boolean) => void;
  summaryError: string | null;
  onRegenerateSummary: () => Promise<void>;
  getSummaryStatusMessage: (status: 'idle' | 'processing' | 'summarizing' | 'regenerating' | 'completed' | 'error') => string;
}

export function SummaryPanel({
  readOnly = false,
  meeting,
  meetingTitle,
  isSummaryDirty,
  summaryRef,
  isSaving,
  onSaveAll,
  onCopySummary,
  aiSummary,
  summaryStatus,
  transcripts,
  llm,
  onGenerateSummary,
  onStopGeneration,
  customPrompt,
  onSaveSummary,
  onSummaryChange,
  onDirtyChange,
  summaryError,
  onRegenerateSummary,
  getSummaryStatusMessage,
}: SummaryPanelProps) {
  const [summaryLang, setSummaryLang] = useState<string | null>(null);
  const [summaryLangStorage, setSummaryLangStorage] = useState<SummaryLanguageStorage>('metadata');
  const [langPickerOpen, setLangPickerOpen] = useState(false);
  const languageLoadVersionRef = useRef(0);
  const activeMeetingIdRef = useRef(meeting.id);
  const languageSaveVersionRef = useRef(0);
  const languageSaveLoopRunningRef = useRef(false);
  const latestLanguageSaveRequestRef = useRef<{
    version: number;
    meetingId: string;
    language: string | null;
    rollback: {
      language: string | null;
      storage: SummaryLanguageStorage;
    };
  } | null>(null);
  activeMeetingIdRef.current = meeting.id;
  const { addRecent } = useRecentLanguages();
  const { t, locale } = useI18n();

  const effectiveLangLabel = summaryLang
    ? languageLabel(summaryLang, locale, labelForCode(summaryLang))
    : t('summary.language.auto');
  const isLocalFallbackLanguage = summaryLangStorage === 'local_fallback';
  const autoSubtitle = isLocalFallbackLanguage
    ? t('summary.language.autoSubtitleLocal')
    : t('summary.language.autoSubtitle');

  useEffect(() => {
    let cancelled = false;
    const loadVersion = languageLoadVersionRef.current + 1;
    languageLoadVersionRef.current = loadVersion;

    const loadSummaryLanguage = async () => {
      try {
        const stored = await readMeetingSummaryLanguage(meeting.id);
        if (!cancelled && languageLoadVersionRef.current === loadVersion) {
          setSummaryLang(stored.language);
          setSummaryLangStorage(stored.storage);
        }
      } catch (err) {
        console.error('Failed to load summary language:', err);
        toast.warning(t('summary.language.loadFailed'), {
          description: t('summary.language.loadFailedDetail'),
        });
        if (!cancelled && languageLoadVersionRef.current === loadVersion) setSummaryLang(null);
      }
    };

    loadSummaryLanguage();

    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- reload only when the meeting changes
  }, [meeting.id]);

  const persistLatestLanguageSelection = async () => {
    if (languageSaveLoopRunningRef.current) return;
    languageSaveLoopRunningRef.current = true;

    try {
      while (true) {
        const request = latestLanguageSaveRequestRef.current;
        if (!request) return;

        try {
          const saved = await saveMeetingSummaryLanguage(request.meetingId, request.language);
          const latest = latestLanguageSaveRequestRef.current;
          if (
            latest?.version === request.version &&
            activeMeetingIdRef.current === request.meetingId
          ) {
            setSummaryLang(saved.language);
            setSummaryLangStorage(saved.storage);
            if (saved.storage === 'local_fallback') {
              toast.info(t('summary.language.savedLocal'), {
                description: t('summary.language.savedLocalDetail'),
              });
            }
            if (request.language) {
              addRecent(request.language);
            }
            return;
          }

          if (latest?.version === request.version) return;
        } catch (err) {
          const latest = latestLanguageSaveRequestRef.current;
          if (
            latest?.version === request.version &&
            activeMeetingIdRef.current === request.meetingId
          ) {
            console.error('Failed to persist summary language:', err);
            toast.error(t('summary.language.saveFailed'));
            setSummaryLang(request.rollback.language);
            setSummaryLangStorage(request.rollback.storage);
            return;
          }

          console.warn('Ignoring failed stale summary language save:', err);
          if (latest?.version === request.version) return;
        }
      }
    } finally {
      languageSaveLoopRunningRef.current = false;
    }
  };

  const handleLangChange = (code: string | null) => {
    const previous = summaryLang;
    const previousStorage = summaryLangStorage;
    const nextStored = code;
    languageLoadVersionRef.current += 1;
    latestLanguageSaveRequestRef.current = {
      version: languageSaveVersionRef.current + 1,
      meetingId: meeting.id,
      language: nextStored,
      rollback: {
        language: previous,
        storage: previousStorage,
      },
    };
    languageSaveVersionRef.current += 1;
    setSummaryLang(nextStored);
    setLangPickerOpen(false);
    void persistLatestLanguageSelection();
  };

  const isSummaryLoading = summaryStatus === 'processing' || summaryStatus === 'summarizing' || summaryStatus === 'regenerating';
  const hasSummary = hasVisibleSummaryContent(aiSummary);

  const languageSlot = (
    <Popover open={langPickerOpen} onOpenChange={setLangPickerOpen}>
      <PopoverTrigger asChild>
        <button
          type="button"
          className={chipButtonClass}
          disabled={isSummaryLoading}
          title={isLocalFallbackLanguage
            ? t('summary.language.tooltipLocal', { label: effectiveLangLabel })
            : t('summary.language.tooltip', { label: effectiveLangLabel })}
          aria-label={t('summary.language.button')}
        >
          <Languages className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
          <span className="truncate">{effectiveLangLabel}</span>
          <ChevronDown className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
        </button>
      </PopoverTrigger>
      <PopoverContent
        align="start"
        className="w-auto p-0 border-0 shadow-none bg-transparent"
      >
        <LanguagePickerPopover
          value={summaryLang}
          onChange={handleLangChange}
          onClose={() => setLangPickerOpen(false)}
          autoSubtitle={autoSubtitle}
        />
      </PopoverContent>
    </Popover>
  );

  const hasTranscripts = transcripts.length > 0;
  const showToolbar = hasTranscripts || hasSummary;

  return (
    <section className="flex h-full w-full min-w-0 flex-1 flex-col overflow-hidden rounded-xl border border-border bg-card shadow-card @container">
      <header className="shrink-0 border-b border-border px-5 py-3.5">
        {/* Same row height as the transcript card header (h-8 action buttons), with or without actions. */}
        <div className="flex min-h-8 flex-wrap items-center justify-between gap-3">
          <div className="flex min-w-0 items-center gap-2">
            <Sparkles className="h-4 w-4 shrink-0 text-primary" />
            <h2 className="truncate text-base font-semibold text-foreground">{t('summary.panel.title')}</h2>
            {isSummaryLoading && (
              <span className="inline-flex shrink-0 items-center gap-1 rounded-full bg-accent px-2 py-0.5 text-xs font-medium text-accent-foreground">
                <Loader2 className="h-3 w-3 animate-spin" />
                {getSummaryStatusMessage(summaryStatus)}
              </span>
            )}
            {!isSummaryLoading && hasSummary && isSummaryDirty && (
              <span className="shrink-0 rounded-full bg-warning/10 px-2 py-0.5 text-xs font-medium text-warning">
                {t('summary.panel.unsaved')}
              </span>
            )}
          </div>
          <div className="flex min-w-0 max-w-full flex-wrap items-center gap-1.5">
            {/* Summary language picker, on the title row so both cards' headers are the same height */}
            {!readOnly && showToolbar && (
              <SummaryGeneratorButtonGroup hasTranscripts={hasTranscripts} languageSlot={languageSlot} />
            )}
            {!readOnly && hasSummary && !isSummaryLoading && (
              <SummaryUpdaterButtonGroup
                isSaving={isSaving}
                isDirty={isSummaryDirty}
                onSave={onSaveAll}
                onCopy={onCopySummary}
              />
            )}
            {!readOnly && hasTranscripts && (
              <SummaryActionButton
                onGenerateSummary={onGenerateSummary}
                onStopGeneration={onStopGeneration}
                customPrompt={customPrompt}
                summaryStatus={summaryStatus}
                hasSummary={hasSummary}
              />
            )}
          </div>
        </div>

      </header>

      {isSummaryLoading ? (
        <div className="flex flex-1 items-center justify-center p-8">
          <div className="flex max-w-sm flex-col items-center text-center">
            <div className="relative mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-accent text-primary">
              <span className="absolute inset-0 animate-ping rounded-full bg-primary/10" />
              <Sparkles className="h-6 w-6" />
            </div>
            <p className="text-base font-semibold text-foreground">{t('summary.panel.generatingTitle')}</p>
            <p className="mt-1 text-sm text-muted-foreground">{getSummaryStatusMessage(summaryStatus)}</p>
            <div className="mt-4 h-1.5 w-56 overflow-hidden rounded-full bg-muted">
              <div className="h-full w-1/3 animate-pulse rounded-full bg-primary" />
            </div>
            <p className="mt-4 text-xs text-muted-foreground">{t('summary.panel.generatingHint')}</p>
          </div>
        </div>
      ) : !hasSummary ? (
        readOnly ? <p className="p-6 text-sm text-muted-foreground">{t('meeting.shared.pendingSummary')}</p> : <EmptyStateSummary
          onGenerate={() => onGenerateSummary(customPrompt)}
          hasModel={!llm || llm.ready}
          isGenerating={isSummaryLoading}
          error={summaryError}
        />
      ) : (
        <div className="min-h-0 flex-1 overflow-x-auto overflow-y-auto">
          {summaryStatus === 'error' && summaryError && (
            <div role="alert" className="mx-5 mt-4 flex items-start gap-2 rounded-lg border border-destructive/20 bg-destructive/10 px-3 py-2 text-sm text-destructive">
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
              <span className="break-words">{summaryError}</span>
            </div>
          )}
          {/* BlockNote ships Inter; use the app font so Chinese renders with PingFang / YaHei. */}
          <div className="w-full px-1 py-4 @[40rem]:px-3 [&_.bn-default-styles]:font-sans [&_.bn-editor]:font-sans [&_.bn-editor]:text-foreground">
            <BlockNoteSummaryView
              readOnly={readOnly}
              ref={summaryRef}
              summaryData={aiSummary}
              onSave={onSaveSummary}
              onSummaryChange={onSummaryChange}
              onDirtyChange={onDirtyChange}
              status={summaryStatus}
              error={summaryError}
              onRegenerateSummary={() => {
                Analytics.trackButtonClick('regenerate_summary', 'meeting_details');
                onRegenerateSummary();
              }}
              meeting={{
                id: meeting.id,
                title: meetingTitle,
                created_at: meeting.created_at
              }}
            />
          </div>
        </div>
      )}
    </section>
  );
}
