'use client';

import React, { useMemo, useState } from 'react';
import { Check, Globe, Info, Languages, Search, TriangleAlert } from 'lucide-react';
import Analytics from '@/lib/analytics';
import { toast } from 'sonner';
import { useConfig } from '@/contexts/ConfigContext';
import { useI18n, type Locale } from '@/i18n';
import { cn } from '@/lib/utils';

export interface Language {
  code: string;
  /** English name; also used for analytics and as fallback label. */
  name: string;
}

// ISO 639-1 language codes supported by Whisper
export const LANGUAGES: Language[] = [
  { code: 'auto', name: 'Auto Detect (Original Language)' },
  { code: 'auto-translate', name: 'Auto Detect (Translate to English)' },
  { code: 'en', name: 'English' },
  { code: 'zh', name: 'Chinese' },
  { code: 'de', name: 'German' },
  { code: 'es', name: 'Spanish' },
  { code: 'ru', name: 'Russian' },
  { code: 'ko', name: 'Korean' },
  { code: 'fr', name: 'French' },
  { code: 'ja', name: 'Japanese' },
  { code: 'pt', name: 'Portuguese' },
  { code: 'tr', name: 'Turkish' },
  { code: 'pl', name: 'Polish' },
  { code: 'ca', name: 'Catalan' },
  { code: 'nl', name: 'Dutch' },
  { code: 'ar', name: 'Arabic' },
  { code: 'sv', name: 'Swedish' },
  { code: 'it', name: 'Italian' },
  { code: 'id', name: 'Indonesian' },
  { code: 'hi', name: 'Hindi' },
  { code: 'fi', name: 'Finnish' },
  { code: 'vi', name: 'Vietnamese' },
  { code: 'he', name: 'Hebrew' },
  { code: 'uk', name: 'Ukrainian' },
  { code: 'el', name: 'Greek' },
  { code: 'ms', name: 'Malay' },
  { code: 'cs', name: 'Czech' },
  { code: 'ro', name: 'Romanian' },
  { code: 'da', name: 'Danish' },
  { code: 'hu', name: 'Hungarian' },
  { code: 'ta', name: 'Tamil' },
  { code: 'no', name: 'Norwegian' },
  { code: 'th', name: 'Thai' },
  { code: 'ur', name: 'Urdu' },
  { code: 'hr', name: 'Croatian' },
  { code: 'bg', name: 'Bulgarian' },
  { code: 'lt', name: 'Lithuanian' },
  { code: 'la', name: 'Latin' },
  { code: 'mi', name: 'Maori' },
  { code: 'ml', name: 'Malayalam' },
  { code: 'cy', name: 'Welsh' },
  { code: 'sk', name: 'Slovak' },
  { code: 'te', name: 'Telugu' },
  { code: 'fa', name: 'Persian' },
  { code: 'lv', name: 'Latvian' },
  { code: 'bn', name: 'Bengali' },
  { code: 'sr', name: 'Serbian' },
  { code: 'az', name: 'Azerbaijani' },
  { code: 'sl', name: 'Slovenian' },
  { code: 'kn', name: 'Kannada' },
  { code: 'et', name: 'Estonian' },
  { code: 'mk', name: 'Macedonian' },
  { code: 'br', name: 'Breton' },
  { code: 'eu', name: 'Basque' },
  { code: 'is', name: 'Icelandic' },
  { code: 'hy', name: 'Armenian' },
  { code: 'ne', name: 'Nepali' },
  { code: 'mn', name: 'Mongolian' },
  { code: 'bs', name: 'Bosnian' },
  { code: 'kk', name: 'Kazakh' },
  { code: 'sq', name: 'Albanian' },
  { code: 'sw', name: 'Swahili' },
  { code: 'gl', name: 'Galician' },
  { code: 'mr', name: 'Marathi' },
  { code: 'pa', name: 'Punjabi' },
  { code: 'si', name: 'Sinhala' },
  { code: 'km', name: 'Khmer' },
  { code: 'sn', name: 'Shona' },
  { code: 'yo', name: 'Yoruba' },
  { code: 'so', name: 'Somali' },
  { code: 'af', name: 'Afrikaans' },
  { code: 'oc', name: 'Occitan' },
  { code: 'ka', name: 'Georgian' },
  { code: 'be', name: 'Belarusian' },
  { code: 'tg', name: 'Tajik' },
  { code: 'sd', name: 'Sindhi' },
  { code: 'gu', name: 'Gujarati' },
  { code: 'am', name: 'Amharic' },
  { code: 'yi', name: 'Yiddish' },
  { code: 'lo', name: 'Lao' },
  { code: 'uz', name: 'Uzbek' },
  { code: 'fo', name: 'Faroese' },
  { code: 'ht', name: 'Haitian Creole' },
  { code: 'ps', name: 'Pashto' },
  { code: 'tk', name: 'Turkmen' },
  { code: 'nn', name: 'Norwegian Nynorsk' },
  { code: 'mt', name: 'Maltese' },
  { code: 'sa', name: 'Sanskrit' },
  { code: 'lb', name: 'Luxembourgish' },
  { code: 'my', name: 'Myanmar' },
  { code: 'bo', name: 'Tibetan' },
  { code: 'tl', name: 'Tagalog' },
  { code: 'mg', name: 'Malagasy' },
  { code: 'as', name: 'Assamese' },
  { code: 'tt', name: 'Tatar' },
  { code: 'haw', name: 'Hawaiian' },
  { code: 'ln', name: 'Lingala' },
  { code: 'ha', name: 'Hausa' },
  { code: 'ba', name: 'Bashkir' },
  { code: 'jw', name: 'Javanese' },
  { code: 'su', name: 'Sundanese' },
];

const AUTO_CODES = new Set(['auto', 'auto-translate']);

// Codes Intl.DisplayNames does not know under the Whisper spelling.
const DISPLAY_CODE_ALIASES: Record<string, string> = {
  'zh-tw': 'zh-Hant',
  jw: 'jv',
};

const displayNamesCache = new Map<string, Intl.DisplayNames | null>();

function getDisplayNames(locale: string): Intl.DisplayNames | null {
  if (!displayNamesCache.has(locale)) {
    let dn: Intl.DisplayNames | null = null;
    try {
      dn = new Intl.DisplayNames([locale], { type: 'language' });
    } catch {
      dn = null;
    }
    displayNamesCache.set(locale, dn);
  }
  return displayNamesCache.get(locale) ?? null;
}

/**
 * Localized name of a language code (e.g. "zh" → "中文" / "Chinese").
 * Falls back to the given English name, then to the code itself.
 */
export function languageDisplayName(code: string, locale: Locale | string, fallback?: string): string {
  const lookup = DISPLAY_CODE_ALIASES[code] ?? code;
  const dn = getDisplayNames(locale);
  if (dn) {
    try {
      const name = dn.of(lookup);
      if (name && name.toLowerCase() !== lookup.toLowerCase()) return name;
    } catch {
      /* invalid code for Intl */
    }
  }
  return fallback ?? LANGUAGES.find((l) => l.code === code)?.name ?? code;
}

/** Localized label for a transcription language code, including the auto modes. */
export function transcriptionLanguageLabel(
  code: string,
  locale: Locale,
  t: ReturnType<typeof useI18n>['t'],
): string {
  if (code === 'auto') return t('recording.language.auto');
  if (code === 'auto-translate') return t('recording.language.autoTranslate');
  return languageDisplayName(code, locale);
}

interface LanguageSelectionProps {
  selectedLanguage: string;
  onLanguageChange: (language: string) => void;
  disabled?: boolean;
  /** Hide the section heading (e.g. when the container already shows one). */
  hideTitle?: boolean;
}

export function LanguageSelection({
  selectedLanguage,
  onLanguageChange,
  disabled = false,
  hideTitle = false,
}: LanguageSelectionProps) {
  const { t, locale } = useI18n();
  const [saving, setSaving] = useState(false);
  const [query, setQuery] = useState('');
  const { setSelectedLanguage } = useConfig();

  const options = useMemo(
    () =>
      LANGUAGES.map((lang) => ({
        ...lang,
        label: transcriptionLanguageLabel(lang.code, locale, t),
        description: lang.code === 'auto'
          ? t('recording.language.autoDesc')
          : lang.code === 'auto-translate'
            ? t('recording.language.autoTranslateDesc')
            : undefined,
      })),
    [locale, t],
  );

  const filter = query.trim().toLowerCase();
  const visible = useMemo(
    () =>
      filter
        ? options.filter(
            (o) =>
              o.code.toLowerCase().includes(filter) ||
              o.label.toLowerCase().includes(filter) ||
              o.name.toLowerCase().includes(filter),
          )
        : options,
    [filter, options],
  );

  const handleLanguageChange = async (languageCode: string) => {
    if (languageCode === selectedLanguage) return;
    setSaving(true);
    try {
      // Save language preference to localStorage and sync to backend
      setSelectedLanguage(languageCode);
      onLanguageChange(languageCode);
      console.log('Language preference saved:', languageCode);

      // Track language selection analytics (English names for analytics)
      const selectedLang = LANGUAGES.find(lang => lang.code === languageCode);
      await Analytics.track('language_selected', {
        language_code: languageCode,
        language_name: selectedLang?.name || 'Unknown',
        is_auto_detect: (languageCode === 'auto').toString(),
        is_auto_translate: (languageCode === 'auto-translate').toString()
      });

      toast.success(t('recording.language.saved'), {
        description: t('recording.language.savedDesc', { name: transcriptionLanguageLabel(languageCode, locale, t) }),
      });
    } catch (error) {
      console.error('Failed to save language preference:', error);
      toast.error(t('recording.language.saveFailed'), {
        description: error instanceof Error ? error.message : String(error)
      });
    } finally {
      setSaving(false);
    }
  };

  const selectedLabel = transcriptionLanguageLabel(selectedLanguage, locale, t);
  const isDisabled = disabled || saving;

  return (
    <div className="space-y-3">
      {!hideTitle && (
        <div className="flex items-center gap-2">
          <Globe className="h-4 w-4 text-muted-foreground" />
          <h4 className="text-sm font-semibold text-foreground">{t('recording.language.title')}</h4>
        </div>
      )}

      <div className="overflow-hidden rounded-lg border border-border bg-card">
        <div className="flex items-center gap-2 border-b border-border px-3 py-2">
          <Search className="h-4 w-4 shrink-0 text-muted-foreground" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={t('recording.language.search')}
            aria-label={t('recording.language.search')}
            disabled={isDisabled}
            className="min-w-0 flex-1 bg-transparent text-sm text-foreground outline-none placeholder:text-muted-foreground disabled:opacity-60"
          />
        </div>
        <div role="listbox" aria-label={t('recording.language.title')} className="max-h-60 overflow-y-auto py-1">
          {visible.map((o, i) => {
            const selected = o.code === selectedLanguage;
            const isAuto = AUTO_CODES.has(o.code);
            const nextIsRegular = isAuto && visible[i + 1] && !AUTO_CODES.has(visible[i + 1].code);
            return (
              <React.Fragment key={o.code}>
                <button
                  type="button"
                  role="option"
                  aria-selected={selected}
                  disabled={isDisabled}
                  onClick={() => handleLanguageChange(o.code)}
                  className={cn(
                    'flex w-full items-center justify-between gap-3 px-3 py-1.5 text-left text-sm transition-colors',
                    'hover:bg-accent disabled:cursor-not-allowed disabled:opacity-60',
                    selected ? 'bg-accent font-medium text-accent-foreground' : 'text-foreground',
                  )}
                >
                  <span className="min-w-0">
                    <span className="block truncate">
                      {o.label}
                      {!isAuto && <span className="ml-1.5 text-xs text-muted-foreground">{o.code}</span>}
                    </span>
                    {o.description && (
                      <span className="block truncate text-xs font-normal text-muted-foreground">{o.description}</span>
                    )}
                  </span>
                  {selected && <Check className="h-4 w-4 shrink-0 text-primary" />}
                </button>
                {nextIsRegular && <div className="my-1 h-px bg-border" />}
              </React.Fragment>
            );
          })}
          {visible.length === 0 && (
            <p className="px-3 py-2 text-sm text-muted-foreground">{t('recording.language.noMatches')}</p>
          )}
        </div>
      </div>

      {/* Info text */}
      <div className="space-y-2 text-xs">
        <p className="text-muted-foreground">
          {t('recording.language.current', { name: selectedLabel })}
        </p>
        {selectedLanguage === 'auto' && (
          <div className="flex gap-2 rounded-lg bg-warning/10 p-2.5 text-foreground">
            <TriangleAlert className="mt-0.5 h-4 w-4 shrink-0 text-warning" />
            <div>
              <p className="font-medium">{t('recording.language.autoWarningTitle')}</p>
              <p className="mt-0.5 text-muted-foreground">{t('recording.language.autoWarningBody')}</p>
            </div>
          </div>
        )}
        {selectedLanguage === 'auto-translate' && (
          <div className="flex gap-2 rounded-lg bg-accent p-2.5 text-foreground">
            <Languages className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
            <div>
              <p className="font-medium">{t('recording.language.translateTitle')}</p>
              <p className="mt-0.5 text-muted-foreground">{t('recording.language.translateBody')}</p>
            </div>
          </div>
        )}
        {!AUTO_CODES.has(selectedLanguage) && (
          <p className="flex items-center gap-1.5 text-muted-foreground">
            <Info className="h-3.5 w-3.5 shrink-0" />
            {t('recording.language.optimizedFor', { name: selectedLabel })}
          </p>
        )}
      </div>
    </div>
  );
}
