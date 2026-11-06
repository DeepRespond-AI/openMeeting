'use client';

import type { ReactNode } from 'react';
import { FileText, Info, Sparkles } from 'lucide-react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useT } from '@/i18n';

const TABS = [
  { value: 'info' as const, labelKey: 'meeting.split.infoTab' as const, icon: Info },
  { value: 'transcript' as const, labelKey: 'meeting.split.transcriptTab' as const, icon: FileText },
  { value: 'summary' as const, labelKey: 'meeting.split.summaryTab' as const, icon: Sparkles },
];

export type MeetingDetailsTab = 'info' | 'transcript' | 'summary';

interface MeetingDetailsTabsProps {
  /** Title, metadata, actions and the recording player. */
  info: ReactNode;
  transcript: ReactNode;
  summary: ReactNode;
  activeTab: MeetingDetailsTab;
  onTabChange: (tab: MeetingDetailsTab) => void;
}

/**
 * Meeting info / transcript / AI summary as tabs, one panel at a time. All panels stay mounted
 * (hidden when inactive): playback keeps running, and the summary editor's unsaved edits and
 * the transcript scroll position survive switching tabs.
 */
export function MeetingDetailsTabs({ info, transcript, summary, activeTab, onTabChange }: MeetingDetailsTabsProps) {
  const t = useT();
  const panelClass = 'mt-0 flex min-h-0 min-w-0 flex-1 flex-col data-[state=inactive]:hidden';

  return (
    <Tabs
      value={activeTab}
      onValueChange={(value) => onTabChange(value as MeetingDetailsTab)}
      className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden"
    >
      <TabsList className="mb-3 grid h-auto w-full max-w-full shrink-0 grid-cols-3 gap-1 rounded-lg bg-muted p-1 sm:inline-flex sm:w-fit">
        {TABS.map((tab) => {
          const Icon = tab.icon;
          return (
            <TabsTrigger
              key={tab.value}
              value={tab.value}
              className="flex min-w-0 items-center gap-1 rounded-md px-2 py-1.5 text-xs font-medium text-muted-foreground hover:text-foreground data-[state=active]:bg-card data-[state=active]:text-primary data-[state=active]:shadow-card sm:gap-2 sm:px-4 sm:text-sm"
            >
              <Icon className="hidden h-4 w-4 shrink-0 sm:block" />
              {t(tab.labelKey)}
            </TabsTrigger>
          );
        })}
      </TabsList>
      <TabsContent value="info" forceMount className={`${panelClass} custom-scrollbar gap-3 overflow-y-auto`}>
        {info}
      </TabsContent>
      <TabsContent value="transcript" forceMount className={panelClass}>
        {transcript}
      </TabsContent>
      <TabsContent value="summary" forceMount className={panelClass}>
        {summary}
      </TabsContent>
    </Tabs>
  );
}
