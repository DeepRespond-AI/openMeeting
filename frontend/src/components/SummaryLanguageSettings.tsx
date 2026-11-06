'use client';

import { useState } from 'react';
import { Globe, Pin, Plus, X } from 'lucide-react';
import { Popover, PopoverTrigger, PopoverContent } from '@/components/ui/popover';
import { LanguagePickerPopover } from '@/components/LanguagePickerPopover';
import { useRecentLanguages } from '@/hooks/useRecentLanguages';
import { labelForCode } from '@/lib/summary-languages';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

export function SummaryLanguageSettings() {
  const { recents, pinned, addRecent, removeRecent, setPinned } = useRecentLanguages();
  const [pickerOpen, setPickerOpen] = useState(false);
  const t = useT();

  const togglePin = (code: string) => {
    setPinned(pinned === code ? null : code);
  };

  return (
    <section className="bg-card border border-border rounded-xl shadow-card p-5 relative">
      <div className="flex items-center gap-2 mb-1">
        <Globe className="h-4 w-4 text-muted-foreground" />
        <h3 className="text-base font-semibold text-foreground">{t('settings.summaryLanguage.title')}</h3>
      </div>
      <p className="text-xs text-muted-foreground mb-4">{t('settings.summaryLanguage.description')}</p>

      <div className="flex flex-wrap items-center gap-2">
        {recents.map((code) => {
          const isPinned = pinned === code;
          const language = labelForCode(code);
          return (
            <span
              key={code}
              className={cn(
                'inline-flex items-center rounded-full border text-sm overflow-hidden',
                isPinned
                  ? 'bg-accent border-primary/30 text-primary'
                  : 'bg-muted border-border text-foreground',
              )}
            >
              <button
                type="button"
                aria-label={isPinned
                  ? t('settings.summaryLanguage.unpin', { language })
                  : t('settings.summaryLanguage.pin', { language })}
                aria-pressed={isPinned}
                title={isPinned ? t('settings.summaryLanguage.unpinHint') : t('settings.summaryLanguage.pinHint')}
                onClick={() => togglePin(code)}
                className="flex items-center gap-1.5 pl-3 pr-2 py-1 hover:brightness-95 active:brightness-90"
              >
                <Pin
                  className={cn('h-3.5 w-3.5', isPinned ? 'text-primary' : 'text-muted-foreground')}
                  fill={isPinned ? 'currentColor' : 'none'}
                />
                {language}
              </button>
              <button
                type="button"
                aria-label={t('settings.summaryLanguage.remove', { language })}
                onClick={() => removeRecent(code)}
                className={cn(
                  'pr-2.5 pl-0.5 py-1 leading-none',
                  isPinned ? 'text-primary/60 hover:text-primary' : 'text-muted-foreground hover:text-foreground',
                )}
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </span>
          );
        })}

        <Popover open={pickerOpen} onOpenChange={setPickerOpen}>
          <PopoverTrigger asChild>
            <button
              type="button"
              disabled={recents.length >= 5}
              className="inline-flex items-center gap-1 rounded-full border border-dashed border-border px-3 py-1 text-sm text-muted-foreground hover:border-primary/50 hover:text-primary disabled:cursor-not-allowed disabled:opacity-50"
            >
              <Plus className="h-3.5 w-3.5" />
              {t('settings.summaryLanguage.add')}
            </button>
          </PopoverTrigger>
          <PopoverContent align="start" className="w-auto p-0 border-0 shadow-none bg-transparent">
            <LanguagePickerPopover
              mode="settings"
              value={null}
              onChange={(code) => {
                if (code) addRecent(code);
                setPickerOpen(false);
              }}
              onClose={() => setPickerOpen(false)}
            />
          </PopoverContent>
        </Popover>
      </div>

      <p className="text-xs text-muted-foreground mt-3">
        {pinned
          ? t('settings.summaryLanguage.footerPinned', { language: labelForCode(pinned) })
          : t('settings.summaryLanguage.footerUnpinned')}
      </p>
    </section>
  );
}
