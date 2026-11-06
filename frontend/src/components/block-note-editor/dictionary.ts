import { en, zh } from '@blocknote/core/locales';
import type { Locale } from '@/i18n';

/** BlockNote's built-in UI strings (slash menu, toolbar, placeholders) for the app locale. */
export function blockNoteDictionary(locale: Locale) {
  return locale === 'zh-CN' ? zh : en;
}
