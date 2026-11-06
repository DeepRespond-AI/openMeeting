'use client';

import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { AlignJustify, ChevronRight, FileText, LayoutGrid, Loader2, MoreHorizontal, NotebookPen, Pencil, Search, Trash2, X } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { invoke } from '@tauri-apps/api/core';
import { toast } from 'sonner';
import { useSidebar } from '@/components/sidebar/SidebarProvider';
import type { CurrentMeeting } from '@/components/sidebar/SidebarProvider';
import { ConfirmationModal } from '@/components/confirmation-model/confirmation-modal';
import Analytics from '@/lib/analytics';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { LimitedInput } from '@/components/ui/limited-input';
import { MEETING_TITLE_MAX, textLength } from '@/lib/field-limits';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';

interface MeetingItem {
  id: string;
  title: string;
}

type ViewMode = 'list' | 'card';

const VIEW_MODE_STORAGE_KEY = 'dr.meetings.viewMode';

function readViewMode(): ViewMode {
  try {
    return window.localStorage?.getItem(VIEW_MODE_STORAGE_KEY) === 'card' ? 'card' : 'list';
  } catch {
    return 'list';
  }
}

/** Meetings from the server have ids like "meeting-<uuid>"; "intro-call" is the home placeholder. */
const isMeetingId = (id: string) => id.includes('-') && !id.startsWith('intro-call');

const meetingPath = (id: string) => (id.startsWith('intro-call') ? '/' : `/meeting-details?id=${id}`);

/**
 * The meeting list page (sidebar → 会议记录): search by title or transcript content, open,
 * rename and delete meetings.
 */
export function MeetingList() {
  const t = useT();
  const router = useRouter();
  const {
    currentMeeting,
    setCurrentMeeting,
    sidebarItems,
    searchTranscripts,
    searchResults,
    isSearching,
    meetings,
    setMeetings,
  } = useSidebar();
  const [searchQuery, setSearchQuery] = useState('');
  const [viewMode, setViewMode] = useState<ViewMode>('list');
  const [renameState, setRenameState] = useState<{ meetingId: string | null; title: string }>({ meetingId: null, title: '' });
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [renaming, setRenaming] = useState(false);

  // List/card view mode, remembered locally
  useEffect(() => {
    setViewMode(readViewMode());
  }, []);

  const toggleViewMode = (mode: ViewMode) => {
    setViewMode(mode);
    try {
      window.localStorage?.setItem(VIEW_MODE_STORAGE_KEY, mode);
    } catch {
      /* storage unavailable */
    }
  };

  // Filter titles locally and search transcripts on the server.
  const handleSearchChange = useCallback(async (value: string) => {
    setSearchQuery(value);
    if (!value.trim()) return;
    await searchTranscripts(value);
  }, [searchTranscripts]);

  const meetingItems = useMemo<MeetingItem[]>(
    () => sidebarItems.find((item) => item.id === 'meetings')?.children ?? [],
    [sidebarItems],
  );

  const filteredItems = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    if (!query) return meetingItems;
    const matched = new Set(searchResults.map((result) => result.id));
    return meetingItems.filter((item) => matched.has(item.id) || item.title.toLowerCase().includes(query));
  }, [meetingItems, searchQuery, searchResults]);

  const matchingSnippet = (itemId: string) => {
    if (!searchQuery.trim() || !searchResults.length) return null;
    return searchResults.find((result) => result.id === itemId) ?? null;
  };

  const openMeeting = (item: MeetingItem) => {
    setCurrentMeeting({ id: item.id, title: item.title });
    router.push(meetingPath(item.id));
  };

  const handleDelete = async (meetingId: string) => {
    try {
      await invoke('api_delete_meeting', { meetingId });
      setMeetings(meetings.filter((m: CurrentMeeting) => m.id !== meetingId));
      Analytics.trackMeetingDeleted(meetingId);
      toast.success(t('nav.meetings.deleted'), { description: t('nav.meetings.deletedDescription') });
      if (currentMeeting?.id === meetingId) {
        setCurrentMeeting({ id: 'intro-call', title: '+ New Call' });
      }
    } catch (error) {
      console.error('Failed to delete meeting:', error);
      toast.error(t('nav.meetings.deleteFailed'), {
        description: error instanceof Error ? error.message : String(error),
      });
    }
  };

  const closeRename = () => setRenameState({ meetingId: null, title: '' });

  const confirmRename = async () => {
    const meetingId = renameState.meetingId;
    const title = renameState.title.trim();
    if (!meetingId || renaming) return;
    if (textLength(title) > MEETING_TITLE_MAX) {
      toast.error(t('common.errors.textTooLong', { max: MEETING_TITLE_MAX }));
      return;
    }
    if (!title) {
      toast.error(t('nav.meetings.titleEmpty'));
      return;
    }
    setRenaming(true);
    try {
      await invoke('api_save_meeting_title', { meetingId, title });
      setMeetings(meetings.map((m: CurrentMeeting) => (m.id === meetingId ? { ...m, title } : m)));
      if (currentMeeting?.id === meetingId) setCurrentMeeting({ id: meetingId, title });
      Analytics.trackButtonClick('edit_meeting_title', 'meeting_list');
      toast.success(t('nav.meetings.renamed'));
      closeRename();
    } catch (error) {
      console.error('Failed to update meeting title:', error);
      toast.error(t('nav.meetings.renameFailed'), {
        description: error instanceof Error ? error.message : String(error),
      });
    } finally {
      setRenaming(false);
    }
  };

  /** Row/card actions: rename + delete (list and card views share it). */
  const renderActions = (item: MeetingItem) => {
    if (!isMeetingId(item.id) || meetings.find(meeting => meeting.id === item.id)?.can_manage === false) return null;
    return (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button
            type="button"
            onClick={(e) => e.stopPropagation()}
            aria-label={t('nav.meetings.moreActions')}
            className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-card hover:text-foreground"
          >
            <MoreHorizontal className="h-4 w-4" />
          </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-40" onClick={(e) => e.stopPropagation()}>
          <DropdownMenuItem onSelect={() => setRenameState({ meetingId: item.id, title: item.title })}>
            <Pencil className="mr-2 h-4 w-4" />
            {t('nav.meetings.rename')}
          </DropdownMenuItem>
          <DropdownMenuSeparator />
          <DropdownMenuItem
            onSelect={() => setDeleteId(item.id)}
            className="text-destructive focus:bg-destructive/10 focus:text-destructive"
          >
            <Trash2 className="mr-2 h-4 w-4" />
            {t('nav.meetings.delete')}
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    );
  };

  return (
    <div className="flex h-full min-h-0 flex-col bg-background">
      {/* Page header */}
      <div className="shrink-0 border-b border-border">
        <div className="mx-auto flex max-w-5xl flex-wrap items-end justify-between gap-4 px-6 py-5">
          <div className="min-w-0">
            <h1 className="flex items-center gap-2 text-xl font-semibold text-foreground">
              {t('nav.meetings.title')}
              {meetingItems.length > 0 && (
                <span className="rounded-full bg-muted px-2 py-0.5 text-xs font-medium text-muted-foreground tabular-nums">
                  {meetingItems.length}
                </span>
              )}
            </h1>
            <p className="mt-0.5 text-sm text-muted-foreground">{t('nav.meetings.pageDescription')}</p>
          </div>
          <div className="flex w-full items-center gap-2 sm:w-auto">
            <div className="relative w-full sm:w-80">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={searchQuery}
                onChange={(e) => handleSearchChange(e.target.value)}
                placeholder={t('nav.meetings.searchPlaceholder')}
                className="h-9 bg-card pl-9 pr-9"
              />
              {searchQuery && isSearching ? (
                <Loader2 className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-primary" aria-label={t('nav.meetings.searching')} />
              ) : (
                searchQuery && (
                  <button
                    type="button"
                    onClick={() => handleSearchChange('')}
                    aria-label={t('nav.meetings.clearSearch')}
                    className="absolute right-2 top-1/2 flex h-6 w-6 -translate-y-1/2 items-center justify-center rounded text-muted-foreground hover:bg-muted hover:text-foreground"
                  >
                    <X className="h-4 w-4" />
                  </button>
                )
              )}
            </div>
            {/* List / card view toggle */}
            <div className="flex shrink-0 items-center gap-0.5 rounded-lg border border-border bg-card p-0.5">
              {([
                { mode: 'list' as ViewMode, icon: AlignJustify, label: t('nav.meetings.viewList') },
                { mode: 'card' as ViewMode, icon: LayoutGrid, label: t('nav.meetings.viewCard') },
              ]).map(({ mode, icon: Icon, label }) => (
                <button
                  key={mode}
                  type="button"
                  onClick={() => toggleViewMode(mode)}
                  aria-label={label}
                  aria-pressed={viewMode === mode}
                  title={label}
                  className={cn(
                    'flex h-8 w-8 items-center justify-center rounded-md transition-colors',
                    viewMode === mode
                      ? 'bg-accent text-primary'
                      : 'text-muted-foreground hover:bg-muted hover:text-foreground',
                  )}
                >
                  <Icon className="h-4 w-4" />
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* List */}
      <div className="custom-scrollbar min-h-0 flex-1 overflow-y-auto">
        <div className="mx-auto max-w-5xl px-6 py-5">
          {filteredItems.length > 0 ? (
            viewMode === 'card' ? (
              <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                {filteredItems.map((item) => {
                  const match = matchingSnippet(item.id);
                  return (
                    <div
                      key={item.id}
                      role="button"
                      tabIndex={0}
                      title={item.title}
                      onClick={() => openMeeting(item)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault();
                          openMeeting(item);
                        }
                      }}
                      className="group flex cursor-pointer flex-col gap-3 rounded-xl border border-border bg-card p-4 shadow-card outline-none transition-all duration-200 hover:-translate-y-0.5 hover:border-brand-300/40 hover:shadow-elevated focus-visible:bg-muted/60"
                    >
                      <div className="flex items-start gap-3">
                        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-accent">
                          <FileText className="h-4 w-4 text-primary" />
                        </div>
                        <p className="min-w-0 flex-1 truncate pt-1.5 text-sm font-medium text-foreground">{item.title}</p>
                        {renderActions(item)}
                      </div>
                      {match && (
                        <p className="line-clamp-2 rounded-md bg-warning/10 px-2 py-1 text-xs text-muted-foreground">
                          <span className="font-medium text-foreground">{t('nav.meetings.match')}</span> {match.matchContext}
                        </p>
                      )}
                    </div>
                  );
                })}
              </div>
            ) : (
            <ul className="divide-y divide-border overflow-hidden rounded-xl border border-border bg-card shadow-card">
              {filteredItems.map((item) => {
                const isMeeting = isMeetingId(item.id);
                const match = isMeeting ? matchingSnippet(item.id) : null;
                return (
                  <li key={item.id}>
                    <div
                      role="button"
                      tabIndex={0}
                      title={item.title}
                      onClick={() => openMeeting(item)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault();
                          openMeeting(item);
                        }
                      }}
                      className="group flex cursor-pointer items-center gap-3 px-5 py-4 outline-none transition-colors hover:bg-muted/60 focus-visible:bg-muted/60"
                    >
                      <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-accent">
                        <FileText className="h-4 w-4 text-primary" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-medium text-foreground">{item.title}</p>
                        {match && (
                          <p className="mt-1 line-clamp-2 rounded-md bg-warning/10 px-2 py-1 text-xs text-muted-foreground">
                            <span className="font-medium text-foreground">{t('nav.meetings.match')}</span> {match.matchContext}
                          </p>
                        )}
                      </div>
                      {renderActions(item)}
                      <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground" />
                    </div>
                  </li>
                );
              })}
            </ul>
            )
          ) : (
            <div className="flex flex-col items-center px-4 py-16 text-center">
              <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-accent">
                <NotebookPen className="h-6 w-6 text-primary" />
              </div>
              {searchQuery.trim() ? (
                <p className="break-words text-sm text-muted-foreground">{t('nav.meetings.noResults', { query: searchQuery.trim() })}</p>
              ) : (
                <>
                  <p className="text-base font-medium text-foreground">{t('nav.meetings.emptyTitle')}</p>
                  <p className="mt-1 text-sm text-muted-foreground">{t('nav.meetings.emptyDescription')}</p>
                </>
              )}
            </div>
          )}
        </div>
      </div>

      <ConfirmationModal
        isOpen={deleteId !== null}
        title={t('nav.meetings.deleteTitle')}
        text={t('nav.meetings.deleteConfirm')}
        onConfirm={() => {
          if (deleteId) void handleDelete(deleteId);
          setDeleteId(null);
        }}
        onCancel={() => setDeleteId(null)}
      />

      <Dialog open={renameState.meetingId !== null} onOpenChange={(open) => { if (!open && !renaming) closeRename(); }}>
        <DialogContent className="sm:max-w-[440px]">
          <DialogHeader>
            <DialogTitle>{t('nav.meetings.renameTitle')}</DialogTitle>
            <DialogDescription>{t('nav.meetings.renameDescription')}</DialogDescription>
          </DialogHeader>
          <div className="space-y-2">
            <Label htmlFor="meeting-title">{t('nav.meetings.titleLabel')}</Label>
            <LimitedInput
              id="meeting-title"
              maxLength={MEETING_TITLE_MAX}
              disabled={renaming}
              value={renameState.title}
              onChange={(e) => setRenameState((s) => ({ ...s, title: e.target.value }))}
              onKeyDown={(e) => {
                if (e.key === 'Enter') void confirmRename();
                else if (e.key === 'Escape') closeRename();
              }}
              placeholder={t('nav.meetings.titlePlaceholder')}
              autoFocus
            />
          </div>
          <DialogFooter>
            <Button variant="outline" disabled={renaming} onClick={closeRename}>{t('common.actions.cancel')}</Button>
            <Button disabled={renaming || !renameState.title.trim() || textLength(renameState.title.trim()) > MEETING_TITLE_MAX} onClick={() => void confirmRename()}>{renaming && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}{t('common.actions.save')}</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
