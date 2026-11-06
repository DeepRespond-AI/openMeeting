import { toast } from 'sonner';
import Analytics from '@/lib/analytics';
import { t } from '@/i18n';

/**
 * Shows the (localized) recording notification toast with compliance message.
 * Checks user preferences and displays a dismissible toast with:
 * - notice to inform participants
 * - "Don't show again" checkbox
 * - Acknowledgment button
 *
 * @returns Promise<void> - Resolves when notification is shown or skipped
 */
export async function showRecordingNotification(): Promise<void> {
  try {
    const { Store } = await import('@tauri-apps/plugin-store');
    const store = await Store.load('preferences.json');
    const showNotification = await store.get<boolean>('show_recording_notification') ?? true;

    if (showNotification) {
      let dontShowAgain = false;

      const toastId = toast.info(t('recording.notice.title'), {
        description: (
          <div className="min-w-0 space-y-3">
            <p className="text-sm font-medium text-foreground">{t('recording.notice.body')}</p>
            <label className="flex cursor-pointer items-center gap-2 rounded-md p-1.5 text-xs text-muted-foreground transition-colors hover:bg-accent">
              <input
                type="checkbox"
                onChange={(e) => {
                  dontShowAgain = e.target.checked;
                }}
                className="h-3.5 w-3.5 rounded border-input accent-primary"
              />
              <span className="select-none">{t('recording.notice.dontShowAgain')}</span>
            </label>
            <button
              onClick={async () => {
                if (dontShowAgain) {
                  const { Store } = await import('@tauri-apps/plugin-store');
                  const store = await Store.load('preferences.json');
                  await store.set('show_recording_notification', false);
                  await store.save();
                }
                Analytics.trackButtonClick('recording_notification_acknowledged', 'toast');
                toast.dismiss(toastId);
              }}
              className="w-full rounded-md bg-primary px-3 py-1.5 text-xs font-medium text-primary-foreground transition-colors hover:bg-primary/90"
            >
              {t('recording.notice.acknowledge')}
            </button>
          </div>
        ),
        position: 'bottom-right',
      });
    }
  } catch (notificationError) {
    console.error('Failed to show recording notification:', notificationError);
    // Don't fail the recording if notification fails
  }
}
