"use client"

import { Switch } from "./ui/switch"
import { FlaskConical, AlertCircle, Info } from "lucide-react"
import { useConfig } from "@/contexts/ConfigContext"
import { BetaFeatureKey } from "@/types/betaFeatures"
import { useT } from "@/i18n"

export function BetaSettings() {
  const { betaFeatures, toggleBetaFeature } = useConfig();
  const t = useT();

  // Define feature order for display (allows custom ordering)
  const featureOrder: BetaFeatureKey[] = ['importAndRetranscribe'];

  return (
    <div className="space-y-4">
      {/* Warning Banner */}
      <div className="flex items-start gap-3 rounded-xl bg-warning/10 p-4">
        <AlertCircle className="h-5 w-5 text-warning flex-shrink-0 mt-0.5" />
        <div className="text-sm text-warning">
          <p className="font-medium">{t('settings.beta.bannerTitle')}</p>
          <p className="mt-1">{t('settings.beta.bannerBody')}</p>
        </div>
      </div>

      {/* Dynamic Feature Toggles - Automatically renders all features */}
      {featureOrder.map((featureKey) => (
        <section
          key={featureKey}
          className="bg-card border border-border rounded-xl shadow-card p-5"
        >
          <div className="flex items-center justify-between gap-6">
            <div className="flex-1 min-w-0">
              <div className="flex flex-wrap items-center gap-2 mb-1">
                <FlaskConical className="h-4 w-4 text-muted-foreground" />
                <h3 className="text-base font-semibold text-foreground">
                  {t(`settings.beta.features.${featureKey}.name`)}
                </h3>
                <span className="rounded-full bg-warning/10 px-2 py-0.5 text-xs font-medium text-warning">
                  {t('settings.beta.badge')}
                </span>
              </div>
              <p className="text-xs text-muted-foreground">
                {t(`settings.beta.features.${featureKey}.description`)}
              </p>
            </div>

            <Switch
              checked={betaFeatures[featureKey]}
              onCheckedChange={(checked) => toggleBetaFeature(featureKey, checked)}
            />
          </div>
        </section>
      ))}

      {/* Info Box */}
      <div className="flex items-start gap-2 rounded-xl bg-accent px-4 py-3">
        <Info className="h-4 w-4 text-primary flex-shrink-0 mt-0.5" />
        <p className="text-xs text-accent-foreground">{t('settings.beta.note')}</p>
      </div>
    </div>
  );
}
