import React from 'react';
import { Upload } from 'lucide-react';
import { getAudioFormatsDisplayList } from '@/constants/audioFormats';
import { useT } from '@/i18n';

interface ImportDropOverlayProps {
  visible: boolean;
}

export function ImportDropOverlay({ visible }: ImportDropOverlayProps) {
  const t = useT();
  if (!visible) return null;

  return (
    <div
      className="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-foreground/30 p-6 backdrop-blur-sm transition-opacity duration-200"
    >
      <div className="flex w-full max-w-md flex-col items-center rounded-xl border-2 border-dashed border-primary bg-card px-10 py-12 text-center shadow-elevated">
        <div className="mb-5 flex h-16 w-16 items-center justify-center rounded-full bg-brand-gradient text-white shadow-lg">
          <Upload className="h-7 w-7" />
        </div>
        <p className="text-lg font-semibold text-foreground">{t('importAudio.drop.title')}</p>
        <p className="mt-2 text-xs uppercase tracking-wide text-muted-foreground">{getAudioFormatsDisplayList()}</p>
      </div>
    </div>
  );
}
