'use client';

import { Languages } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useI18n, LOCALES, type Locale } from '@/i18n';

const LABEL_KEY = { 'zh-CN': 'common.language.zhCN', en: 'common.language.en' } as const;

interface LanguageSwitcherProps {
  /** "toggle": compact icon button flipping between languages; "segmented": both options visible. */
  variant?: 'toggle' | 'segmented';
  className?: string;
}

export function LanguageSwitcher({ variant = 'segmented', className }: LanguageSwitcherProps) {
  const { locale, setLocale, t } = useI18n();

  if (variant === 'toggle') {
    const next: Locale = locale === 'zh-CN' ? 'en' : 'zh-CN';
    return (
      <button
        type="button"
        onClick={() => setLocale(next)}
        title={t('common.language.switchTo')}
        aria-label={t('common.language.switchTo')}
        className={cn(
          'inline-flex items-center gap-1.5 rounded-lg px-2 py-1.5 text-xs font-medium text-muted-foreground',
          'hover:bg-accent hover:text-accent-foreground transition-colors',
          className,
        )}
      >
        <Languages className="h-4 w-4" />
        {locale === 'zh-CN' ? 'EN' : '中'}
      </button>
    );
  }

  return (
    <div role="radiogroup" aria-label={t('common.language.label')} className={cn('inline-flex rounded-lg bg-muted p-1', className)}>
      {LOCALES.map((l) => (
        <button
          key={l}
          type="button"
          role="radio"
          aria-checked={locale === l}
          onClick={() => setLocale(l)}
          className={cn(
            'rounded-md px-3 py-1.5 text-sm font-medium transition-colors',
            locale === l ? 'bg-card text-primary shadow-card' : 'text-muted-foreground hover:text-foreground',
          )}
        >
          {t(LABEL_KEY[l])}
        </button>
      ))}
    </div>
  );
}
