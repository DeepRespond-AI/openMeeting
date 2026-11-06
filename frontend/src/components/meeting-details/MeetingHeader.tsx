"use client";

import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import { CalendarClock, Clock, Copy, FileDown, FileText, FolderOpen, Pencil, RefreshCw, Trash2 } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipTrigger } from '@/components/ui/tooltip';
import { ConfirmationModal } from '@/components/confirmation-model/confirmation-modal';
import { useConfig } from '@/contexts/ConfigContext';
import { useI18n } from '@/i18n';
import Analytics from '@/lib/analytics';
import { cn } from '@/lib/utils';
import { formatClock } from '@/hooks/meeting-details/languageLabels';
import { RetranscribeDialog } from './RetranscribeDialog';
import { useMeetingAudio } from './MeetingAudioContext';
import { LimitedInput } from '@/components/ui/limited-input';
import { MEETING_TITLE_MAX, textLength } from '@/lib/field-limits';

interface MeetingHeaderProps {
  readOnly?: boolean;
  meetingId: string;
  title: string;
  createdAt: string;
  /** Recording length from the server, when known. */
  durationSeconds?: number | null;
  segmentCount: number;
  meetingFolderPath?: string | null;
  hasAudio?: boolean;
  onRename: (title: string) => Promise<boolean>;
  onCopyTranscript: () => void | Promise<void>;
  onExport: (durationSeconds?: number | null) => void | Promise<void>;
  onOpenFolder: () => Promise<void>;
  onDelete: () => Promise<boolean>;
  onRefetchTranscripts?: () => Promise<void>;
}

function IconAction({
  label,
  onClick,
  disabled,
  danger,
  children,
}: {
  label: string;
  onClick: () => void;
  disabled?: boolean;
  danger?: boolean;
  children: ReactNode;
}) {
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <button
          type="button"
          onClick={onClick}
          disabled={disabled}
          aria-label={label}
          className={cn(
            'inline-flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground transition-colors',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-40',
            danger ? 'hover:bg-destructive/10 hover:text-destructive' : 'hover:bg-accent hover:text-accent-foreground',
          )}
        >
          {children}
        </button>
      </TooltipTrigger>
      <TooltipContent>{label}</TooltipContent>
    </Tooltip>
  );
}

/** Page header card: editable title, meeting facts and meeting-level actions. */
export function MeetingHeader({
  readOnly = false,
  meetingId,
  title,
  createdAt,
  durationSeconds,
  segmentCount,
  meetingFolderPath,
  hasAudio = false,
  onRename,
  onCopyTranscript,
  onExport,
  onOpenFolder,
  onDelete,
  onRefetchTranscripts,
}: MeetingHeaderProps) {
  const { t, locale } = useI18n();
  const { betaFeatures } = useConfig();
  const audio = useMeetingAudio();
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(title);
  const [savingTitle, setSavingTitle] = useState(false);
  const [showRetranscribe, setShowRetranscribe] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);
  // Set while an edit is being cancelled/committed so the trailing blur doesn't save again.
  const settledRef = useRef(false);

  // Retranscription runs on the server using its stored audio.
  const canRetranscribe = !readOnly && betaFeatures.importAndRetranscribe && (hasAudio || !!meetingFolderPath);
  const duration = durationSeconds && durationSeconds > 0 ? durationSeconds : audio?.duration ?? null;

  useEffect(() => {
    if (!editing) setDraft(title);
  }, [title, editing]);

  useEffect(() => {
    if (editing) {
      settledRef.current = false;
      inputRef.current?.select();
    }
  }, [editing]);

  const commitTitle = useCallback(async () => {
    if (settledRef.current) return;
    const next = draft.trim();
    if (!next || textLength(next) > MEETING_TITLE_MAX) return;
    if (next === title.trim()) {
      setEditing(false);
      return;
    }
    settledRef.current = true;
    setSavingTitle(true);
    const ok = await onRename(next);
    setSavingTitle(false);
    if (ok) {
      setEditing(false);
    } else {
      settledRef.current = false;
      inputRef.current?.focus();
    }
  }, [draft, onRename, title]);

  const createdLabel = (() => {
    const date = new Date(createdAt);
    if (Number.isNaN(date.getTime())) return createdAt;
    return new Intl.DateTimeFormat(locale, { dateStyle: 'medium', timeStyle: 'short' }).format(date);
  })();

  const displayTitle = title.trim() || t('meeting.header.untitled');

  return (
    <div className="rounded-xl border border-border bg-card p-5 shadow-card">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
        <div className="min-w-0 flex-1">
          {editing ? (
            <LimitedInput
              ref={inputRef}
              maxLength={MEETING_TITLE_MAX}
              value={draft}
              disabled={savingTitle}
              placeholder={t('meeting.header.titlePlaceholder')}
              aria-label={t('meeting.header.titlePlaceholder')}
              onChange={(e) => setDraft(e.target.value)}
              onBlur={() => void commitTitle()}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  void commitTitle();
                } else if (e.key === 'Escape') {
                  settledRef.current = true;
                  setDraft(title);
                  setEditing(false);
                }
              }}
              className="w-full rounded-lg border border-input bg-background px-2.5 py-1 text-xl font-semibold text-foreground outline-none focus:border-primary focus:ring-2 focus:ring-ring/30"
            />
          ) : (
            <button
              type="button"
              onClick={() => { if (!readOnly) setEditing(true); }}
              disabled={readOnly}
              title={t('meeting.header.renameHint')}
              className="group -mx-2.5 flex max-w-full items-center gap-2 rounded-lg px-2.5 py-1 text-left hover:bg-muted"
            >
              <h1 className="truncate text-xl font-semibold text-foreground">{displayTitle}</h1>
              <Pencil className="h-4 w-4 shrink-0 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" />
            </button>
          )}

          <div className="mt-2 flex flex-wrap items-center gap-x-5 gap-y-1.5 text-sm text-muted-foreground">
            <span className="inline-flex items-center gap-1.5" title={t('meeting.header.createdAt')}>
              <CalendarClock className="h-4 w-4" />
              {createdLabel}
            </span>
            {duration ? (
              <span className="inline-flex items-center gap-1.5" title={t('meeting.header.duration')}>
                <Clock className="h-4 w-4" />
                {formatClock(duration)}
              </span>
            ) : null}
            <span className="inline-flex items-center gap-1.5">
              <FileText className="h-4 w-4" />
              {t('meeting.header.segments', { n: segmentCount })}
            </span>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-1 rounded-lg bg-muted/60 p-1">
          <IconAction
            label={t('meeting.actions.copyTranscript')}
            disabled={segmentCount === 0}
            onClick={() => {
              Analytics.trackButtonClick('copy_transcript', 'meeting_details');
              void onCopyTranscript();
            }}
          >
            <Copy className="h-4 w-4" />
          </IconAction>
          <IconAction
            label={t('meeting.actions.exportMarkdown')}
            onClick={() => {
              Analytics.trackButtonClick('export_markdown', 'meeting_details');
              void onExport(duration);
            }}
          >
            <FileDown className="h-4 w-4" />
          </IconAction>
          {/* Only meetings with a local recording folder can be opened in the file explorer */}
          {meetingFolderPath && (
            <IconAction
              label={t('meeting.actions.openFolder')}
              onClick={() => {
                Analytics.trackButtonClick('open_recording_folder', 'meeting_details');
                void onOpenFolder();
              }}
            >
              <FolderOpen className="h-4 w-4" />
            </IconAction>
          )}
          {canRetranscribe && (
            <IconAction
              label={t('meeting.actions.retranscribe')}
              onClick={() => {
                Analytics.trackButtonClick('enhance_transcript', 'meeting_details');
                setShowRetranscribe(true);
              }}
            >
              <RefreshCw className="h-4 w-4" />
            </IconAction>
          )}
          <div className="mx-0.5 h-5 w-px bg-border" aria-hidden="true" />
          {!readOnly && <IconAction danger label={t('meeting.actions.delete')} onClick={() => setConfirmDelete(true)}>
            <Trash2 className="h-4 w-4" />
          </IconAction>}
        </div>
      </div>

      {canRetranscribe && (
        <RetranscribeDialog
          open={showRetranscribe}
          onOpenChange={setShowRetranscribe}
          meetingId={meetingId}
          meetingFolderPath={meetingFolderPath ?? null}
          onComplete={async () => {
            await onRefetchTranscripts?.();
          }}
        />
      )}

      <ConfirmationModal
        isOpen={confirmDelete}
        title={t('meeting.delete.title')}
        text={t('meeting.delete.description', { title: displayTitle })}
        confirmText={deleting ? t('meeting.delete.deleting') : t('meeting.delete.confirm')}
        isLoading={deleting}
        onCancel={() => setConfirmDelete(false)}
        onConfirm={async () => {
          setDeleting(true);
          const ok = await onDelete();
          setDeleting(false);
          if (ok) setConfirmDelete(false);
        }}
      />
    </div>
  );
}
