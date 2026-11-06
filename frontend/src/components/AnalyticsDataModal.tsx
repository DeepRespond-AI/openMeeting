'use client';

import React from 'react';
import { Info, Shield, XCircle } from 'lucide-react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { useT, type TranslationKey } from '@/i18n';

interface AnalyticsDataModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirmDisable: () => void;
}

interface Category {
  title: TranslationKey;
  items: TranslationKey[];
  why: TranslationKey;
}

const CATEGORIES: Category[] = [
  {
    title: 'settings.analytics.modal.models.title',
    items: [
      'settings.analytics.modal.models.item1',
      'settings.analytics.modal.models.item2',
      'settings.analytics.modal.models.item3',
    ],
    why: 'settings.analytics.modal.models.why',
  },
  {
    title: 'settings.analytics.modal.metrics.title',
    items: [
      'settings.analytics.modal.metrics.item1',
      'settings.analytics.modal.metrics.item2',
      'settings.analytics.modal.metrics.item3',
      'settings.analytics.modal.metrics.item4',
    ],
    why: 'settings.analytics.modal.metrics.why',
  },
  {
    title: 'settings.analytics.modal.devices.title',
    items: [
      'settings.analytics.modal.devices.item1',
      'settings.analytics.modal.devices.item2',
    ],
    why: 'settings.analytics.modal.devices.why',
  },
  {
    title: 'settings.analytics.modal.usage.title',
    items: [
      'settings.analytics.modal.usage.item1',
      'settings.analytics.modal.usage.item2',
      'settings.analytics.modal.usage.item3',
      'settings.analytics.modal.usage.item4',
    ],
    why: 'settings.analytics.modal.usage.why',
  },
  {
    title: 'settings.analytics.modal.platform.title',
    items: [
      'settings.analytics.modal.platform.item1',
      'settings.analytics.modal.platform.item2',
      'settings.analytics.modal.platform.item3',
    ],
    why: 'settings.analytics.modal.platform.why',
  },
];

const NOT_COLLECTED: TranslationKey[] = [
  'settings.analytics.modal.notCollected.item1',
  'settings.analytics.modal.notCollected.item2',
  'settings.analytics.modal.notCollected.item3',
  'settings.analytics.modal.notCollected.item4',
  'settings.analytics.modal.notCollected.item5',
  'settings.analytics.modal.notCollected.item6',
  'settings.analytics.modal.notCollected.item7',
];

// Sample payload shown verbatim (technical data, not translated).
const EXAMPLE_EVENT = `{
  "event": "meeting_ended",
  "app_version": "0.1.0",
  "transcription_provider": "parakeet",
  "transcription_model": "parakeet-tdt-0.6b-v3-int8",
  "summary_provider": "ollama",
  "summary_model": "llama3.2:latest",
  "total_duration_seconds": "125.5",
  "microphone_device_type": "Wired",
  "system_audio_device_type": "Bluetooth",
  "chunks_processed": "150",
  "had_fatal_error": "false"
}`;

export default function AnalyticsDataModal({ isOpen, onClose, onConfirmDisable }: AnalyticsDataModalProps) {
  const t = useT();

  return (
    <Dialog open={isOpen} onOpenChange={(open) => { if (!open) onClose(); }}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto rounded-xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5 text-primary" />
            {t('settings.analytics.modal.title')}
          </DialogTitle>
          <DialogDescription>{t('settings.analytics.modal.description')}</DialogDescription>
        </DialogHeader>

        <div className="space-y-5">
          {/* Privacy Notice */}
          <div className="flex items-start gap-3 rounded-lg bg-success/10 p-4">
            <Info className="h-5 w-5 text-success mt-0.5 flex-shrink-0" />
            <div className="text-sm text-success">
              <p className="font-semibold mb-1">{t('settings.analytics.modal.privacyTitle')}</p>
              <p>{t('settings.analytics.modal.privacyBody')}</p>
            </div>
          </div>

          {/* Data Categories */}
          <div className="space-y-3">
            <h3 className="text-base font-semibold text-foreground">{t('settings.analytics.modal.collectTitle')}</h3>
            {CATEGORIES.map((category) => (
              <div key={category.title} className="rounded-lg border border-border p-4">
                <h4 className="text-sm font-semibold text-foreground mb-2">{t(category.title)}</h4>
                <ul className="text-sm text-foreground space-y-1 list-disc pl-5">
                  {category.items.map((item) => (
                    <li key={item}>{t(item)}</li>
                  ))}
                </ul>
                <p className="text-xs text-muted-foreground mt-2">{t(category.why)}</p>
              </div>
            ))}
          </div>

          {/* What is never collected */}
          <div className="rounded-lg bg-destructive/10 p-4">
            <h4 className="text-sm font-semibold text-destructive mb-2">{t('settings.analytics.modal.notCollected.title')}</h4>
            <ul className="text-sm text-destructive space-y-1">
              {NOT_COLLECTED.map((item) => (
                <li key={item} className="flex items-start gap-2">
                  <XCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
                  <span>{t(item)}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Example Event */}
          <div className="rounded-lg border border-border bg-muted p-4">
            <h4 className="text-sm font-semibold text-foreground mb-2">{t('settings.analytics.modal.exampleTitle')}</h4>
            <pre className="text-xs text-muted-foreground overflow-x-auto">{EXAMPLE_EVENT}</pre>
          </div>
        </div>

        <DialogFooter className="gap-2">
          <Button variant="outline" onClick={onClose}>
            {t('settings.analytics.modal.keepEnabled')}
          </Button>
          <Button variant="destructive" onClick={onConfirmDisable}>
            {t('settings.analytics.modal.confirmDisable')}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
