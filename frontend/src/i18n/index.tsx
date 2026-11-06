'use client';

import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { namespaces } from './messages';
import { LOCALES, type Locale, type MessageTree, type MessageVars, type Paths } from './types';

export type { Locale } from './types';
export { LOCALES } from './types';

type Namespaces = typeof namespaces;
/** Every valid translation key, e.g. "common.actions.save" or "recording.start". */
export type TranslationKey = {
  [N in keyof Namespaces & string]: `${N}.${Paths<Namespaces[N]['en']>}`;
}[keyof Namespaces & string];

const STORAGE_KEY = 'dr.locale';

function detectLocale(): Locale {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved && (LOCALES as readonly string[]).includes(saved)) return saved as Locale;
  } catch {
    /* storage unavailable */
  }
  if (typeof navigator !== 'undefined' && navigator.language?.toLowerCase().startsWith('zh')) return 'zh-CN';
  return 'en';
}

// Module-level locale so non-React code (services, toasts in plain functions) can translate too.
let currentLocale: Locale = typeof window === 'undefined' ? 'zh-CN' : detectLocale();

export function getLocale(): Locale {
  return currentLocale;
}

function lookup(locale: Locale, key: string): string | undefined {
  const [ns, ...path] = key.split('.');
  let node: string | MessageTree | undefined = (namespaces as Record<string, Record<Locale, MessageTree>>)[ns]?.[locale];
  for (const part of path) {
    if (node === undefined || typeof node === 'string') return undefined;
    node = node[part];
  }
  return typeof node === 'string' ? node : undefined;
}

function interpolate(text: string, vars?: MessageVars): string {
  if (!vars) return text;
  return text.replace(/\{(\w+)\}/g, (match, name: string) => (name in vars ? String(vars[name]) : match));
}

/** Translate outside React (uses the active locale). Falls back to English, then to the key itself. */
export function t(key: TranslationKey, vars?: MessageVars): string {
  const text = lookup(currentLocale, key) ?? lookup('en', key) ?? key;
  return interpolate(text, vars);
}

interface I18nContextValue {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: typeof t;
}

const I18nContext = createContext<I18nContextValue | null>(null);

function applyLocale(locale: Locale) {
  currentLocale = locale;
  document.documentElement.lang = locale;
  // Keep native surfaces (window title, tray menu) in sync; ignore when not running in Tauri.
  invoke('set_ui_locale', { locale }).catch(() => {});
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(currentLocale);
  // The static export is prerendered without access to the user's language; render only
  // on the client so the first paint is already in the right language (no hydration mismatch).
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    applyLocale(locale);
  }, [locale]);

  useEffect(() => {
    const detected = detectLocale();
    currentLocale = detected;
    setLocaleState(detected);
    setMounted(true);
  }, []);

  const setLocale = useCallback((next: Locale) => {
    try {
      localStorage.setItem(STORAGE_KEY, next);
    } catch {
      /* storage unavailable */
    }
    currentLocale = next;
    setLocaleState(next);
  }, []);

  // `t` identity changes with the locale so memoized consumers re-render on switch.
  const value = useMemo<I18nContextValue>(
    () => ({ locale, setLocale, t: (key, vars) => t(key, vars) }),
    [locale, setLocale],
  );

  return <I18nContext.Provider value={value}>{mounted ? children : null}</I18nContext.Provider>;
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext);
  if (!ctx) {
    // Outside the provider (isolated tests): translate with the module locale.
    return { locale: currentLocale, setLocale: () => {}, t };
  }
  return ctx;
}

/** Shorthand for components that only need `t`. */
export function useT() {
  return useI18n().t;
}
