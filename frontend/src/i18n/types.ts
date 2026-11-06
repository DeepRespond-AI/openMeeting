export const LOCALES = ['zh-CN', 'en'] as const;
export type Locale = (typeof LOCALES)[number];

/** A namespace's messages: nested objects whose leaves are strings. */
export type MessageTree = { [key: string]: string | MessageTree };

/** Recursively widens string literals so zh-CN must mirror the en shape, not its text. */
export type Widen<T> = { [K in keyof T]: T[K] extends string ? string : Widen<T[K]> };

/** Dotted key paths of a message tree, e.g. "recording.start". */
export type Paths<T, P extends string = ''> = {
  [K in keyof T & string]: T[K] extends string ? `${P}${K}` : Paths<T[K], `${P}${K}.`>;
}[keyof T & string];

/**
 * Define one namespace in both languages side by side.
 * English is the source of truth for keys; zh-CN must provide exactly the same keys.
 */
export function defineMessages<T extends MessageTree>(messages: { en: T; 'zh-CN': Widen<T> }) {
  return messages;
}

/** Interpolation values for `{name}` placeholders. */
export type MessageVars = Record<string, string | number>;
