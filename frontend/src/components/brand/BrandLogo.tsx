'use client';

import { cn } from '@/lib/utils';
import { useT } from '@/i18n';

// Intrinsic size of public/brand-logo.png.
const LOGO_WIDTH = 354;
const LOGO_HEIGHT = 220;

interface BrandLogoProps {
  /** Logo width in px; height follows the logo's aspect ratio (it is wider than tall). */
  size?: number;
  /** Show the localized product name next to the mark. */
  showName?: boolean;
  /** Show the tagline under the name. */
  showTagline?: boolean;
  className?: string;
}

/**
 * Brand mark with the localized product name.
 * `public/brand-logo.png` is `deeprespond_meeting_logo_400.png` with transparent margins trimmed.
 */
export function BrandLogo({ size = 32, showName = false, showTagline = false, className }: BrandLogoProps) {
  const t = useT();
  return (
    <div className={cn('flex items-center gap-2.5 select-none', className)}>
      {/* eslint-disable-next-line @next/next/no-img-element -- static export, no image optimizer */}
      <img
        src="/brand-logo.png"
        alt={t('common.appName')}
        width={size}
        height={Math.round((size * LOGO_HEIGHT) / LOGO_WIDTH)}
        className="shrink-0"
        draggable={false}
      />
      {showName && (
        <div className="min-w-0 leading-tight">
          <div className="font-semibold text-foreground truncate">{t('common.appName')}</div>
          {showTagline && <div className="text-xs text-muted-foreground truncate">{t('common.appTagline')}</div>}
        </div>
      )}
    </div>
  );
}
