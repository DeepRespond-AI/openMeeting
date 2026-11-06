'use client';

import React, { forwardRef, useState } from 'react';
import { Eye, EyeOff, LockKeyhole } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { useT } from '@/i18n';
import { DEFAULT_PASSWORD_RULES, type PasswordProblem, type PasswordRules } from '@/lib/password';
import type { AuthConfig } from '@/lib/server';
import { cn } from '@/lib/utils';

type PasswordInputProps = Omit<React.ComponentProps<typeof Input>, 'type'>;

/** Password field with a lock icon and a show/hide toggle. */
export const PasswordInput = forwardRef<HTMLInputElement, PasswordInputProps>(({ className, ...props }, ref) => {
  const t = useT();
  const [visible, setVisible] = useState(false);
  return (
    <div className="relative">
      <LockKeyhole className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
      <Input ref={ref} type={visible ? 'text' : 'password'} className={cn('h-11 rounded-lg pl-9 pr-10', className)} {...props} />
      <button
        type="button"
        onClick={() => setVisible((v) => !v)}
        aria-label={visible ? t('auth.fields.hidePassword') : t('auth.fields.showPassword')}
        className="absolute right-2 top-1/2 flex h-7 w-7 -translate-y-1/2 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
      >
        {visible ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
      </button>
    </div>
  );
});
PasswordInput.displayName = 'PasswordInput';

/** Localized message for a client-side password rule violation. */
export function describePasswordProblem(
  problem: PasswordProblem,
  rules: PasswordRules,
  t: ReturnType<typeof useT>,
): string {
  switch (problem) {
    case 'length':
      return t('auth.errors.passwordLength', { min: rules.minLength, max: rules.maxLength });
    case 'spaces':
      return t('auth.errors.passwordSpaces');
    case 'letterDigit':
      return t('auth.errors.passwordLetterDigit');
  }
}

/** Password rules advertised by the server (`auth/config`), with the documented defaults. */
export function passwordRulesOf(config: AuthConfig | null | undefined): PasswordRules {
  return {
    minLength: config?.password_min_length || DEFAULT_PASSWORD_RULES.minLength,
    maxLength: config?.password_max_length || DEFAULT_PASSWORD_RULES.maxLength,
  };
}
