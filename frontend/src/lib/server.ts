/**
 * Typed wrappers for the remote-server Tauri commands (see server/API.md section 3).
 *
 * The desktop app is a thin client: speech recognition, LLM summaries and
 * meeting storage all live on the self-hosted server. These helpers are the only
 * place the UI talks to the `server_*` commands directly.
 */
import { invoke } from '@tauri-apps/api/core';
import { getLocale, t } from '@/i18n';

export interface SttCapability {
  engine: string | null;
  model: string | null;
  ready: boolean;
  error: string | null;
}

export interface LlmCapability {
  name: string | null;
  model: string | null;
  ready: boolean;
  error: string | null;
}

export interface Capabilities {
  server_version: string;
  user: { id: string; name: string; phone?: string } | null;
  stt: SttCapability;
  llm: LlmCapability;
}

/** The account that owns the login session (server/API.md §1.0). */
export interface User {
  id: string;
  phone: string;
  name: string;
  created_at: string | null;
  last_login_at: string | null;
  /** False for accounts created before passwords existed (SMS-code login only). */
  has_password: boolean;
}

/** Public `GET /api/v1/auth/config`. */
export interface AuthConfig {
  registration_open: boolean;
  sms_ready: boolean;
  code_length: number;
  resend_interval_sec: number;
  password_min_length: number;
  password_max_length: number;
  server_version: string | null;
}

/**
 * Connection state from Rust. The server URL is built into the app and is never sent to
 * (or shown by) the UI.
 */
export interface ServerStatus {
  /** A server URL is set (always true: it is built in). */
  configured: boolean;
  /** The server is reachable. */
  connected: boolean;
  /** A login session is stored locally. */
  loggedIn: boolean;
  /** The server accepted the stored session (false after a 401). */
  authenticated: boolean;
  user: User | null;
  authConfig: AuthConfig | null;
  capabilities: Capabilities | null;
  error: string | null;
  lastCheck: string | null;
}

export interface ServerConfig {
  loggedIn: boolean;
  clientId: string;
}

export type SmsPurpose = 'register' | 'login' | 'reset_password';

export interface SendCodeResult {
  sent: boolean;
  resend_after_sec: number;
  expires_in_sec: number | null;
  /** Only returned by a dev-mode server without SMS configuration. */
  dev_code?: string;
}

/** Event emitted by Rust on every heartbeat / status change. */
export const SERVER_STATUS_EVENT = 'server-status';

/** Settings route + tab that hosts the account and service-status settings. */
export const SERVER_SETTINGS_ROUTE = '/settings?tab=server';

/** Rust command errors arrive as plain strings (server `detail` passed through). */
export function errorMessage(error: unknown): string {
  if (typeof error === 'string') return error;
  if (error instanceof Error) return error.message;
  return String(error);
}

export function getServerConfig(): Promise<ServerConfig> {
  return invoke<ServerConfig>('server_get_config');
}

export function sendAuthCode(phone: string, purpose: SmsPurpose): Promise<SendCodeResult> {
  return invoke<SendCodeResult>('auth_send_code', { phone, purpose });
}

export function registerWithPhone(phone: string, code: string, name: string, password: string): Promise<User> {
  return invoke<User>('auth_register', { phone, code, name, password });
}

/** Login with an SMS code. */
export function loginWithPhone(phone: string, code: string): Promise<User> {
  return invoke<User>('auth_login', { phone, code, password: null });
}

/** Login with the account password. */
export function loginWithPassword(phone: string, password: string): Promise<User> {
  return invoke<User>('auth_login', { phone, code: null, password });
}

/** Forgot password: set a new one with a `reset_password` SMS code; signs in on success. */
export function resetPassword(phone: string, code: string, password: string): Promise<User> {
  return invoke<User>('auth_reset_password', { phone, code, password });
}

/** Set the first password (`oldPassword` null) or change it. */
export function changePassword(oldPassword: string | null, password: string): Promise<User> {
  return invoke<User>('auth_change_password', { oldPassword, password });
}

export function logout(): Promise<void> {
  return invoke<void>('auth_logout');
}

export function getCurrentUser(): Promise<User | null> {
  return invoke<User | null>('auth_get_user');
}

export function updateProfile(name: string): Promise<User> {
  return invoke<User>('auth_update_profile', { name });
}

export function getServerStatus(): Promise<ServerStatus> {
  return invoke<ServerStatus>('server_get_status');
}

/**
 * Returns a local file path for the meeting audio (downloading it from the server
 * into the recordings folder if needed), or null when the server has none.
 */
export function fetchMeetingAudio(meetingId: string): Promise<string | null> {
  return invoke<string | null>('server_fetch_meeting_audio', { meetingId });
}

export function isServerUsable(status: ServerStatus | null | undefined): boolean {
  return !!status && status.configured && status.connected && status.loggedIn && status.authenticated;
}

/**
 * Localized, user-facing explanation of why the service cannot be used, or null if it is fine.
 * `need` selects which capability must be ready in addition to the connection. Deliberately
 * generic: service internals (models, versions, server error details) are never shown.
 */
export function describeServerProblem(
  status: ServerStatus | null | undefined,
  need: 'connection' | 'stt' | 'llm' = 'connection',
): string | null {
  if (!status) return t('server.problems.noStatus');
  if (!status.configured) return t('server.problems.notConfigured');
  if (!status.connected) return t('server.problems.cannotConnect');
  if (!status.loggedIn) return t('server.problems.notLoggedIn');
  if (!status.authenticated) return t('server.problems.sessionInvalid');
  const caps = status.capabilities;
  if (need === 'stt' && (!caps || !caps.stt.ready)) return t('server.problems.sttNotReady');
  if (need === 'llm' && (!caps || !caps.llm.ready)) return t('server.problems.llmNotReady');
  return null;
}
