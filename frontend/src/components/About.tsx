'use client';

import React, { useEffect, useState } from 'react';
import { getVersion } from '@tauri-apps/api/app';
import { Loader2, RefreshCw } from 'lucide-react';
import { BrandLogo } from '@/components/brand/BrandLogo';
import { Button } from '@/components/ui/button';
import { useUpdateCheckContext } from '@/components/UpdateCheckProvider';
import { useT } from '@/i18n';

/** Settings → About: logo, product name, version, "check for updates" and the copyright line. */
export function About() {
  const t = useT();
  const [version, setVersion] = useState<string | null>(null);
  const { isChecking, checkForUpdates } = useUpdateCheckContext();

  useEffect(() => {
    getVersion()
      .then(setVersion)
      .catch((error) => console.error('[About] Failed to read app version:', error));
  }, []);

  const app = t('common.appName');

  return (
    <div className="flex flex-col items-center text-center">
      <div className="mb-4 rounded-2xl bg-accent p-4">
        <BrandLogo size={56} />
      </div>
      <h2 className="text-xl font-semibold text-foreground">{app}</h2>
      {version && (
        <span className="mt-2 inline-flex items-center rounded-full bg-muted px-2.5 py-0.5 text-xs font-medium text-muted-foreground">
          {t('nav.about.version', { version })}
        </span>
      )}
      <p className="mt-3 max-w-sm text-sm text-muted-foreground">{t('nav.about.description')}</p>
      <Button variant="outline" size="sm" className="mt-4 rounded-lg" disabled={isChecking} onClick={() => void checkForUpdates()}>
        {isChecking ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
        {isChecking ? t('update.about.checking') : t('update.about.check')}
      </Button>
      <div className="mt-6 w-full border-t border-border pt-4 text-xs text-muted-foreground">
        <p>{t('nav.about.copyright', { year: new Date().getFullYear(), app })}</p>
      </div>
    </div>
  );
}
