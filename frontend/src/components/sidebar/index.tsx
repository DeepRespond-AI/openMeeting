'use client';

import React, { useEffect } from 'react';
import { Home, Mic, NotebookPen, PanelLeftClose, PanelLeftOpen } from 'lucide-react';
import { useRouter, usePathname } from 'next/navigation';
import { useSidebar } from './SidebarProvider';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { useRecordingState } from '@/contexts/RecordingStateContext';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { ServerStatusIndicator } from '../server/ServerStatusIndicator';
import { AccountMenu } from '../auth/AccountMenu';

interface NavButtonProps {
  icon: React.ElementType;
  label: string;
  active?: boolean;
  collapsed: boolean;
  onClick: () => void;
  className?: string;
}

/** A primary-nav row; collapses to an icon with a tooltip. */
function NavButton({ icon: Icon, label, active, collapsed, onClick, className }: NavButtonProps) {
  const button = (
    <button
      type="button"
      onClick={onClick}
      aria-label={collapsed ? label : undefined}
      aria-current={active ? 'page' : undefined}
      className={cn(
        'flex items-center rounded-lg text-sm font-medium transition-colors',
        collapsed ? 'h-10 w-10 justify-center' : 'h-9 w-full gap-3 px-3',
        active
          ? 'bg-accent text-accent-foreground'
          : 'text-sidebar-foreground hover:bg-muted hover:text-foreground',
        className,
      )}
    >
      <Icon className={cn('shrink-0', collapsed ? 'h-5 w-5' : 'h-[18px] w-[18px]')} />
      {!collapsed && <span className="truncate">{label}</span>}
    </button>
  );

  if (!collapsed) return button;
  return (
    <Tooltip>
      <TooltipTrigger asChild>{button}</TooltipTrigger>
      <TooltipContent side="right">{label}</TooltipContent>
    </Tooltip>
  );
}

const Sidebar: React.FC = () => {
  const t = useT();
  const router = useRouter();
  const pathname = usePathname();
  const { isCollapsed, toggleCollapse, handleRecordingToggle } = useSidebar();

  // Recording state from RecordingStateContext (single source of truth)
  const { isRecording } = useRecordingState();

  // Expose openSettings to window for the Rust tray to call
  useEffect(() => {
    (window as any).openSettings = () => {
      router.push('/settings');
    };
    return () => {
      delete (window as any).openSettings;
    };
  }, []);

  const collapsed = isCollapsed;
  const isHomePage = pathname === '/';
  const isMeetingsPage = pathname === '/meetings' || !!pathname?.startsWith('/meeting-details');

  // Record button: starts a recording, or jumps back to the live recording.
  const handleRecordClick = () => {
    if (isRecording) {
      router.push('/');
    } else {
      handleRecordingToggle();
    }
  };
  const recordLabel = isRecording ? t('nav.primary.recordingInProgress') : t('nav.primary.newRecording');

  const recordButton = (
    <button
      type="button"
      onClick={handleRecordClick}
      aria-label={collapsed ? recordLabel : undefined}
      className={cn(
        'flex items-center justify-center rounded-lg text-sm font-semibold shadow-sm transition-colors',
        collapsed ? 'h-10 w-10' : 'h-10 w-full gap-2 px-3',
        isRecording
          ? 'bg-destructive/10 text-destructive hover:bg-destructive/15'
          : 'bg-primary text-primary-foreground hover:bg-primary/90',
      )}
    >
      {isRecording ? (
        <span className="relative flex h-2.5 w-2.5 shrink-0">
          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-destructive opacity-60" />
          <span className="relative inline-flex h-2.5 w-2.5 rounded-full bg-destructive" />
        </span>
      ) : (
        <Mic className={collapsed ? 'h-5 w-5' : 'h-4 w-4'} />
      )}
      {!collapsed && <span className="truncate">{recordLabel}</span>}
    </button>
  );

  return (
    <TooltipProvider delayDuration={200}>
      <aside
        aria-label={t('nav.sidebar.navigation')}
        className={cn(
          'fixed left-0 top-0 z-40 flex h-screen flex-col border-r border-border bg-sidebar transition-[width] duration-300',
          collapsed ? 'w-16' : 'w-64',
        )}
      >
        {/* Brand header */}
        <div className={cn('flex h-16 shrink-0 items-center', collapsed ? 'justify-center' : 'justify-between pl-4 pr-2')}>
          <button
            type="button"
            onClick={() => router.push('/')}
            title={t('nav.primary.home')}
            className="min-w-0 rounded-lg p-1 transition-opacity hover:opacity-80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <BrandLogo size={collapsed ? 32 : 36} showName={!collapsed} />
          </button>
          {!collapsed && (
            <Tooltip>
              <TooltipTrigger asChild>
                <button
                  type="button"
                  onClick={toggleCollapse}
                  aria-label={t('nav.sidebar.collapse')}
                  className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                >
                  <PanelLeftClose className="h-[18px] w-[18px]" />
                </button>
              </TooltipTrigger>
              <TooltipContent side="right">{t('nav.sidebar.collapse')}</TooltipContent>
            </Tooltip>
          )}
        </div>

        {/* Record button + menu (settings are in the account menu) */}
        <nav className={cn('flex shrink-0 flex-col gap-1', collapsed ? 'items-center px-3' : 'px-3')}>
          {collapsed ? (
            <Tooltip>
              <TooltipTrigger asChild>{recordButton}</TooltipTrigger>
              <TooltipContent side="right">{recordLabel}</TooltipContent>
            </Tooltip>
          ) : (
            recordButton
          )}
          <div className="h-2" />
          <NavButton icon={Home} label={t('nav.primary.home')} active={isHomePage} collapsed={collapsed} onClick={() => router.push('/')} />
          <NavButton
            icon={NotebookPen}
            label={t('nav.meetings.title')}
            active={isMeetingsPage}
            collapsed={collapsed}
            onClick={() => router.push('/meetings')}
          />
        </nav>

        <div className="flex-1" />

        {/* Signed-in account */}
        <div className={cn('shrink-0 border-t border-border p-2', collapsed && 'flex justify-center')}>
          <AccountMenu collapsed={collapsed} />
        </div>

        {/* Footer: service warning (only when there is a problem) and, when collapsed, the expand
            button. Language and About live in Settings. Hidden when empty. */}
        <div
          className={cn(
            'flex shrink-0 border-t border-border p-2 empty:hidden',
            collapsed ? 'flex-col items-center gap-1' : 'items-center gap-1',
          )}
        >
          <ServerStatusIndicator isCollapsed={collapsed} />
          {collapsed && (
            <Tooltip>
              <TooltipTrigger asChild>
                <button
                  type="button"
                  onClick={toggleCollapse}
                  aria-label={t('nav.sidebar.expand')}
                  className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
                >
                  <PanelLeftOpen className="h-[18px] w-[18px]" />
                </button>
              </TooltipTrigger>
              <TooltipContent side="right">{t('nav.sidebar.expand')}</TooltipContent>
            </Tooltip>
          )}
        </div>
      </aside>

    </TooltipProvider>
  );
};

export default Sidebar;
