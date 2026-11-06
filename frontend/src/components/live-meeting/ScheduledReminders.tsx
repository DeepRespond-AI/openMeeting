'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { invoke } from '@tauri-apps/api/core';
import { useServer } from '@/contexts/ServerContext';
import { getLiveMeetingApi } from '@/services/live-meeting';

/** Global while logged in, including rooms and details. Fetch afresh before notifying. */
export default function ScheduledReminders() {
  const { user, loggedIn } = useServer();
  const router = useRouter();
  useEffect(() => {
    if (!loggedIn || !user) return;
    let disposed = false, busy = false;
    const check = async () => {
      if (busy || disposed) return;
      busy = true;
      try {
        const now = Date.now();
        const rows = await getLiveMeetingApi().listScheduledMeetings({ from: new Date(now).toISOString(), to: new Date(now + 600001).toISOString() });
        if (disposed) return;
        for (const row of rows) {
          if (!row.remind || row.cancelled || row.activeRoomId || Date.parse(row.startAt) <= Date.now()) continue;
          const key = `meeting-reminder:${user.id}:${row.id}:${row.startAt}`;
          try { if (localStorage.getItem(key)) continue; } catch { /* in-memory set below still deduplicates */ }
          if (sent.has(key)) continue;
          sent.add(key);
          try { localStorage.setItem(key, String(Date.now())); } catch { /* storage unavailable */ }
          toast('会议即将开始', { description: row.title, duration: 15000, action: { label: '加入会议', onClick: () => router.push(`/room?code=${row.code}`) } });
          // Existing manager applies consent, system permission, DND and reminder preferences.
          void invoke('show_notification', { notification: { id: key, title: '会议即将开始', body: row.title,
            notification_type: { MeetingReminder: 10 }, priority: 'Normal', timeout: 'Default',
            icon: null, sound: true, actions: [] } }).catch(() => {});
        }
      } catch { /* keep retrying after the service returns; never send stale reminders */ }
      finally { busy = false; }
    };
    void check();
    const timer = window.setInterval(() => void check(), 15000);
    const wake = () => { void check(); };
    window.addEventListener('focus', wake);
    document.addEventListener('visibilitychange', wake);
    window.addEventListener('scheduled-meetings-changed', wake);
    return () => { disposed = true; clearInterval(timer); window.removeEventListener('focus', wake); document.removeEventListener('visibilitychange', wake); window.removeEventListener('scheduled-meetings-changed', wake); };
  }, [loggedIn, user?.id, router]);
  return null;
}
const sent = new Set<string>();
