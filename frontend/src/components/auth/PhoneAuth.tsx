'use client';

import React, { useEffect, useMemo, useRef, useState } from 'react';
import { AlertCircle, Info, KeyRound, Loader2, MailCheck, ShieldCheck, Smartphone, UserRound } from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { cn } from '@/lib/utils';
import { useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { useCountdown } from '@/hooks/useCountdown';
import { passwordProblem } from '@/lib/password';
import { maskPhone, normalizePhone, sanitizeCodeInput, sanitizePhoneInput } from '@/lib/phone';
import { errorMessage, type AuthConfig, type SmsPurpose, type User } from '@/lib/server';
import { describePasswordProblem, PasswordInput, passwordRulesOf } from './PasswordInput';

/** Sign in, sign up, or reset a forgotten password (reached from "Forgot password?"). */
export type PhoneAuthMode = 'login' | 'register' | 'reset';

/** How a user signs in: account password or SMS verification code. */
export type LoginMethod = 'password' | 'code';

const SMS_PURPOSE: Record<PhoneAuthMode, SmsPurpose> = {
  login: 'login',
  register: 'register',
  reset: 'reset_password',
};

/** Nickname length limit (mirrors the Rust-side validation). */
import { USER_NAME_MAX as NAME_MAX_LENGTH } from '@/lib/field-limits';
import { LimitedInput } from '@/components/ui/limited-input';
export { NAME_MAX_LENGTH };

interface PhoneAuthProps {
  initialMode?: PhoneAuthMode;
  /** Server auth config; defaults to the one from the current server status. */
  authConfig?: AuthConfig | null;
  /** Called after a successful login/registration (the session is already stored). */
  onSuccess?: (user: User, mode: PhoneAuthMode) => void;
  /** Show the heading + subheading above the form. */
  showHeading?: boolean;
  className?: string;
}

function Notice({ tone, icon: Icon, children }: { tone: 'error' | 'info' | 'success' | 'warning'; icon: React.ElementType; children: React.ReactNode }) {
  return (
    <div
      role={tone === 'error' ? 'alert' : 'status'}
      className={cn(
        'flex items-start gap-2 rounded-lg border px-3 py-2 text-sm',
        tone === 'error' && 'border-destructive/30 bg-destructive/5 text-destructive',
        tone === 'info' && 'border-primary/20 bg-accent text-accent-foreground',
        tone === 'success' && 'border-success/30 bg-success/10 text-success',
        tone === 'warning' && 'border-warning/30 bg-warning/10 text-warning',
      )}
    >
      <Icon className="mt-0.5 h-4 w-4 shrink-0" />
      <span className="min-w-0 break-words">{children}</span>
    </div>
  );
}

/**
 * Phone-number auth form (server/API.md §1.0):
 * - Sign in with the password or with an SMS code (method switch);
 * - Sign up with an SMS code, nickname and password;
 * - Forgot password: SMS code + new password, then signed in.
 * Server error details (Chinese `detail`) are shown as returned.
 */
export function PhoneAuth({ initialMode = 'login', authConfig: authConfigProp, onSuccess, showHeading = true, className }: PhoneAuthProps) {
  const t = useT();
  const server = useServer();
  const authConfig = authConfigProp === undefined ? server.authConfig : authConfigProp;
  const codeLength = authConfig?.code_length || 6;
  const registrationClosed = authConfig?.registration_open === false;
  const passwordRules = passwordRulesOf(authConfig);

  const [mode, setMode] = useState<PhoneAuthMode>(initialMode);
  const [method, setMethod] = useState<LoginMethod>('password');
  const [phone, setPhone] = useState('');
  const [code, setCode] = useState('');
  const [name, setName] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [sentTo, setSentTo] = useState<string | null>(null);
  const [devCode, setDevCode] = useState<string | null>(null);
  const [sending, setSending] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const countdown = useCountdown();
  const codeInputRef = useRef<HTMLInputElement>(null);

  const normalizedPhone = useMemo(() => normalizePhone(phone), [phone]);
  const registerBlocked = mode === 'register' && registrationClosed;
  const needsCode = mode !== 'login' || method === 'code';
  const needsPassword = mode !== 'login' || method === 'password';
  // Registration and reset choose a new password: confirm it and check the rules.
  const choosesPassword = mode !== 'login';

  useEffect(() => {
    setMode(initialMode);
  }, [initialMode]);

  const resetTransient = () => {
    setCode('');
    setPassword('');
    setConfirm('');
    setError(null);
    setSentTo(null);
    setDevCode(null);
  };

  const switchMode = (next: PhoneAuthMode) => {
    if (next === mode) return;
    setMode(next);
    resetTransient();
  };

  const switchMethod = (next: LoginMethod) => {
    if (next === method) return;
    setMethod(next);
    resetTransient();
  };

  const handleSendCode = async () => {
    setError(null);
    if (!normalizedPhone) {
      setError(t('auth.errors.phoneInvalid'));
      return;
    }
    setSending(true);
    try {
      const result = await server.sendCode(normalizedPhone, SMS_PURPOSE[mode]);
      countdown.start(result.resend_after_sec || authConfig?.resend_interval_sec || 60);
      setSentTo(normalizedPhone);
      setDevCode(result.dev_code ?? null);
      codeInputRef.current?.focus();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSending(false);
    }
  };

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (submitting) return;
    setError(null);
    if (!normalizedPhone) {
      setError(t('auth.errors.phoneInvalid'));
      return;
    }
    if (needsCode && code.length !== codeLength) {
      setError(t('auth.errors.codeInvalid', { length: codeLength }));
      return;
    }
    const trimmedName = name.trim();
    if (mode === 'register') {
      if (!trimmedName) {
        setError(t('auth.errors.nameRequired'));
        return;
      }
      if (Array.from(trimmedName).length > NAME_MAX_LENGTH) {
        setError(t('auth.errors.nameTooLong', { max: NAME_MAX_LENGTH }));
        return;
      }
    }
    if (needsPassword && !password) {
      setError(t('auth.errors.passwordRequired'));
      return;
    }
    if (choosesPassword) {
      const problem = passwordProblem(password, passwordRules);
      if (problem) {
        setError(describePasswordProblem(problem, passwordRules, t));
        return;
      }
      if (password !== confirm) {
        setError(t('auth.errors.passwordMismatch'));
        return;
      }
    }
    setSubmitting(true);
    try {
      let user: User;
      if (mode === 'register') {
        user = await server.register(normalizedPhone, code, trimmedName, password);
        toast.success(t('auth.toast.registered', { name: user.name }));
      } else if (mode === 'reset') {
        user = await server.resetPassword(normalizedPhone, code, password);
        toast.success(t('auth.toast.passwordReset', { name: user.name }));
      } else {
        user = method === 'password'
          ? await server.loginWithPassword(normalizedPhone, password)
          : await server.login(normalizedPhone, code);
        toast.success(t('auth.toast.loggedIn', { name: user.name }));
      }
      onSuccess?.(user, mode);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSubmitting(false);
    }
  };

  const sendLabel = sending
    ? t('auth.sending')
    : countdown.running
      ? t('auth.resendIn', { seconds: countdown.remaining })
      : sentTo
        ? t('auth.resend')
        : t('auth.sendCode');

  return (
    <div className={cn('space-y-6', className)}>
      {showHeading && (
        <div className="space-y-2">
          <h1 className="animate-fade-in-up text-2xl font-semibold text-foreground">
            {mode === 'login'
              ? t('auth.heading.login', { appName: t('common.appName') })
              : t(`auth.heading.${mode}`)}
          </h1>
          <p className="animate-fade-in-up delay-75 text-sm leading-relaxed text-muted-foreground">
            {t(`auth.subheading.${mode}`)}
          </p>
        </div>
      )}

      {mode !== 'reset' && (
        <Tabs value={mode} onValueChange={(v) => switchMode(v as PhoneAuthMode)}>
          <TabsList aria-label={t('auth.tabs.label')} className="grid h-10 w-full grid-cols-2">
            <TabsTrigger value="login" className="h-8">{t('auth.tabs.login')}</TabsTrigger>
            <TabsTrigger value="register" className="h-8">{t('auth.tabs.register')}</TabsTrigger>
          </TabsList>
        </Tabs>
      )}

      <form onSubmit={handleSubmit} noValidate className="space-y-4 rounded-xl border border-border bg-card p-5 shadow-card">
        {/* Sign-in method */}
        {mode === 'login' && (
          <div role="radiogroup" aria-label={t('auth.method.label')} className="flex gap-5 border-b border-border">
            {(['password', 'code'] as const).map((m) => (
              <button
                key={m}
                type="button"
                role="radio"
                aria-checked={method === m}
                onClick={() => switchMethod(m)}
                className={cn(
                  '-mb-px border-b-2 pb-2 text-sm font-medium transition-colors',
                  method === m
                    ? 'border-primary text-foreground'
                    : 'border-transparent text-muted-foreground hover:text-foreground',
                )}
              >
                {t(`auth.method.${m}`)}
              </button>
            ))}
          </div>
        )}

        {/* Phone */}
        <div className="space-y-2">
          <Label htmlFor="phone-auth-phone">{t('auth.fields.phone')}</Label>
          <div className="flex h-11 items-center overflow-hidden rounded-lg border border-input bg-card shadow-sm transition-colors focus-within:border-primary focus-within:ring-2 focus-within:ring-primary/20">
            <span className="flex h-full shrink-0 items-center gap-1.5 border-r border-border bg-muted px-3 text-sm font-medium text-muted-foreground">
              <Smartphone className="h-4 w-4" />
              {t('auth.fields.phonePrefix')}
            </span>
            <input
              id="phone-auth-phone"
              type="tel"
              inputMode="numeric"
              autoComplete="tel-national"
              autoFocus
              placeholder={t('auth.fields.phonePlaceholder')}
              value={phone}
              onChange={(e) => {
                setPhone(sanitizePhoneInput(e.target.value));
                setError(null);
              }}
              className="h-full min-w-0 flex-1 bg-transparent px-3 text-base tracking-wide text-foreground outline-none placeholder:text-muted-foreground md:text-sm"
            />
          </div>
        </div>

        {/* Code + send button */}
        {needsCode && <div className="space-y-2">
          <Label htmlFor="phone-auth-code">{t('auth.fields.code')}</Label>
          <div className="flex gap-2">
            <div className="relative min-w-0 flex-1">
              <KeyRound className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                id="phone-auth-code"
                ref={codeInputRef}
                inputMode="numeric"
                autoComplete="one-time-code"
                maxLength={codeLength}
                placeholder={t('auth.fields.codePlaceholder', { length: codeLength })}
                value={code}
                onChange={(e) => {
                  setCode(sanitizeCodeInput(e.target.value, codeLength));
                  setError(null);
                }}
                className="h-11 rounded-lg pl-9 font-mono tracking-[0.3em] placeholder:font-sans placeholder:tracking-normal"
              />
            </div>
            <Button
              type="button"
              variant="outline"
              onClick={handleSendCode}
              disabled={sending || countdown.running || !normalizedPhone || registerBlocked}
              className="h-11 min-w-[7.5rem] shrink-0 rounded-lg tabular-nums"
            >
              {sending && <Loader2 className="h-4 w-4 animate-spin" />}
              {sendLabel}
            </Button>
          </div>
        </div>}

        {/* Nickname (sign up) */}
        {mode === 'register' && (
          <div className="space-y-2">
            <Label htmlFor="phone-auth-name">{t('auth.fields.name')}</Label>
            <div className="relative">
              <UserRound className="pointer-events-none absolute left-3 top-[22px] z-10 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <LimitedInput
                id="phone-auth-name"
                autoComplete="nickname"
                maxLength={NAME_MAX_LENGTH}
                placeholder={t('auth.fields.namePlaceholder')}
                value={name}
                onChange={(e) => {
                  setName(e.target.value);
                  setError(null);
                }}
                className="h-11 rounded-lg pl-9"
              />
            </div>
          </div>
        )}

        {/* Password (+ confirmation when choosing a new one) */}
        {needsPassword && (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <Label htmlFor="phone-auth-password">
                {mode === 'reset' ? t('auth.fields.newPassword') : t('auth.fields.password')}
              </Label>
              {mode === 'login' && (
                <button
                  type="button"
                  onClick={() => switchMode('reset')}
                  className="text-xs font-medium text-primary underline-offset-4 hover:underline"
                >
                  {t('auth.forgotPassword')}
                </button>
              )}
            </div>
            <PasswordInput
              id="phone-auth-password"
              autoComplete={choosesPassword ? 'new-password' : 'current-password'}
              maxLength={passwordRules.maxLength}
              placeholder={choosesPassword
                ? t('auth.fields.passwordPlaceholder', { min: passwordRules.minLength, max: passwordRules.maxLength })
                : undefined}
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                setError(null);
              }}
            />
          </div>
        )}
        {choosesPassword && (
          <div className="space-y-2">
            <Label htmlFor="phone-auth-confirm">{t('auth.fields.confirmPassword')}</Label>
            <PasswordInput
              id="phone-auth-confirm"
              autoComplete="new-password"
              maxLength={passwordRules.maxLength}
              placeholder={t('auth.fields.confirmPasswordPlaceholder')}
              value={confirm}
              onChange={(e) => {
                setConfirm(e.target.value);
                setError(null);
              }}
            />
          </div>
        )}

        {registerBlocked && <Notice tone="warning" icon={Info}>{t('auth.registrationClosed')}</Notice>}
        {needsCode && authConfig?.sms_ready === false && !devCode && !registerBlocked && (
          <Notice tone="warning" icon={Info}>{t('auth.smsNotReady')}</Notice>
        )}
        {sentTo && !error && (
          <Notice tone="success" icon={MailCheck}>{t('auth.codeSent', { phone: maskPhone(sentTo) })}</Notice>
        )}
        {devCode && <Notice tone="info" icon={Info}>{t('auth.devCode', { code: devCode })}</Notice>}
        {error && <Notice tone="error" icon={AlertCircle}>{error}</Notice>}

        <Button type="submit" disabled={submitting || registerBlocked} className="h-11 w-full rounded-lg text-base md:text-sm">
          {submitting && <Loader2 className="h-4 w-4 animate-spin" />}
          {t(`auth.submit.${mode}`)}
        </Button>

        {mode === 'reset' ? (
          <p className="text-center text-sm">
            <button
              type="button"
              onClick={() => switchMode('login')}
              className="font-medium text-primary underline-offset-4 hover:underline"
            >
              {t('auth.backToLogin')}
            </button>
          </p>
        ) : (
          <p className="text-center text-sm text-muted-foreground">
            {mode === 'login' ? t('auth.switch.toRegister') : t('auth.switch.toLogin')}{' '}
            <button
              type="button"
              onClick={() => switchMode(mode === 'login' ? 'register' : 'login')}
              className="font-medium text-primary underline-offset-4 hover:underline"
            >
              {mode === 'login' ? t('auth.switch.toRegisterAction') : t('auth.switch.toLoginAction')}
            </button>
          </p>
        )}
      </form>

      <p className="flex items-center justify-center gap-1.5 text-center text-xs text-muted-foreground">
        <ShieldCheck className="h-3.5 w-3.5 shrink-0" />
        {t('auth.privacy')}
      </p>
    </div>
  );
}
