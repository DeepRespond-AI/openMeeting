/** Shared time helpers for the live-meeting scheduled surfaces. */
import type { ScheduledDisplayStatus, ScheduledMeeting } from './types';

/** A reservation's clock does not mean its current scene has started or ended. */
export function deriveScheduledStatus(m: ScheduledMeeting, now = new Date()): ScheduledDisplayStatus {
  if (m.cancelled) return 'past';
  if (m.activeRoomId) return 'ongoing';
  const start = new Date(m.startAt).getTime();
  if (now.getTime() < start) return 'upcoming';
  return 'past';
}

/** Day bounds as ISO strings for `listScheduledMeetings` range queries. */
export function dayRange(day = new Date()): { from: string; to: string } {
  const from = new Date(day);
  from.setHours(0, 0, 0, 0);
  const to = new Date(day);
  to.setHours(23, 59, 59, 999);
  return { from: from.toISOString(), to: to.toISOString() };
}

/** HH:mm in the active locale (24-hour). */
export function formatTime(d: Date, locale: string): string {
  return new Intl.DateTimeFormat(locale, { hour: '2-digit', minute: '2-digit', hour12: false }).format(d);
}

/** "10月13日 周二" / "Tue, Oct 13" style label for the trigger button. */
export function formatDateLabel(d: Date, locale: string): string {
  return new Intl.DateTimeFormat(locale, { month: 'long', day: 'numeric', weekday: 'short' }).format(d);
}
