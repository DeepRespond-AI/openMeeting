/**
 * Client-side mirror of the server password rules (server/API.md §1.0) so forms can explain
 * problems before submitting. The server stays authoritative.
 */
export type PasswordProblem = 'length' | 'spaces' | 'letterDigit';

export interface PasswordRules {
  minLength: number;
  maxLength: number;
}

export const DEFAULT_PASSWORD_RULES: PasswordRules = { minLength: 8, maxLength: 64 };

export function passwordProblem(password: string, rules: PasswordRules = DEFAULT_PASSWORD_RULES): PasswordProblem | null {
  if (password.length < rules.minLength || password.length > rules.maxLength) return 'length';
  if (password !== password.trim()) return 'spaces';
  if (!/[A-Za-z]/.test(password) || !/\d/.test(password)) return 'letterDigit';
  return null;
}
