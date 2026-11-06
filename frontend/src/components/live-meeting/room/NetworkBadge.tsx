'use client';
import { useState } from 'react';
import { Signal } from 'lucide-react';
import type { NetworkSample } from '@/services/live-meeting/media/types';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogTitle,
} from '@/components/ui/dialog';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

export default function NetworkBadge({
  sample,
  local,
  connected,
}: {
  sample?: NetworkSample;
  local: boolean;
  connected: boolean;
}) {
  const t = useT(),
    [open, setOpen] = useState(false);
  const measured = connected && sample && Date.now() - sample.sampledAt < 5000;
  const quality = measured
    ? (sample.rttMs ?? 0) > 500 || (sample.lossPercent ?? 0) > 5
      ? 'poor'
      : (sample.rttMs ?? 0) > 200 || (sample.lossPercent ?? 0) > 2
        ? 'fair'
        : 'good'
    : 'unknown';
  const title = t(`liveMeeting.room.network.${quality}`);
  return (
    <>
      <button
        type="button"
        className="absolute left-2 top-2 rounded bg-black/35 px-1.5 py-1 opacity-60 backdrop-blur-sm transition-opacity hover:opacity-100 focus-visible:opacity-100"
        title={title}
        aria-label={title}
        onKeyDown={(e) => e.stopPropagation()}
        onClick={(e) => {
          e.stopPropagation();
          setOpen(true);
        }}
      >
        <Signal
          className={cn(
            'h-3 w-3',
            quality === 'unknown'
              ? 'text-gray-400'
              : quality === 'poor'
                ? 'text-red-400'
                : quality === 'fair'
                  ? 'text-amber-400'
                  : 'text-green-400',
          )}
          strokeWidth={2.4}
        />
      </button>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent
          onClick={(e) => e.stopPropagation()}
          className="w-[calc(100%-2rem)] max-w-sm bg-[#151A26]"
        >
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>
            {t('liveMeeting.room.network.scope')}
          </DialogDescription>
          <p className="text-sm">
            {t(
              local
                ? 'liveMeeting.room.network.send'
                : 'liveMeeting.room.network.receive',
            )}
          </p>
          <dl className="space-y-2 text-sm">
            <div className="flex justify-between">
              <dt>RTT</dt>
              <dd>
                {measured && sample.rttMs !== undefined
                  ? `${sample.rttMs.toFixed(0)} ms`
                  : '—'}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt>{t('liveMeeting.room.network.loss')}</dt>
              <dd>
                {measured && sample.lossPercent !== undefined
                  ? `${sample.lossPercent.toFixed(1)}%`
                  : '—'}
              </dd>
            </div>
          </dl>
        </DialogContent>
      </Dialog>
    </>
  );
}
