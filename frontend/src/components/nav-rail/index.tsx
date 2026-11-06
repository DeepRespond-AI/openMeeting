'use client';

import React, { useEffect, useState } from 'react';
import { Home, Mic, NotebookPen, LogOut, Settings, UserCog } from 'lucide-react';
import { usePathname, useRouter } from 'next/navigation';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { useRecordingState } from '@/contexts/RecordingStateContext';
import { useServer } from '@/contexts/ServerContext';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { maskPhone } from '@/lib/phone';
import { SERVER_SETTINGS_ROUTE } from '@/lib/server';
import { ImUserAvatar as UserAvatar } from '@/components/im/ImUserAvatar';
import { LogoutDialog } from '@/components/auth/LogoutDialog';

interface RailItemProps {
  icon: React.ElementType;
  label: string;
  active: boolean;
  /** Red pulse dot (recording in progress). */
  live?: boolean;
  onClick: () => void;
}

/** A 64px-rail nav tile: icon on top, tiny label below; active = brand gradient glow. */
function RailItem({ icon: Icon, label, active, live, onClick }: RailItemProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-current={active ? 'page' : undefined}
      title={label}
      className={cn(
        'relative flex h-[52px] w-[52px] flex-col items-center justify-center gap-1 rounded-xl transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
        active
          ? 'bg-brand-gradient text-white shadow-glow'
          : 'text-white/45 hover:bg-white/[0.07] hover:text-white',
      )}
    >
      <span className="relative">
        <Icon className="h-[18px] w-[18px]" />
        {live && (
          <span className="absolute -right-1 -top-0.5 flex h-2 w-2">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-destructive opacity-60" />
            <span className="relative inline-flex h-2 w-2 rounded-full bg-destructive" />
          </span>
        )}
      </span>
      <span className="text-[10px] leading-none">{label}</span>
    </button>
  );
}

/**
 * V2 shell: fixed 64px dark nav rail (Aurora Dark).
 * Logo top, primary nav (home / meetings / record / settings), gradient avatar
 * with account menu at the bottom. Replaces the old collapsible Sidebar
 * (src/components/Sidebar) while keeping `window.openSettings` for the tray.
 */
const NavRail: React.FC = () => {
  const t = useT();
  const router = useRouter();
  const pathname = usePathname();
  const { isRecording } = useRecordingState();
  const { user, loggedIn } = useServer();
  const [logoutOpen, setLogoutOpen] = useState(false);

  // Expose openSettings to window for the Rust tray to call
  useEffect(() => {
    (window as any).openSettings = () => {
      router.push('/settings');
    };
    return () => {
      delete (window as any).openSettings;
    };
  }, []);

  const isHome = pathname === '/';
  const isMeetings = pathname === '/meetings' || !!pathname?.startsWith('/meeting-details');
  const isRecord = pathname === '/record';
  const isSettings = pathname === '/settings';

  const name = user?.name || maskPhone(user?.phone) || t('auth.account.signedInAccount');
  const phone = maskPhone(user?.phone);

  return (
    <aside
      aria-label={t('nav.sidebar.navigation')}
      className="fixed left-0 top-0 z-40 flex h-dvh min-h-0 w-16 flex-col items-center border-r border-white/[0.05] bg-sidebar"
    >
      {/* Brand header */}
      <button
        type="button"
        onClick={() => router.push('/')}
        title={t('nav.primary.home')}
        aria-label={t('common.appName')}
        className="flex h-16 shrink-0 items-center justify-center transition-opacity hover:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
      >
        <BrandLogo size={34} />
      </button>

      {/* Primary nav */}
      <nav className="custom-scrollbar flex min-h-0 w-full flex-1 flex-col items-center gap-2 overflow-y-auto px-2 pb-2 [&>button]:shrink-0">
        <RailItem icon={Home} label={t('nav.primary.home')} active={isHome} onClick={() => router.push('/')} />
        <RailItem
          icon={NotebookPen}
          label={t('nav.meetings.title')}
          active={isMeetings}
          onClick={() => router.push('/meetings')}
        />
        <RailItem
          icon={Mic}
          label={t('nav.rail.record')}
          active={isRecord}
          live={isRecording}
          onClick={() => router.push('/record')}
        />
        <RailItem
          icon={Settings}
          label={t('nav.rail.settings')}
          active={isSettings}
          onClick={() => router.push('/settings')}
        />
      </nav>


      {/* Signed-in account (gradient avatar + menu); hidden when logged out */}
      {loggedIn && user && (
        <div className="flex shrink-0 flex-col items-center pb-4">
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <button
                type="button"
                aria-label={t('auth.menu.label')}
                title={name}
                className="rounded-full ring-1 ring-white/20 transition-transform hover:scale-105 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              >
                <UserAvatar username={user.id} name={user?.name} size="md" />
              </button>
            </DropdownMenuTrigger>
            <DropdownMenuContent side="right" align="end" className="w-56">
              <DropdownMenuLabel className="flex items-center gap-2.5 font-normal">
                <UserAvatar username={user.id} name={user?.name} size="sm" />
                <span className="min-w-0 leading-tight">
                  <span className="block truncate text-sm font-medium text-foreground" title={name}>{name}</span>
                  {phone && <span className="block truncate text-xs text-muted-foreground">{phone}</span>}
                </span>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem onSelect={() => router.push(SERVER_SETTINGS_ROUTE)}>
                <UserCog className="h-4 w-4" />
                {t('auth.menu.settings')}
              </DropdownMenuItem>
              <DropdownMenuItem
                onSelect={() => setLogoutOpen(true)}
                className="text-destructive focus:bg-destructive/10 focus:text-destructive"
              >
                <LogOut className="h-4 w-4" />
                {t('auth.menu.logout')}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
          <LogoutDialog open={logoutOpen} onOpenChange={setLogoutOpen} />
        </div>
      )}
    </aside>
  );
};

export default NavRail;
