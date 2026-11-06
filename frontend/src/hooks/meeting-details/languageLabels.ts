import { t, type Locale } from '@/i18n';

// Codes whose BCP-47 form differs from the code we send to the backend.
const DISPLAY_CODE: Record<string, string> = {
  'zh-tw': 'zh-Hant',
  zh: 'zh-Hans',
};

const displayNamesCache = new Map<Locale, Intl.DisplayNames | null>();

function displayNames(locale: Locale): Intl.DisplayNames | null {
  if (!displayNamesCache.has(locale)) {
    try {
      displayNamesCache.set(locale, new Intl.DisplayNames([locale], { type: 'language' }));
    } catch {
      displayNamesCache.set(locale, null);
    }
  }
  return displayNamesCache.get(locale) ?? null;
}

/**
 * Localized display name for a language code (codes themselves are never changed).
 * Handles the transcription pseudo-codes `auto` / `auto-translate`.
 */
export function languageLabel(code: string, locale: Locale, fallback?: string): string {
  if (code === 'auto') return t('meeting.languages.auto');
  if (code === 'auto-translate') return t('meeting.languages.autoTranslate');
  try {
    const name = displayNames(locale)?.of(DISPLAY_CODE[code] ?? code);
    if (name && name.toLowerCase() !== code.toLowerCase()) return name;
  } catch {
    /* unsupported code */
  }
  return fallback ?? code;
}

/** Format seconds as m:ss or h:mm:ss. */
export function formatClock(seconds: number | null | undefined): string {
  if (seconds == null || !Number.isFinite(seconds) || seconds < 0) return '--:--';
  const total = Math.floor(seconds);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const ss = s.toString().padStart(2, '0');
  return h > 0 ? `${h}:${m.toString().padStart(2, '0')}:${ss}` : `${m.toString().padStart(2, '0')}:${ss}`;
}
