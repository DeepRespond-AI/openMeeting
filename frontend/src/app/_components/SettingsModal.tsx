import { AlertTriangle, OctagonAlert, RefreshCw } from "lucide-react";
import { PreferenceSettings } from "@/components/PreferenceSettings";
import { DeviceSelection } from "@/components/DeviceSelection";
import { LanguageSelection } from "@/components/LanguageSelection";
import { useServer } from "@/contexts/ServerContext";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { toast } from "sonner";
import { useConfig } from "@/contexts/ConfigContext";
import { useRecordingState } from "@/contexts/RecordingStateContext";
import { useT } from "@/i18n";
import { cn } from "@/lib/utils";

type modalType = "modelSettings" | "deviceSettings" | "languageSettings" | "modelSelector" | "errorAlert" | "chunkDropWarning";

/**
 * SettingsModals Component
 *
 * All settings modals consolidated into a single component.
 * Uses ConfigContext and RecordingStateContext internally - no prop drilling needed!
 */

interface SettingsModalsProps {
  modals: {
    modelSettings: boolean;
    deviceSettings: boolean;
    languageSettings: boolean;
    modelSelector: boolean;
    errorAlert: boolean;
    chunkDropWarning: boolean;
  };
  messages: {
    errorAlert: string;
    chunkDropWarning: string;
    modelSelector: string;
  };
  onClose: (name: modalType) => void;
}

const dialogSurface = "rounded-xl sm:rounded-xl border-border bg-card shadow-elevated";

export function SettingsModals({
  modals,
  messages,
  onClose,
}: SettingsModalsProps) {
  const t = useT();
  // Contexts
  const {
    selectedDevices,
    setSelectedDevices,
    selectedLanguage,
    setSelectedLanguage,
    showConfidenceIndicator,
    toggleConfidenceIndicator,
  } = useConfig();
  const { refresh: refreshServerStatus } = useServer();

  const { isRecording } = useRecordingState();

  const closeOnDismiss = (name: modalType) => (open: boolean) => {
    if (!open) onClose(name);
  };

  return <>
    {/* Preferences Modal */}
    <Dialog open={modals.modelSettings} onOpenChange={closeOnDismiss("modelSettings")}>
      <DialogContent className={cn(dialogSurface, "max-w-4xl max-h-[90vh] p-0 gap-0 flex flex-col overflow-hidden")}>
        <DialogHeader className="px-6 pt-6 pb-4 border-b border-border">
          <DialogTitle className="text-xl font-semibold">{t('dialogs.settingsModal.preferencesTitle')}</DialogTitle>
          <DialogDescription>{t('dialogs.settingsModal.preferencesDescription')}</DialogDescription>
        </DialogHeader>

        {/* Content - Scrollable */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* General Preferences Section */}
          <PreferenceSettings />
        </div>

        <DialogFooter className="px-6 py-4 border-t border-border">
          <Button className="rounded-lg" onClick={() => onClose('modelSettings')}>
            {t('common.actions.done')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    {/* Device Settings Modal */}
    <Dialog open={modals.deviceSettings} onOpenChange={closeOnDismiss("deviceSettings")}>
      <DialogContent className={cn(dialogSurface, "max-w-md")}>
        <DialogHeader>
          <DialogTitle className="text-base font-semibold">{t('dialogs.settingsModal.deviceTitle')}</DialogTitle>
          <DialogDescription>{t('dialogs.settingsModal.deviceDescription')}</DialogDescription>
        </DialogHeader>

        <DeviceSelection
          selectedDevices={selectedDevices}
          onDeviceChange={setSelectedDevices}
          disabled={isRecording}
        />

        <DialogFooter>
          <Button
            className="rounded-lg"
            onClick={() => {
              const micDevice = selectedDevices.micDevice || t('dialogs.settingsModal.defaultDevice');
              const systemDevice = selectedDevices.systemDevice || t('dialogs.settingsModal.defaultDevice');
              toast.success(t('dialogs.settingsModal.devicesSelectedToast'), {
                description: t('dialogs.settingsModal.devicesSelectedDetail', { mic: micDevice, system: systemDevice }),
              });
              onClose('deviceSettings');
            }}
          >
            {t('common.actions.done')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    {/* Language Settings Modal */}
    <Dialog open={modals.languageSettings} onOpenChange={closeOnDismiss("languageSettings")}>
      <DialogContent className={cn(dialogSurface, "max-w-md")}>
        <DialogHeader>
          <DialogTitle className="text-base font-semibold">{t('dialogs.settingsModal.languageTitle')}</DialogTitle>
          <DialogDescription>{t('dialogs.settingsModal.languageDescription')}</DialogDescription>
        </DialogHeader>

        <LanguageSelection
          selectedLanguage={selectedLanguage}
          onLanguageChange={setSelectedLanguage}
          disabled={isRecording}
        />

        <DialogFooter>
          <Button className="rounded-lg" onClick={() => onClose('languageSettings')}>
            {t('common.actions.done')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    {/* Server not ready modal (replaces the old local model selector) */}
    <Dialog open={modals.modelSelector} onOpenChange={closeOnDismiss("modelSelector")}>
      <DialogContent className={cn(dialogSurface, "max-w-lg max-h-[90vh] p-0 gap-0 flex flex-col overflow-hidden")}>
        <DialogHeader className="px-6 pt-6 pb-4 border-b border-border">
          <DialogTitle className="text-base font-semibold">
            {t('dialogs.settingsModal.serverNotReadyTitle')}
          </DialogTitle>
          <DialogDescription className="leading-relaxed">
            {t('dialogs.settingsModal.serverNotReadyHint')}
          </DialogDescription>
        </DialogHeader>

        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.modelSelector && (
            <div className="flex items-start gap-2 rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-sm text-destructive">
              <OctagonAlert className="h-4 w-4 mt-0.5 shrink-0" />
              <p className="break-words">{messages.modelSelector}</p>
            </div>
          )}
        </div>

        <div className="px-6 py-4 border-t border-border flex flex-wrap items-center justify-between gap-3">
          <label className="flex items-center gap-2 cursor-pointer">
            <Switch
              checked={showConfidenceIndicator}
              onCheckedChange={(checked) => toggleConfidenceIndicator(checked)}
            />
            <span className="text-sm text-foreground">{t('dialogs.settingsModal.showConfidence')}</span>
          </label>

          <div className="flex gap-2">
            <Button
              variant="outline"
              className="rounded-lg"
              onClick={() => void refreshServerStatus()}
            >
              <RefreshCw className="h-4 w-4" />
              {t('dialogs.settingsModal.recheck')}
            </Button>
            <Button className="rounded-lg" onClick={() => onClose('modelSelector')}>
              {t('common.actions.done')}
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>

    {/* Error Alert Modal */}
    <Dialog open={modals.errorAlert} onOpenChange={closeOnDismiss("errorAlert")}>
      <DialogContent className={cn(dialogSurface, "max-w-md")}>
        <DialogHeader>
          <DialogTitle className="text-base font-semibold flex items-center gap-2 text-destructive">
            <OctagonAlert className="h-4 w-4" />
            {t('dialogs.settingsModal.recordingStoppedTitle')}
          </DialogTitle>
          <DialogDescription className="leading-relaxed break-words">
            {messages.errorAlert}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" className="rounded-lg" onClick={() => onClose('errorAlert')}>
            {t('dialogs.settingsModal.dismiss')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    {/* Chunk Drop Warning Modal */}
    <Dialog open={modals.chunkDropWarning} onOpenChange={closeOnDismiss("chunkDropWarning")}>
      <DialogContent className={cn(dialogSurface, "max-w-lg")}>
        <DialogHeader>
          <DialogTitle className="text-base font-semibold flex items-center gap-2">
            <span className="inline-flex h-7 w-7 items-center justify-center rounded-full bg-warning/10 text-warning">
              <AlertTriangle className="h-4 w-4" />
            </span>
            {t('dialogs.settingsModal.performanceWarningTitle')}
          </DialogTitle>
          <DialogDescription className="leading-relaxed break-words">
            {messages.chunkDropWarning}
          </DialogDescription>
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" className="rounded-lg" onClick={() => onClose('chunkDropWarning')}>
            {t('dialogs.settingsModal.dismiss')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </>
}
