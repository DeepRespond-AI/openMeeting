'use client';

import { cn } from '@/lib/utils';
import { avatarInitial } from '@/lib/phone';
import { useState } from 'react';

const SIZES = {
  sm: 'h-7 w-7 text-xs',
  md: 'h-9 w-9 text-sm',
  lg: 'h-14 w-14 text-xl',
} as const;

/** Public IM avatar, with the existing initial kept when an image is unavailable. */
export function UserAvatar({ name, src, label, size = 'md', className }: { name: string | null | undefined; src?: string; label?: string; size?: keyof typeof SIZES; className?: string }) {
  const [failedSrc, setFailedSrc] = useState('');
  const image = src && /^https:\/\//i.test(src) && src !== failedSrc ? src : '';
  return (
    <span
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
      className={cn(
        'relative inline-flex shrink-0 select-none items-center justify-center overflow-hidden rounded-full bg-brand-gradient font-semibold text-white shadow-card',
        SIZES[size],
        className,
      )}
    >
      {avatarInitial(name)}
      {image && <img src={image} alt="" className="absolute inset-0 h-full w-full object-cover" onError={() => setFailedSrc(image)} />}
    </span>
  );
}
