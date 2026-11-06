/**
 * Mainland China mobile number helpers for phone login (server/API.md §1.0).
 * The server accepts `^1[3-9]\d{9}$` after stripping a leading +86/86, spaces and dashes.
 */

const PHONE_RE = /^1[3-9]\d{9}$/;

/** Normalise user input to 11 digits, or null when it is not a valid mobile number. */
export function normalizePhone(raw: string): string | null {
  let compact = raw.replace(/[\s-]/g, '');
  if (compact.startsWith('+86')) compact = compact.slice(3);
  else if (compact.length === 13 && compact.startsWith('86')) compact = compact.slice(2);
  return PHONE_RE.test(compact) ? compact : null;
}

export function isValidPhone(raw: string): boolean {
  return normalizePhone(raw) !== null;
}

/**
 * Sanitise what the user types/pastes into the phone field (the +86 prefix is
 * shown separately): drop a pasted country code and non-digits, cap at 11 digits.
 */
export function sanitizePhoneInput(raw: string): string {
  let compact = raw.replace(/[\s-]/g, '');
  if (compact.startsWith('+86')) compact = compact.slice(3);
  else if (compact.length > 11 && compact.startsWith('86')) compact = compact.slice(2);
  return compact.replace(/\D/g, '').slice(0, 11);
}

/** Digits only, capped at `length` — for the SMS code field. */
export function sanitizeCodeInput(raw: string, length = 6): string {
  return raw.replace(/\D/g, '').slice(0, length);
}

/** `13800138000` → `138****8000` (other values are returned unchanged). */
export function maskPhone(phone: string | null | undefined): string {
  if (!phone) return '';
  const normalized = normalizePhone(phone);
  if (!normalized) return phone;
  return `${normalized.slice(0, 3)}****${normalized.slice(7)}`;
}

/** First visible character of a name for avatars (uppercased for Latin names). */
export function avatarInitial(name: string | null | undefined): string {
  const trimmed = (name ?? '').trim();
  if (!trimmed) return '?';
  return Array.from(trimmed)[0].toUpperCase();
}
