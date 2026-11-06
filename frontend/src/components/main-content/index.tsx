'use client';

import React from 'react';
import { cn } from '@/lib/utils';

interface MainContentProps {
  children: React.ReactNode;
}

/** Content area to the right of the fixed 64px NavRail. Pages own their padding (UI_design.md: p-6). */
const MainContent: React.FC<MainContentProps> = ({ children }) => {
  return (
    <main
      className={cn(
        'ml-16 h-full min-h-0 min-w-0 flex-1 overflow-hidden bg-background transition-[margin] duration-300',
      )}
    >
      <div data-testid="desktop-content" className="relative z-[1] h-full min-h-0 w-full min-w-0 max-w-full overflow-hidden [overflow-wrap:anywhere]">{children}</div>
    </main>
  );
};

export default MainContent;
