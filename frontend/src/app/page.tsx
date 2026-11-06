'use client';

import { useEffect, useRef, useState } from 'react';
import { Check, ChevronRight, Mic, NotebookPen, Plus, Zap } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { useSidebar } from '@/components/sidebar/SidebarProvider';
import { useServer } from '@/contexts/ServerContext';
import { useI18n } from '@/i18n';
import Analytics from '@/lib/analytics';
import { getLiveMeetingApi, getLiveMeetingDataSource, setLiveMeetingUser } from '@/services/live-meeting';
import JoinDialog from '@/components/live-meeting/JoinDialog';
import ScheduleDialog from '@/components/live-meeting/ScheduleDialog';
import TodayPanel from '@/components/live-meeting/TodayPanel';
import { useMeetingEntry } from '@/components/live-meeting/MeetingEntry';

/* ---------- Quick-entry cards (glass, per-card gradient chip) ---------- */
type QuickCardProps = {
  icon: React.ElementType;
  title: string;
  desc: string;
  chip: string;
  glow: string;
  onClick: () => void;
  disabled?: boolean;
};

function QuickCard({ icon: Icon, title, desc, chip, glow, onClick, disabled }: QuickCardProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className="group relative flex flex-col items-start gap-4 overflow-hidden rounded-2xl border border-white/[0.07] bg-white/[0.04] p-5 text-left backdrop-blur-md transition-all duration-300 hover:-translate-y-1 hover:border-white/[0.14] hover:bg-white/[0.07] hover:shadow-[0_18px_44px_rgba(0,0,0,0.45)] active:translate-y-0 active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-cyan/50"
    >
      {/* Hover brand glow */}
      <span
        className="pointer-events-none absolute -right-8 -top-8 h-28 w-28 rounded-full opacity-0 blur-2xl transition-opacity duration-300 group-hover:opacity-100"
        style={{ background: glow }}
        aria-hidden="true"
      />
      <span
        className="flex h-11 w-11 items-center justify-center rounded-xl text-white transition-transform duration-300 group-hover:scale-110"
        style={{ background: chip, boxShadow: `0 8px 20px ${glow}` }}
      >
        <Icon className="h-[22px] w-[22px]" />
      </span>
      <span className="min-w-0">
        <span className="block text-[15px] font-semibold text-foreground">{title}</span>
        <span className="mt-0.5 block text-xs text-muted-foreground">{desc}</span>
      </span>
    </button>
  );
}

/** V2 home dashboard: greeting hero, quick entries, today's scheduled meetings, recent notes. */
export default function Home() {
  const { t, locale } = useI18n();
  const router = useRouter();
  const { user } = useServer();
  const { meetings } = useSidebar();
  const { beginEntry, finishEntry } = useMeetingEntry();

  const [scheduleOpen, setScheduleOpen] = useState(false);
  const [joinOpen, setJoinOpen] = useState(false);
  const [joinCode, setJoinCode] = useState<string | null>(null);
  const [scheduleVersion, setScheduleVersion] = useState(0);
  const [creating, setCreating] = useState(false);
  const creatingRef = useRef(false);

  useEffect(() => {
    Analytics.trackPageView('home');
  }, []);

  // Keep the live-meeting data layer's self identity in sync with the logged-in user.
  useEffect(() => {
    setLiveMeetingUser(user ? { id: user.id, name: user.name } : null);
  }, [user]);

  /* Hero: time-based greeting + big date */
  const hour = new Date().getHours();
  const greeting = hour < 5
    ? t('home.greeting.lateNight')
    : hour < 9
      ? t('home.greeting.morning')
      : hour < 12
        ? t('home.greeting.forenoon')
        : hour < 14
          ? t('home.greeting.noon')
          : hour < 18
            ? t('home.greeting.afternoon')
            : t('home.greeting.evening');
  const now = new Date();
  const dateLabel = new Intl.DateTimeFormat(locale, { month: 'long', day: 'numeric' }).format(now);
  const weekLabel = new Intl.DateTimeFormat(locale, { weekday: 'long' }).format(now);
  const name = user?.name || '';

  /* Quick entries (live meetings wired) */
  const openJoin = (code: string | null) => {
    setJoinCode(code);
    setJoinOpen(true);
  };

  const startQuickMeeting = async () => {
    if (creatingRef.current) return;
    creatingRef.current = true;
    setCreating(true);
    beginEntry();
    try {
      const room = await getLiveMeetingApi().createRoom({});
      router.push(`/room?code=${room.code}`);
    } catch {
      finishEntry();
      toast.error(t('liveMeeting.join.errGeneric'));
    } finally {
      creatingRef.current = false;
      setCreating(false);
    }
  };

  const recents = meetings.slice(0, 5);

  return (
    <div className="flex h-full flex-col overflow-y-auto">
      <div className="mx-auto flex min-h-full w-full max-w-[1100px] flex-col px-4 pb-8 pt-6 sm:px-8 sm:pt-8 lg:px-10 lg:pt-10">

        {/* ===== Hero: greeting + date + actions ===== */}
        <div className="rise rise-1 flex shrink-0 flex-wrap items-end justify-between gap-4">
          <div>
            <p className="text-sm font-medium text-brand-cyan">
              {name ? t('home.hero.greetUser', { greeting, name }) : greeting}
            </p>
            <h1 className="mt-1.5 text-[36px] font-semibold leading-tight tracking-tight text-foreground">
              {dateLabel}
              <span className="ml-3 text-base font-normal text-muted-foreground">{weekLabel}</span>
            </h1>
          </div>
          <div className="flex shrink-0 items-center gap-2">
            <button
              type="button"
              onClick={() => router.push('/meetings')}
              className="inline-flex shrink-0 items-center gap-1 rounded-full border border-white/[0.08] bg-white/[0.05] px-4 py-1.5 text-sm text-foreground/75 backdrop-blur-md transition-all hover:bg-white/[0.1] hover:text-foreground"
            >
              {t('home.hero.allMeetings')}
              <ChevronRight className="h-3.5 w-3.5" />
            </button>
          </div>
        </div>

        {/* ===== Body: left column (quick entries + today) | right column (recent notes) ===== */}
        <div className="rise rise-2 mt-6 grid min-w-0 grid-cols-1 items-start gap-5 lg:mt-9 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]">

          {/* Left column: 2×2 quick entries + today's meetings */}
          <div className="flex min-w-0 w-full flex-col gap-5">

            <div className="grid shrink-0 grid-cols-2 gap-4">
              <QuickCard
                icon={Plus}
                title={t('home.quick.join')}
                desc={t('home.quick.joinDesc')}
                chip="linear-gradient(135deg,#6366f1,#3b82f6)"
                glow="rgba(99,102,241,0.5)"
                onClick={() => openJoin(null)}
              />
              <QuickCard
                icon={Zap}
                title={t('home.quick.quick')}
                desc={t('home.quick.quickDesc')}
                chip="linear-gradient(135deg,#3b82f6,#22d3ee)"
                glow="rgba(34,211,238,0.45)"
                onClick={() => void startQuickMeeting()}
                disabled={creating}
              />
              <QuickCard
                icon={Check}
                title={t('home.quick.schedule')}
                desc={t('home.quick.scheduleDesc')}
                chip="linear-gradient(135deg,#8b5cf6,#6366f1)"
                glow="rgba(139,92,246,0.5)"
                onClick={() => setScheduleOpen(true)}
              />
              <QuickCard
                icon={Mic}
                title={t('home.quick.record')}
                desc={t('home.quick.recordDesc')}
                chip="linear-gradient(135deg,#22d3ee,#34d399)"
                glow="rgba(52,211,153,0.45)"
                onClick={() => router.push('/record')}
              />
            </div>

            {/* Today's scheduled meetings */}
            <TodayPanel version={scheduleVersion} onJoin={(code) => {
              // The owner starts an unopened schedule through POST join. The
              // generic code precheck intentionally returns 404 before it starts.
              if (getLiveMeetingDataSource() === 'real') { beginEntry(); router.push(`/room?code=${code}`); }
              else openJoin(code);
            }} />
          </div>

          {/* Right column: recent meeting notes */}
          <section className="flex min-w-0 flex-1 flex-col">
            <div className="mb-3 flex shrink-0 items-center justify-between">
              <h2 className="text-[13px] font-medium text-muted-foreground">{t('home.recent.title')}</h2>
            </div>
            {recents.length ? (
              <div className="flex min-w-0 flex-col gap-2">
                {recents.map(m => (
                  <button
                    key={m.id}
                    type="button"
                    title={m.title}
                    onClick={() => router.push(`/meeting-details?id=${m.id}`)}
                    className="group flex items-center gap-3 rounded-xl border border-white/[0.05] bg-white/[0.03] px-4 py-3 text-left transition-all duration-200 hover:border-white/[0.1] hover:bg-white/[0.06]"
                  >
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-accent text-primary">
                      <NotebookPen className="h-4 w-4" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium text-foreground">{m.title}</p>
                    </div>
                    <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground/50 transition-all group-hover:translate-x-0.5 group-hover:text-foreground" />
                  </button>
                ))}
              </div>
            ) : (
              <p className="rounded-2xl border border-white/[0.06] bg-white/[0.03] px-5 py-4 text-sm text-muted-foreground">
                {t('home.recent.empty')}
              </p>
            )}
          </section>
        </div>

      </div>

      {/* Live-meeting dialogs */}
      <ScheduleDialog
        open={scheduleOpen}
        onOpenChange={setScheduleOpen}
        userName={name}
        onScheduled={() => setScheduleVersion((v) => v + 1)}
      />
      <JoinDialog
        open={joinOpen}
        onOpenChange={setJoinOpen}
        defaultName={name || 'Me'}
        initialCode={joinCode}
      />
    </div>
  );
}
