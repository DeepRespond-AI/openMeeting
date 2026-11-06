import type { ConversationView, GroupView } from '@deeprespond/im-web';
import type { DRTauriEngineClient, EngineAlert } from '@deeprespond/im-tauri/engine';

/** Only service-owned, active meeting groups have a reachable chat panel. */
function isMeetingGroup(view: GroupView): boolean {
  const group = view.group;
  return view.in_my_groups && group.status === 'active' && group.type === 'private'
    && group.owner === 'openmeeting-meetings'
    && /^room-[A-Za-z0-9-]{1,75}$/.test(group.attributes?.openmeeting_room_id ?? '');
}

const chatTypes = new Set(['text', 'image', 'video', 'voice', 'file', 'location']);

/** Keep SDK focus, viewing, mute and sound throttling; narrow its auto alerts.
 * The global SDK unread total includes private/service chats, so the taskbar
 * badge is calculated separately from active meeting conversations only. */
export function createMeetingNotifications(client: DRTauriEngineClient) {
  let groups: ReturnType<typeof client.groups.list> | null = null;
  let offGroups: (() => void) | undefined;
  let disposed = false;
  let revision = 0;
  let running = false;
  let dirty = false;
  let lastBadge: number | null | undefined;

  const signedIn = () => !disposed && ['signed_in', 'suspended'].includes(client.auth.state.kind);
  const meetingGroups = () => signedIn() ? (groups?.getSnapshot().items ?? []).filter(isMeetingGroup) : [];

  async function updateBadge() {
    if (running) return;
    running = true;
    try {
      while (dirty) {
        dirty = false;
        const current = revision;
        try {
          // Clear the former global badge even if the first local read fails.
          if (lastBadge === undefined) {
            await client.desktop.setBadge(null);
            lastBadge = null;
          }
          // Read by group ID, rather than the paginated conversation window:
          // old private chats must neither contribute nor hide a meeting unread.
          const views = await Promise.all(meetingGroups().map(group => client.conversations.get(group.group_id)));
          if (current !== revision) continue;
          const total = views.reduce((sum, view) => sum + unread(view), 0);
          const badge = total > 0 ? total : null;
          if (badge !== lastBadge) {
            await client.desktop.setBadge(badge);
            lastBadge = badge;
          }
        } catch (error) {
          // Retry on the next SDK change; never substitute its unfiltered total.
          console.warn('[meeting notifications] Badge update failed', error);
        }
      }
    } finally { running = false; }
  }

  function scheduleBadge() {
    revision++;
    dirty = true;
    void updateBadge();
  }

  function bindGroups() {
    if (!signedIn()) {
      offGroups?.();
      offGroups = undefined;
      groups?.dispose();
      groups = null;
    } else if (!groups) {
      groups = client.groups.list();
      offGroups = groups.subscribe(scheduleBadge);
    }
    scheduleBadge();
  }

  const offs = [
    client.on('auth.stateChanged', bindGroups),
    client.on('conversations.changed', scheduleBadge),
    client.on('conversations.unreadChanged', scheduleBadge),
    client.on('push.changed', scheduleBadge),
  ];
  bindGroups();

  return {
    format(alert: EngineAlert): { title: string; body: string } | null {
      if (alert.kind !== 'message' || !signedIn()) return null;
      const m = alert.message;
      if (!alert.notify.notify || m.conversation_type !== 'group' || m.sender_type !== 'user'
        || !m.sender || m.sender === 'notice' || m.sender === 'openmeeting-meetings'
        || m.sender === client.auth.currentUser?.username || m.exclude_from_unread
        || m.recalled || m.erased || !chatTypes.has(m.type)
        || !meetingGroups().some(group => group.group_id === m.conversation_id)) return null;
      return { title: alert.notify.title ?? '', body: alert.notify.body ?? '' };
    },
    dispose() {
      disposed = true;
      offs.forEach(off => off());
      offGroups?.();
      groups?.dispose();
      groups = null;
      scheduleBadge();
    },
  };
}

function unread(view: ConversationView | undefined): number {
  if (!view || view.conversation_type !== 'group' || !view.state || view.state.membership !== 'member'
    || view.state.hidden || view.muted) return 0;
  return Math.max(0, view.unread_count);
}
