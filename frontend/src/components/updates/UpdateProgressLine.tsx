'use client'

import { Progress } from '@/components/ui/progress';
import { useT } from '@/i18n';
import type { UpdateProgress } from '@/services/updateService';

/** Download progress of an update (indeterminate until the size is known). */
export function UpdateProgressLine({ progress }: { progress: UpdateProgress | null }) {
  const t = useT();
  const percent = progress?.percentage ?? null;
  return (
    <div className="space-y-1.5">
      <Progress value={percent ?? 0} className={percent === null ? 'animate-pulse' : undefined} />
      <p className="text-xs text-muted-foreground">
        {percent === null ? t('update.progress.downloadingUnknown') : t('update.progress.downloading', { percent })}
      </p>
    </div>
  );
}
