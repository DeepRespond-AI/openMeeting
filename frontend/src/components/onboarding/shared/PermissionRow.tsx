'use client';

import React from 'react';
import { CheckCircle2, Loader2, XCircle } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { Button } from '@/components/ui/button';
import type { PermissionRowProps } from '@/types/onboarding';

export function PermissionRow({ icon, title, description, status, isPending = false, onAction }: PermissionRowProps) {
  const t = useT();
  const isAuthorized = status === 'authorized';
  const isDenied = status === 'denied';
  const isChecking = isPending;

  const getButtonText = () => {
    if (isChecking) return t('onboarding.status.checking');
    if (isDenied) return t('onboarding.status.openSettings');
    return t('onboarding.status.enable');
  };

  return (
    <div
      className={cn(
        'flex items-center justify-between gap-3 rounded-xl border bg-card p-4 shadow-card transition-colors',
        isAuthorized ? 'border-success/40' : isDenied ? 'border-destructive/40 bg-destructive/5' : 'border-border',
      )}
    >
      {/* Left side: Icon + Info */}
      <div className="flex min-w-0 flex-1 items-center gap-3">
        <div
          className={cn(
            'flex size-10 shrink-0 items-center justify-center rounded-lg',
            isAuthorized
              ? 'bg-success/10 text-success'
              : isDenied
                ? 'bg-destructive/10 text-destructive'
                : 'bg-accent text-primary',
          )}
        >
          {icon}
        </div>

        <div className="min-w-0 flex-1">
          <div className="truncate text-sm font-semibold text-foreground" title={title}>
            {title}
          </div>
          <div className="text-xs text-muted-foreground">
            {isAuthorized ? (
              <span className="flex items-center gap-1 text-success">
                <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
                {t('onboarding.status.granted')}
              </span>
            ) : isDenied ? (
              <span className="flex items-center gap-1 text-destructive">
                <XCircle className="h-3.5 w-3.5 shrink-0" />
                {t('onboarding.status.denied')}
              </span>
            ) : (
              <span>{description}</span>
            )}
          </div>
        </div>
      </div>

      {/* Right side: Action button or checkmark */}
      <div className="flex shrink-0 items-center gap-2">
        {!isAuthorized && (
          <Button
            variant={isDenied ? 'destructive' : 'outline'}
            size="sm"
            onClick={onAction}
            disabled={isChecking}
            className="min-w-[88px] rounded-lg"
          >
            {isChecking && <Loader2 className="h-4 w-4 animate-spin" />}
            {getButtonText()}
          </Button>
        )}
        {isAuthorized && (
          <div className="flex size-8 items-center justify-center rounded-full bg-success/10">
            <CheckCircle2 className="h-4 w-4 text-success" />
          </div>
        )}
      </div>
    </div>
  );
}
