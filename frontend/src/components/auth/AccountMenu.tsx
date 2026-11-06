'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { ChevronsUpDown, LogOut, UserCog } from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { maskPhone } from '@/lib/phone';
import { SERVER_SETTINGS_ROUTE } from '@/lib/server';
import { ImUserAvatar as UserAvatar } from '@/components/im/ImUserAvatar';
import { LogoutDialog } from './LogoutDialog';

/** Sidebar footer: signed-in user with a small menu (account settings / sign out). */
export function AccountMenu({ collapsed }: { collapsed: boolean }) {
  const t = useT();
  const router = useRouter();
  const { user, loggedIn } = useServer();
  const [logoutOpen, setLogoutOpen] = useState(false);

  if (!loggedIn || !user) return null;
  const name = user.name || maskPhone(user.phone) || t('auth.account.signedInAccount');
  const phone = maskPhone(user?.phone);

  return (
    <>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <button
            type="button"
            aria-label={t('auth.menu.label')}
            title={collapsed ? name : undefined}
            className={cn(
              'flex min-w-0 items-center gap-2.5 rounded-lg text-left transition-colors hover:bg-accent focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/20',
              collapsed ? 'justify-center p-1' : 'w-full px-2 py-1.5',
            )}
          >
            <UserAvatar username={user.id} name={user?.name} size={collapsed ? 'sm' : 'md'} />
            {!collapsed && (
              <>
                <span className="min-w-0 flex-1 leading-tight">
                  <span className="block truncate text-sm font-medium text-foreground" title={name}>{name}</span>
                  {phone && <span className="block truncate text-xs text-muted-foreground">{phone}</span>}
                </span>
                <ChevronsUpDown className="h-4 w-4 shrink-0 text-muted-foreground" />
              </>
            )}
          </button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align={collapsed ? 'end' : 'start'} side={collapsed ? 'right' : 'top'} className="w-56">
          <DropdownMenuLabel className="flex items-center gap-2.5 font-normal">
            <UserAvatar username={user.id} name={user?.name} size="sm" />
            <span className="min-w-0 leading-tight">
              <span className="block truncate text-sm font-medium text-foreground">{name}</span>
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
    </>
  );
}
