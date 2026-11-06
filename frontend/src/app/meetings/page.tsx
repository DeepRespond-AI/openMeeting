'use client';

import { MeetingList } from '@/components/MeetingList';
import UpcomingMeetings from '@/components/live-meeting/UpcomingMeetings';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { useT } from '@/i18n';

/** 会议记录: the list of the user's meetings (opened from the sidebar). */
export default function MeetingsPage() {
  const t = useT();
  const triggerClass = 'rounded-none border-b-2 border-transparent px-0 py-4 data-[state=active]:border-primary data-[state=active]:bg-transparent data-[state=active]:shadow-none';
  return (
    <Tabs defaultValue="history" className="flex h-full min-h-0 min-w-0 flex-col">
      <div className="shrink-0 border-b border-border bg-background">
        <div className="mx-auto max-w-5xl px-6">
          <TabsList aria-label={t('nav.meetings.tabsLabel')} className="h-auto justify-start gap-6 rounded-none bg-transparent p-0">
            <TabsTrigger value="history" className={triggerClass}>{t('nav.meetings.historyTab')}</TabsTrigger>
            <TabsTrigger value="upcoming" className={triggerClass}>{t('nav.meetings.upcomingTab')}</TabsTrigger>
          </TabsList>
        </div>
      </div>
      <TabsContent value="history" forceMount className="mt-0 min-h-0 flex-1 data-[state=inactive]:hidden"><MeetingList /></TabsContent>
      <TabsContent value="upcoming" className="mt-0 min-h-0 flex-1"><UpcomingMeetings /></TabsContent>
    </Tabs>
  );
}
