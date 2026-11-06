'use client';

import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import { listen } from '@tauri-apps/api/event';
import {
  AuthConfig,
  Capabilities,
  SendCodeResult,
  ServerConfig,
  ServerStatus,
  SERVER_STATUS_EVENT,
  SmsPurpose,
  User,
  getServerConfig,
  getServerStatus,
  isServerUsable,
  changePassword as changePasswordCommand,
  loginWithPassword,
  loginWithPhone,
  logout as logoutCommand,
  registerWithPhone,
  resetPassword as resetPasswordCommand,
  sendAuthCode,
  updateProfile as updateProfileCommand,
} from '@/lib/server';

interface ServerContextType {
  status: ServerStatus | null;
  config: ServerConfig | null;
  capabilities: Capabilities | null;
  /** configured + connected + logged in + authenticated */
  isUsable: boolean;
  /** True until the first server session check has finished. */
  isLoading: boolean;
  /** The server has verified this session and supplied its account. */
  loggedIn: boolean;
  user: User | null;
  authConfig: AuthConfig | null;
  refresh: () => Promise<ServerStatus | null>;
  sendCode: (phone: string, purpose: SmsPurpose) => Promise<SendCodeResult>;
  /** SMS-code login. */
  login: (phone: string, code: string) => Promise<User>;
  loginWithPassword: (phone: string, password: string) => Promise<User>;
  register: (phone: string, code: string, name: string, password: string) => Promise<User>;
  resetPassword: (phone: string, code: string, password: string) => Promise<User>;
  changePassword: (oldPassword: string | null, password: string) => Promise<User>;
  logout: () => Promise<void>;
  updateProfile: (name: string) => Promise<User>;
}

const ServerContext = createContext<ServerContextType | undefined>(undefined);

export function ServerProvider({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<ServerStatus | null>(null);
  const [config, setConfig] = useState<ServerConfig | null>(null);
  const [statusLoaded, setStatusLoaded] = useState(false);
  const [verifiedUser, setVerifiedUser] = useState<User | null>(null);

  const loadConfig = useCallback(async () => {
    try {
      setConfig(await getServerConfig());
    } catch (error) {
      console.error('[ServerContext] Failed to load server config:', error);
    }
  }, []);

  const applyStatus = useCallback((next: ServerStatus) => {
    setStatus(next);
    setVerifiedUser((previous) => {
      if (!next.configured || !next.loggedIn) return null;
      if (next.authenticated && next.user) return next.user;
      // Keep an already verified account through a temporary connection failure.
      // A stored token alone must never establish a session on startup.
      return previous && next.user?.id === previous.id ? next.user : null;
    });
    setStatusLoaded(true);
    // Keep the local config view in sync with the status (login state).
    setConfig((prev) => (prev ? { ...prev, loggedIn: next.loggedIn } : prev));
  }, []);

  const refresh = useCallback(async () => {
    try {
      const next = await getServerStatus();
      applyStatus(next);
      return next;
    } catch (error) {
      console.error('[ServerContext] Failed to load server status:', error);
      return null;
    } finally {
      setStatusLoaded(true);
    }
  }, [applyStatus]);

  useEffect(() => {
    void loadConfig();
    void refresh();
  }, [loadConfig, refresh]);

  useEffect(() => {
    let disposed = false;
    let unlisten: (() => void) | undefined;
    listen<ServerStatus>(SERVER_STATUS_EVENT, (event) => applyStatus(event.payload))
      .then((fn) => {
        if (disposed) fn();
        else unlisten = fn;
      })
      .catch((error) => console.error('[ServerContext] Failed to listen for server-status:', error));
    return () => {
      disposed = true;
      unlisten?.();
    };
  }, [applyStatus]);

  const sendCode = useCallback((phone: string, purpose: SmsPurpose) => sendAuthCode(phone, purpose), []);

  // Login/registration/logout emit `server-status`; refresh afterwards so the
  // state is correct even if the event raced the command result.
  const login = useCallback(async (phone: string, code: string) => {
    const user = await loginWithPhone(phone, code);
    await refresh();
    return user;
  }, [refresh]);

  const passwordLogin = useCallback(async (phone: string, password: string) => {
    const user = await loginWithPassword(phone, password);
    await refresh();
    return user;
  }, [refresh]);

  const register = useCallback(async (phone: string, code: string, name: string, password: string) => {
    const user = await registerWithPhone(phone, code, name, password);
    await refresh();
    return user;
  }, [refresh]);

  const resetPassword = useCallback(async (phone: string, code: string, password: string) => {
    const user = await resetPasswordCommand(phone, code, password);
    await refresh();
    return user;
  }, [refresh]);

  const changePassword = useCallback(async (oldPassword: string | null, password: string) => {
    const user = await changePasswordCommand(oldPassword, password);
    setStatus((prev) => (prev ? { ...prev, user } : prev));
    setVerifiedUser((prev) => (prev?.id === user.id ? user : prev));
    return user;
  }, []);

  const logout = useCallback(async () => {
    await logoutCommand();
    setVerifiedUser(null);
    await refresh();
  }, [refresh]);

  const updateProfile = useCallback(async (name: string) => {
    const user = await updateProfileCommand(name);
    setStatus((prev) => (prev ? { ...prev, user } : prev));
    setVerifiedUser((prev) => (prev?.id === user.id ? user : prev));
    return user;
  }, []);

  const loggedIn = !!status?.loggedIn && !!verifiedUser;
  const isLoading = !statusLoaded;

  const value = useMemo<ServerContextType>(() => ({
    status,
    config,
    capabilities: status?.capabilities ?? null,
    isUsable: loggedIn && isServerUsable(status),
    isLoading,
    loggedIn,
    user: verifiedUser,
    authConfig: status?.authConfig ?? null,
    refresh,
    sendCode,
    login,
    loginWithPassword: passwordLogin,
    register,
    resetPassword,
    changePassword,
    logout,
    updateProfile,
  }), [status, config, isLoading, loggedIn, verifiedUser, refresh, sendCode, login, passwordLogin, register,
    resetPassword, changePassword, logout, updateProfile]);

  return <ServerContext.Provider value={value}>{children}</ServerContext.Provider>;
}

export function useServer() {
  const context = useContext(ServerContext);
  if (!context) {
    throw new Error('useServer must be used within a ServerProvider');
  }
  return context;
}

/** Same as useServer but returns null outside a provider (e.g. isolated component tests). */
export function useOptionalServer() {
  return useContext(ServerContext) ?? null;
}
