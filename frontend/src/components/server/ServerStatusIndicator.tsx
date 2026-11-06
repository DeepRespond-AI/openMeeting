'use client';

import React, { useState } from 'react';
import { AlertTriangle, Loader2 } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '@/components/ui/tooltip';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { describeServerProblem } from '@/lib/server';

/**
 * Sidebar warning shown only while the service cannot be used (offline, or speech recognition /
 * summaries unavailable). Nothing is rendered when everything works: service details are not
 * shown to users. Clicking re-checks.
 */
export function ServerStatusIndicator({ isCollapsed }: { isCollapsed: boolean }) {
  const t = useT();
  const { status, isUsable, isLoading, refresh } = useServer();
  const [checking, setChecking] = useState(false);
  const caps = status?.capabilities ?? null;
  const degraded = isUsable && !!caps && (!caps.stt.ready || !caps.llm.ready);

  // Wait for the first real status; a missing session is handled by the login screen.
  if (isLoading || !status || !status.loggedIn || (isUsable && !degraded)) return null;

  const problem = isUsable
    ? describeServerProblem(status, caps && !caps.stt.ready ? 'stt' : 'llm')
    : describeServerProblem(status);
  const label = status.connected ? t('server.status.unavailable') : t('server.status.offline');

  const recheck = async () => {
    setChecking(true);
    try {
      await refresh();
    } finally {
      setChecking(false);
    }
  };

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <button
            type="button"
            onClick={() => void recheck()}
            disabled={checking}
            className={cn(
              'flex min-w-0 items-center gap-2 rounded-lg px-2 py-1.5 text-xs font-medium text-warning transition-colors hover:bg-warning/10',
              isCollapsed ? 'justify-center' : 'flex-1 justify-start',
            )}
            aria-label={label}
          >
            {checking ? (
              <Loader2 className="h-3.5 w-3.5 shrink-0 animate-spin" />
            ) : (
              <AlertTriangle className="h-3.5 w-3.5 shrink-0" />
            )}
            {!isCollapsed && <span className="truncate">{label}</span>}
          </button>
        </TooltipTrigger>
        <TooltipContent side={isCollapsed ? 'right' : 'top'} className="max-w-xs">
          <div className="space-y-1 text-xs">
            {problem && <p>{problem}</p>}
            <p className="opacity-70">{t('server.tooltip.recheck')}</p>
          </div>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
