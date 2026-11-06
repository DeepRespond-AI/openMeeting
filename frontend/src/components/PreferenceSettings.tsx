"use client"

import { useEffect, useState, useRef } from "react"
import { Switch } from "./ui/switch"
import { FolderOpen } from "lucide-react"
import { invoke } from "@tauri-apps/api/core"
import Analytics from "@/lib/analytics"
import AnalyticsConsentSwitch from "./AnalyticsConsentSwitch"
import { useConfig, NotificationSettings } from "@/contexts/ConfigContext"
import { Button } from "./ui/button"
import { LanguageSwitcher } from "./brand/LanguageSwitcher"
import { useT } from "@/i18n"

export function PreferenceSettings() {
  const t = useT();
  const {
    notificationSettings,
    storageLocations,
    isLoadingPreferences,
    loadPreferences,
    updateNotificationSettings,
    isAutoSummary,
    toggleIsAutoSummary,
  } = useConfig();

  const [notificationsEnabled, setNotificationsEnabled] = useState<boolean | null>(null);
  const [isInitialLoad, setIsInitialLoad] = useState(true);
  const [previousNotificationsEnabled, setPreviousNotificationsEnabled] = useState<boolean | null>(null);
  const hasTrackedViewRef = useRef(false);

  // Lazy load preferences on mount (only loads if not already cached)
  useEffect(() => {
    loadPreferences();
    // Reset tracking ref on mount (every tab visit)
    hasTrackedViewRef.current = false;
  }, [loadPreferences]);

  // Track preferences viewed analytics on every tab visit (once per mount)
  useEffect(() => {
    if (hasTrackedViewRef.current) return;

    const trackPreferencesViewed = async () => {
      // Wait for notification settings to be available (either from cache or after loading)
      if (notificationSettings) {
        await Analytics.track('preferences_viewed', {
          notifications_enabled: notificationSettings.notification_preferences.show_recording_started ? 'true' : 'false'
        });
        hasTrackedViewRef.current = true;
      } else if (!isLoadingPreferences) {
        // If not loading and no settings available, track with default value
        await Analytics.track('preferences_viewed', {
          notifications_enabled: 'false'
        });
        hasTrackedViewRef.current = true;
      }
    };

    trackPreferencesViewed();
  }, [notificationSettings, isLoadingPreferences]);

  // Update notificationsEnabled when notificationSettings are loaded from global state
  useEffect(() => {
    if (notificationSettings) {
      // Notification enabled means both started and stopped notifications are enabled
      const enabled =
        notificationSettings.notification_preferences.show_recording_started &&
        notificationSettings.notification_preferences.show_recording_stopped;
      setNotificationsEnabled(enabled);
      if (isInitialLoad) {
        setPreviousNotificationsEnabled(enabled);
        setIsInitialLoad(false);
      }
    } else if (!isLoadingPreferences) {
      // If not loading and no settings, use default
      setNotificationsEnabled(true);
      if (isInitialLoad) {
        setPreviousNotificationsEnabled(true);
        setIsInitialLoad(false);
      }
    }
  }, [notificationSettings, isLoadingPreferences, isInitialLoad])

  useEffect(() => {
    // Skip update on initial load or if value hasn't actually changed
    if (isInitialLoad || notificationsEnabled === null || notificationsEnabled === previousNotificationsEnabled) return;
    if (!notificationSettings) return;

    const handleUpdateNotificationSettings = async () => {
      console.log("Updating notification settings to:", notificationsEnabled);

      try {
        // Update the notification preferences
        const updatedSettings: NotificationSettings = {
          ...notificationSettings,
          notification_preferences: {
            ...notificationSettings.notification_preferences,
            show_recording_started: notificationsEnabled,
            show_recording_stopped: notificationsEnabled,
          }
        };

        console.log("Calling updateNotificationSettings with:", updatedSettings);
        await updateNotificationSettings(updatedSettings);
        setPreviousNotificationsEnabled(notificationsEnabled);
        console.log("Successfully updated notification settings to:", notificationsEnabled);

        // Track notification preference change - only fires when user manually toggles
        await Analytics.track('notification_settings_changed', {
          notifications_enabled: notificationsEnabled.toString()
        });
      } catch (error) {
        console.error('Failed to update notification settings:', error);
      }
    };

    handleUpdateNotificationSettings();
  }, [notificationsEnabled, notificationSettings, isInitialLoad, previousNotificationsEnabled, updateNotificationSettings])

  const handleOpenRecordingsFolder = async () => {
    try {
      await invoke('open_recordings_folder');

      // Track storage folder access
      await Analytics.track('storage_folder_opened', {
        folder_type: 'recordings'
      });
    } catch (error) {
      console.error('Failed to open recordings folder:', error);
    }
  };

  // Show loading only if we're actually loading and don't have cached data
  if (isLoadingPreferences && !notificationSettings && !storageLocations) {
    return <div className="p-6 text-sm text-muted-foreground">{t('settings.general.loading')}</div>
  }

  // Show loading if notificationsEnabled hasn't been determined yet
  if (notificationsEnabled === null && !isLoadingPreferences) {
    return <div className="p-6 text-sm text-muted-foreground">{t('settings.general.loading')}</div>
  }

  // Ensure we have a boolean value for the Switch component
  const notificationsEnabledValue = notificationsEnabled ?? false;

  return (
    <div className="space-y-4">
      {/* Language Section */}
      <section className="bg-card border border-border rounded-xl shadow-card p-5">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="min-w-0">
            <h3 className="text-base font-semibold text-foreground">{t('settings.language.title')}</h3>
            <p className="text-xs text-muted-foreground mt-1">{t('settings.language.description')}</p>
          </div>
          <LanguageSwitcher variant="segmented" />
        </div>
      </section>

      {/* Notifications Section */}
      <section className="bg-card border border-border rounded-xl shadow-card p-5">
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <h3 className="text-base font-semibold text-foreground">{t('settings.general.notifications.title')}</h3>
            <p className="text-xs text-muted-foreground mt-1">{t('settings.general.notifications.description')}</p>
          </div>
          <Switch checked={notificationsEnabledValue} onCheckedChange={setNotificationsEnabled} />
        </div>
      </section>

      {/* Data Storage Locations Section */}
      <section className="bg-card border border-border rounded-xl shadow-card p-5">
        <h3 className="text-base font-semibold text-foreground">{t('settings.general.storage.title')}</h3>
        <p className="text-xs text-muted-foreground mt-1 mb-4">
          {t('settings.general.storage.description', { appName: t('common.appName') })}
        </p>

        <div className="rounded-lg border border-border bg-muted/50 p-4">
          <div className="text-sm font-medium text-foreground mb-1.5">{t('settings.general.storage.recordings')}</div>
          <div className="text-xs text-muted-foreground mb-3 break-all font-mono">
            {storageLocations?.recordings || t('common.status.loading')}
          </div>
          <Button variant="outline" size="sm" onClick={handleOpenRecordingsFolder}>
            <FolderOpen className="h-4 w-4" />
            {t('settings.general.storage.openFolder')}
          </Button>
        </div>

        <div className="mt-4 rounded-lg bg-accent px-3 py-2.5">
          <p className="text-xs text-accent-foreground">{t('settings.general.storage.note')}</p>
        </div>
      </section>

      {/* Summary Section */}
      <section className="bg-card border border-border rounded-xl shadow-card p-5">
        <div className="flex items-center justify-between gap-4">
          <div className="min-w-0">
            <h3 className="text-base font-semibold text-foreground">{t('settings.general.autoSummary.title')}</h3>
            <p className="text-xs text-muted-foreground mt-1">{t('settings.general.autoSummary.description')}</p>
          </div>
          <Switch checked={isAutoSummary} onCheckedChange={toggleIsAutoSummary} />
        </div>
      </section>

      {/* Analytics Section */}
      <section className="bg-card border border-border rounded-xl shadow-card p-5">
        <AnalyticsConsentSwitch />
      </section>
    </div>
  )
}
