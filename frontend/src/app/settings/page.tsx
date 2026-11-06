'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { ArrowLeft, Settings2, Mic, UserRound, FlaskConical, Info } from 'lucide-react';
import { useRouter, useSearchParams } from 'next/navigation';
import { RecordingSettings } from '@/components/RecordingSettings';
import { PreferenceSettings } from '@/components/PreferenceSettings';
import { ServerSettings } from '@/components/ServerSettings';
import { BetaSettings } from '@/components/BetaSettings';
import { About } from '@/components/About';
import { Button } from '@/components/ui/button';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';

// Tabs configuration (constant)
const TABS = [
  { value: 'server', labelKey: 'settings.tabs.server', icon: UserRound },
  { value: 'general', labelKey: 'settings.tabs.general', icon: Settings2 },
  { value: 'recording', labelKey: 'settings.tabs.recording', icon: Mic },
  { value: 'beta', labelKey: 'settings.tabs.beta', icon: FlaskConical },
  { value: 'about', labelKey: 'settings.tabs.about', icon: Info },
] as const;

type TabValue = typeof TABS[number]['value'];

function isTabValue(value: string | null): value is TabValue {
  return !!value && TABS.some(tab => tab.value === value);
}

export default function SettingsPage() {
  return (
    <Suspense fallback={null}>
      <SettingsPageContent />
    </Suspense>
  );
}

function SettingsPageContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const requestedTab = searchParams.get('tab');
  const t = useT();

  const [activeTab, setActiveTab] = useState<TabValue>(isTabValue(requestedTab) ? requestedTab : 'server');

  // Follow ?tab= when navigating to settings from elsewhere (e.g. "server not connected" prompts)
  useEffect(() => {
    if (isTabValue(requestedTab)) {
      setActiveTab(requestedTab);
    }
  }, [requestedTab]);

  return (
    <div className="h-full min-h-0 min-w-0 bg-background flex flex-col">
      {/* Page header */}
      <div className="sticky top-0 z-10 bg-background border-b border-border">
        <div className="max-w-6xl mx-auto px-4 py-4 sm:px-6 sm:py-5 flex items-start gap-3">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => router.back()}
            title={t('common.actions.back')}
            aria-label={t('common.actions.back')}
            className="shrink-0 -ml-2"
          >
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div className="min-w-0">
            <h1 className="text-xl font-semibold text-foreground">{t('settings.page.title')}</h1>
            <p className="text-sm text-muted-foreground mt-0.5">{t('settings.page.description')}</p>
          </div>
        </div>
      </div>

      {/* Scrollable content */}
      <div className="min-h-0 min-w-0 flex-1 overflow-y-auto overscroll-contain">
        <div className="max-w-6xl mx-auto p-4 sm:p-6 flex flex-col md:flex-row gap-4 md:gap-6 items-start">
          {/* Tab list */}
          <nav
            role="tablist"
            aria-orientation="vertical"
            aria-label={t('settings.tabs.label')}
            className="w-full md:w-52 md:sticky md:top-0 shrink-0 bg-card border border-border rounded-xl shadow-card p-2 flex md:flex-col gap-1 overflow-x-auto"
          >
            {TABS.map((tab) => {
              const Icon = tab.icon;
              const active = activeTab === tab.value;
              return (
                <button
                  key={tab.value}
                  type="button"
                  role="tab"
                  id={`settings-tab-${tab.value}`}
                  aria-selected={active}
                  aria-controls={`settings-panel-${tab.value}`}
                  onClick={() => setActiveTab(tab.value)}
                  className={cn(
                    'flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium whitespace-nowrap transition-colors text-left',
                    active
                      ? 'bg-accent text-primary'
                      : 'text-muted-foreground hover:bg-accent/60 hover:text-foreground',
                  )}
                >
                  <Icon className="h-[18px] w-[18px] shrink-0" />
                  <span className="truncate">{t(tab.labelKey)}</span>
                </button>
              );
            })}
          </nav>

          {/* Content */}
          <div
            role="tabpanel"
            id={`settings-panel-${activeTab}`}
            aria-labelledby={`settings-tab-${activeTab}`}
            className="flex-1 min-w-0 w-full"
          >
            {activeTab === 'server' && <ServerSettings />}
            {activeTab === 'general' && <PreferenceSettings />}
            {activeTab === 'recording' && <RecordingSettings />}
            {activeTab === 'beta' && <BetaSettings />}
            {activeTab === 'about' && (
              <section className="rounded-xl border border-border bg-card p-8 shadow-card">
                <About />
              </section>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
