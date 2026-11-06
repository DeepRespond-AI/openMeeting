/**
 * TranscriptRecovery Component
 *
 * Modal dialog for recovering interrupted meetings from IndexedDB.
 * Displays recoverable meetings, allows preview, and enables recovery or deletion.
 */

import React, { useState, useEffect } from 'react';
import { AlertCircle, CheckCircle2, Clock, FileText, Trash2, XCircle } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { MeetingMetadata, StoredTranscript } from '@/services/indexedDBService';
import { cn } from '@/lib/utils';
import { useI18n } from '@/i18n';
import { toast } from 'sonner';
import { ConfirmationModal } from '@/components/confirmation-model/confirmation-modal';

interface TranscriptRecoveryProps {
  isOpen: boolean;
  onClose: () => void;
  recoverableMeetings: MeetingMetadata[];
  onRecover: (meetingId: string) => Promise<any>;
  onDelete: (meetingId: string) => Promise<void>;
  onLoadPreview: (meetingId: string) => Promise<StoredTranscript[]>;
}

export function TranscriptRecovery({
  isOpen,
  onClose,
  recoverableMeetings,
  onRecover,
  onDelete,
  onLoadPreview,
}: TranscriptRecoveryProps) {
  const [selectedMeetingId, setSelectedMeetingId] = useState<string | null>(null);
  const [previewTranscripts, setPreviewTranscripts] = useState<StoredTranscript[]>([]);
  const [isLoadingPreview, setIsLoadingPreview] = useState(false);
  const [isRecovering, setIsRecovering] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [isDeleteConfirmOpen, setIsDeleteConfirmOpen] = useState(false);
  const { t, locale } = useI18n();

  const formatRelative = (timestamp: number | string | Date) => {
    const diffMs = Date.now() - new Date(timestamp).getTime();
    const minutes = Math.floor(diffMs / 60000);
    if (!Number.isFinite(minutes) || minutes < 1) return t('common.time.justNow');
    if (minutes < 60) return t('common.time.minutesAgo', { n: minutes });
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return t('common.time.hoursAgo', { n: hours });
    return t('common.time.daysAgo', { n: Math.floor(hours / 24) });
  };

  // Reset selection when dialog opens
  useEffect(() => {
    if (isOpen) {
      setSelectedMeetingId(null);
      setPreviewTranscripts([]);
    }
  }, [isOpen]);

  // Auto-select first meeting if available
  useEffect(() => {
    if (isOpen && recoverableMeetings.length > 0 && !selectedMeetingId) {
      handleMeetingSelect(recoverableMeetings[0].meetingId);
    }
  }, [isOpen, recoverableMeetings]);

  const handleMeetingSelect = async (meetingId: string) => {
    setSelectedMeetingId(meetingId);
    setIsLoadingPreview(true);

    try {
      const transcripts = await onLoadPreview(meetingId);
      // Limit to first 10 for preview
      setPreviewTranscripts(transcripts.slice(0, 10));
    } catch (error) {
      console.error('Failed to load preview:', error);
      setPreviewTranscripts([]);
    } finally {
      setIsLoadingPreview(false);
    }
  };

  const handleRecover = async () => {
    if (!selectedMeetingId) return;

    setIsRecovering(true);
    try {
      const result = await onRecover(selectedMeetingId);
      console.log('Recovery successful:', result);
      onClose();
    } catch (error) {
      console.error('Recovery failed:', error);
      toast.error(t('dialogs.recovery.recoverFailed'));
    } finally {
      setIsRecovering(false);
    }
  };

  const handleDelete = () => {
    if (!selectedMeetingId) return;
    setIsDeleteConfirmOpen(true);
  };

  const handleDeleteConfirmed = async () => {
    setIsDeleteConfirmOpen(false);
    if (!selectedMeetingId) return;

    setIsDeleting(true);
    try {
      await onDelete(selectedMeetingId);
      setSelectedMeetingId(null);
      setPreviewTranscripts([]);
    } catch (error) {
      console.error('Delete failed:', error);
      toast.error(t('dialogs.recovery.deleteFailed'));
    } finally {
      setIsDeleting(false);
    }
  };

  const selectedMeeting = recoverableMeetings.find(m => m.meetingId === selectedMeetingId);

  return (
    <>
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-4xl h-[80vh] flex flex-col gap-0 p-0 rounded-xl sm:rounded-xl border-border bg-card shadow-elevated">
        <DialogHeader className="px-6 pt-6 pb-4">
          <DialogTitle className="text-xl font-semibold">{t('dialogs.recovery.title')}</DialogTitle>
          <DialogDescription>
            {t('dialogs.recovery.description', { count: recoverableMeetings.length })}
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 flex gap-4 px-6 pb-6 overflow-hidden">
          {/* Meeting List */}
          <div className="w-1/3 flex flex-col">
            <h3 className="text-xs font-medium text-muted-foreground mb-2">{t('dialogs.recovery.listTitle')}</h3>
            <ScrollArea className="flex-1 border border-border rounded-xl">
              <div className="p-2 space-y-2">
                {recoverableMeetings.map((meeting) => (
                  <button
                    key={meeting.meetingId}
                    onClick={() => handleMeetingSelect(meeting.meetingId)}
                    className={cn(
                      'w-full text-left p-3 rounded-lg border transition-colors',
                      selectedMeetingId === meeting.meetingId
                        ? 'bg-accent text-accent-foreground border-primary'
                        : 'hover:bg-muted border-transparent'
                    )}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-sm truncate" title={meeting.title}>{meeting.title}</p>
                        <p className="text-xs text-muted-foreground flex items-center gap-1 mt-1">
                          <Clock className="w-3 h-3" />
                          {formatRelative(meeting.lastUpdated)}
                        </p>
                        <p className="text-xs text-muted-foreground flex items-center gap-1 mt-1">
                          <FileText className="w-3 h-3" />
                          {t('dialogs.recovery.transcriptCount', { count: meeting.transcriptCount })}
                        </p>
                      </div>
                      {meeting.folderPath ? (
                        <span title={t('dialogs.recovery.audioAvailable')}>
                          <CheckCircle2 className="w-4 h-4 text-success flex-shrink-0" />
                        </span>
                      ) : (
                        <span title={t('dialogs.recovery.noAudio')}>
                          <AlertCircle className="w-4 h-4 text-warning flex-shrink-0" />
                        </span>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </ScrollArea>
          </div>

          {/* Preview Panel */}
          <div className="flex-1 flex flex-col">
            <h3 className="text-xs font-medium text-muted-foreground mb-2">{t('dialogs.recovery.previewTitle')}</h3>
            <div className="flex-1 border border-border rounded-xl overflow-hidden flex flex-col">
              {selectedMeeting ? (
                <>
                  {/* Meeting Info */}
                  <div className="p-4 border-b border-border bg-muted/50">
                    <h4 className="font-semibold break-words">{selectedMeeting.title}</h4>
                    <p className="text-xs text-muted-foreground mt-1">
                      {t('dialogs.recovery.startedAt', { time: new Date(selectedMeeting.startTime).toLocaleString(locale) })}
                    </p>
                    <div className="flex items-center gap-4 mt-2 text-sm">
                      <span className="flex items-center gap-1">
                        <FileText className="w-4 h-4" />
                        {t('dialogs.recovery.transcriptCount', { count: selectedMeeting.transcriptCount })}
                      </span>
                      {selectedMeeting.folderPath ? (
                        <span className="inline-flex items-center gap-1 rounded-full bg-success/10 px-2 py-0.5 text-xs text-success">
                          <CheckCircle2 className="w-4 h-4" />
                          {t('dialogs.recovery.audioAvailable')}
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 rounded-full bg-warning/10 px-2 py-0.5 text-xs text-warning">
                          <AlertCircle className="w-4 h-4" />
                          {t('dialogs.recovery.noAudio')}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Transcript Preview */}
                  <ScrollArea className="flex-1 p-4">
                    {isLoadingPreview ? (
                      <div className="flex items-center justify-center h-full text-muted-foreground">
                        {t('dialogs.recovery.loadingPreview')}
                      </div>
                    ) : previewTranscripts.length > 0 ? (
                      <div className="space-y-3">
                        <Alert>
                          <AlertDescription>
                            {t('dialogs.recovery.previewShowing', { shown: previewTranscripts.length, total: selectedMeeting.transcriptCount })}
                          </AlertDescription>
                        </Alert>
                        {previewTranscripts.map((transcript, index) => {
                          // Handle different timestamp formats
                          const getTimestamp = () => {
                            if (!transcript.timestamp) return '--:--';
                            try {
                              const date = new Date(transcript.timestamp);
                              if (isNaN(date.getTime())) {
                                // If timestamp is invalid, try audio_start_time
                                if (transcript.audio_start_time !== undefined) {
                                  const totalSecs = Math.floor(transcript.audio_start_time);
                                  const mins = Math.floor(totalSecs / 60);
                                  const secs = totalSecs % 60;
                                  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
                                }
                                return '--:--';
                              }
                              return date.toLocaleTimeString(locale);
                            } catch {
                              return '--:--';
                            }
                          };

                          return (
                            <div key={index} className="text-sm">
                              <span className="text-muted-foreground">[{getTimestamp()}]</span>{' '}
                              <span>{transcript.text}</span>
                            </div>
                          );
                        })}
                        {selectedMeeting.transcriptCount > 10 && (
                          <p className="text-sm text-muted-foreground italic">
                            {t('dialogs.recovery.moreTranscripts', { count: selectedMeeting.transcriptCount - 10 })}
                          </p>
                        )}
                      </div>
                    ) : (
                      <div className="flex items-center justify-center h-full text-muted-foreground">
                        {t('dialogs.recovery.noTranscripts')}
                      </div>
                    )}
                  </ScrollArea>
                </>
              ) : (
                <div className="flex items-center justify-center h-full text-muted-foreground">
                  {t('dialogs.recovery.selectMeeting')}
                </div>
              )}
            </div>
          </div>
        </div>

        <DialogFooter className="px-6 py-4 border-t border-border gap-3">
          <Button
            variant="outline"
            className="rounded-lg"
            onClick={onClose}
            disabled={isRecovering || isDeleting}
          >
            {t('common.actions.cancel')}
          </Button>
          <Button
            variant="destructive"
            onClick={handleDelete}
            disabled={!selectedMeetingId || isRecovering || isDeleting}
          >
            {isDeleting ? (
              <>
                <XCircle className="w-4 h-4 mr-2 animate-spin" />
                {t('dialogs.recovery.deleting')}
              </>
            ) : (
              <>
                <Trash2 className="w-4 h-4 mr-2" />
                {t('common.actions.delete')}
              </>
            )}
          </Button>
          <Button
            onClick={handleRecover}
            disabled={!selectedMeetingId || isRecovering || isDeleting}
          >
            {isRecovering ? (
              <>
                <CheckCircle2 className="w-4 h-4 mr-2 animate-spin" />
                {t('dialogs.recovery.recovering')}
              </>
            ) : (
              <>
                <CheckCircle2 className="w-4 h-4 mr-2" />
                {t('dialogs.recovery.recover')}
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
    <ConfirmationModal
      isOpen={isDeleteConfirmOpen}
      text={t('dialogs.recovery.deleteConfirm')}
      onConfirm={handleDeleteConfirmed}
      onCancel={() => setIsDeleteConfirmOpen(false)}
    />
    </>
  );
}
