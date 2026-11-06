import React from 'react';
import { afterEach, describe, expect, mock, test } from 'bun:test';
import { act, create } from 'react-test-renderer';
import type { ServerConfig, ServerStatus, User } from '../../src/lib/server';

function deferred<T>() {
  let resolve!: (value: T) => void;
  let reject!: (error: Error) => void;
  const promise = new Promise<T>((yes, no) => { resolve = yes; reject = no; });
  return { promise, resolve, reject };
}

const user: User = {
  id: 'account-1', phone: '13800138000', name: 'Test account',
  created_at: null, last_login_at: null, has_password: true,
};
const status = (overrides: Partial<ServerStatus> = {}): ServerStatus => ({
  configured: true, connected: true, loggedIn: true, authenticated: true,
  user, authConfig: null, capabilities: null, error: null, lastCheck: null,
  ...overrides,
});
let configRequest = deferred<ServerConfig>();
let statusRequest = deferred<ServerStatus>();
let listener: ((event: { payload: ServerStatus }) => void) | undefined;
let commandUser = user;
const warnings: string[] = [];

mock.module('@tauri-apps/api/core', () => ({
  invoke: async (command: string) => {
    if (command === 'server_get_config') return configRequest.promise;
    if (command === 'server_get_status') return statusRequest.promise;
    if (command === 'auth_logout') return;
    if (['auth_login', 'auth_update_profile', 'auth_change_password'].includes(command)) return commandUser;
    throw new Error(`Unexpected command: ${command}`);
  },
}));
mock.module('@tauri-apps/api/event', () => ({
  listen: async (_name: string, callback: typeof listener) => {
    listener = callback;
    return () => { listener = undefined; };
  },
}));
mock.module('../../src/i18n', () => ({
  t: (_locale: string, key: string) => key,
  getLocale: () => 'en',
  useT: () => (key: string) => key,
  useI18n: () => ({ locale: 'en' }),
}));
mock.module('sonner', () => ({
  toast: { warning: (message: string) => warnings.push(message), success: () => {}, error: () => {} },
}));
mock.module('../../src/components/brand/BrandLogo', () => ({ BrandLogo: () => <div /> }));
mock.module('../../src/components/auth/LoginScreen', () => ({ LoginScreen: () => <div data-testid="login" /> }));
mock.module('../../src/components/auth/PhoneAuth', () => ({ NAME_MAX_LENGTH: 40 }));
mock.module('../../src/components/auth/LogoutDialog', () => ({ LogoutDialog: () => null }));
mock.module('../../src/components/auth/PasswordDialog', () => ({ PasswordDialog: () => null }));
// These tests exercise business-session verification; IM profiles and uploads are
// covered by their own contracts and the real desktop acceptance flow.
mock.module('../../src/components/im/ImUserAvatar', () => ({ ImUserAvatar: ({name}: {name?: string}) => <span>{name}</span> }));
mock.module('../../src/components/auth/AvatarEditor', () => ({ AvatarEditor: () => null }));

const { ServerProvider, useServer } = await import('../../src/contexts/ServerContext');
const { AuthGate } = await import('../../src/components/auth/AuthGate');
const { AccountCard } = await import('../../src/components/auth/AccountCard');
let root: ReturnType<typeof create> | undefined;
afterEach(() => { act(() => root?.unmount()); root = undefined; });

async function mount() {
  configRequest = deferred<ServerConfig>();
  statusRequest = deferred<ServerStatus>();
  commandUser = user;
  warnings.length = 0;
  let context!: ReturnType<typeof useServer>;
  function Probe() { context = useServer(); return null; }
  await act(async () => {
    root = create(
      <ServerProvider>
        <Probe />
        <AuthGate><div data-testid="main"><AccountCard /></div></AuthGate>
      </ServerProvider>,
    );
  });
  return {
    get context() { return context; },
    shown: (view: string) => root!.root.findAllByProps({ 'data-testid': view }).length > 0,
    emit: async (next: ServerStatus) => { await act(async () => { listener!({ payload: next }); }); },
    finish: async (next: ServerStatus) => { await act(async () => { statusRequest.resolve(next); }); },
  };
}

describe('verified server session and AuthGate', () => {
  test('stored credentials cannot bypass the pending server check', async () => {
    const app = await mount();
    await act(async () => { configRequest.resolve({ loggedIn: true, clientId: 'client' }); });
    expect(app.context.isLoading).toBe(true);
    expect(app.context.loggedIn).toBe(false);
    expect(app.shown('main')).toBe(false);
    expect(app.shown('login')).toBe(false);
    await app.finish(status());
    expect(app.context.isLoading).toBe(false);
    expect(app.context.loggedIn).toBe(true);
    expect(app.context.user).toEqual(user);
    expect(app.shown('main')).toBe(true);
  });

  test('a server check can finish before local config', async () => {
    const app = await mount();
    await app.finish(status());
    expect(app.context.isLoading).toBe(false);
    expect(app.shown('main')).toBe(true);
    await act(async () => { configRequest.resolve({ loggedIn: false, clientId: 'client' }); });
    expect(app.shown('main')).toBe(true);
  });

  test.each([
    ['no session', { loggedIn: false, authenticated: false, user: null }],
    ['expired session', { loggedIn: false, authenticated: false, user: null, error: 'Session expired' }],
    ['cold-start network failure', { connected: false, authenticated: false, user: null, error: 'Offline' }],
    ['unverified account data', { authenticated: false }],
    ['missing account data', { user: null }],
  ] as const)('%s shows login without mounting the main app', async (_name, overrides) => {
    const app = await mount();
    await app.finish(status(overrides));
    expect(app.context.isLoading).toBe(false);
    expect(app.context.loggedIn).toBe(false);
    expect(app.context.user).toBeNull();
    expect(app.shown('main')).toBe(false);
    expect(app.shown('login')).toBe(true);
  });

  test('a failed status command ends loading without trusting local credentials', async () => {
    const app = await mount();
    const originalError = console.error;
    console.error = () => {};
    try {
      await act(async () => {
        configRequest.resolve({ loggedIn: true, clientId: 'client' });
        statusRequest.reject(new Error('IPC unavailable'));
      });
    } finally { console.error = originalError; }
    expect(app.context.isLoading).toBe(false);
    expect(app.shown('login')).toBe(true);
    expect(app.shown('main')).toBe(false);
  });

  test('a temporary disconnect keeps an already verified account until session invalidation', async () => {
    const app = await mount();
    await app.finish(status());
    await app.emit(status({ connected: false, authenticated: false, error: 'Offline' }));
    expect(app.shown('main')).toBe(true);
    expect(app.context.user).toEqual(user);
    expect(app.context.isUsable).toBe(false);
    expect(warnings).toEqual([]);
    await app.emit(status({ loggedIn: false, authenticated: false, user: null, error: 'Session expired' }));
    expect(app.shown('login')).toBe(true);
    expect(app.context.user).toBeNull();
    expect(warnings).toEqual(['auth.toast.sessionExpired']);
    // Cached account data cannot restore a session after invalidation.
    await app.emit(status({ authenticated: false }));
    expect(app.shown('login')).toBe(true);
  });

  test('a different unverified account cannot inherit the previous session', async () => {
    const app = await mount();
    await app.finish(status());
    await app.emit(status({ authenticated: false, user: { ...user, id: 'account-2' } }));
    expect(app.shown('login')).toBe(true);
    expect(app.context.user).toBeNull();
  });

  test('password login, profile updates and logout keep the verified account in sync', async () => {
    const app = await mount();
    await app.finish(status({ loggedIn: false, authenticated: false, user: null }));
    statusRequest = deferred<ServerStatus>();
    statusRequest.resolve(status());
    await act(async () => { await app.context.loginWithPassword(user.phone, 'test-password'); });
    expect(app.shown('main')).toBe(true);
    commandUser = { ...user, name: 'New nickname' };
    await act(async () => { await app.context.updateProfile(commandUser.name); });
    expect(app.context.user?.name).toBe('New nickname');
    commandUser = { ...commandUser, has_password: false };
    await act(async () => { await app.context.changePassword(null, 'new-password'); });
    expect(app.context.user?.has_password).toBe(false);
    statusRequest = deferred<ServerStatus>();
    statusRequest.resolve(status({ loggedIn: false, authenticated: false, user: null }));
    await act(async () => { await app.context.logout(); });
    expect(app.shown('login')).toBe(true);
    expect(app.context.user).toBeNull();
    expect(warnings).toEqual([]);
  });

  test('a verified account with no nickname displays its masked phone instead of not signed in', async () => {
    const app = await mount();
    await app.finish(status({ user: { ...user, name: '' } }));
    const rendered = JSON.stringify(root!.toJSON());
    expect(app.shown('main')).toBe(true);
    expect(rendered).toContain('138****8000');
    expect(rendered).not.toContain('auth.account.notLoggedIn');
  });
});
