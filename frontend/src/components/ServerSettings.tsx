'use client';

import React from 'react';
import { useServer } from '@/contexts/ServerContext';
import { AccountCard } from '@/components/auth/AccountCard';

/** Settings → Account: the signed-in account (service details are not shown to users). */
export function ServerSettings() {
  const { loggedIn } = useServer();
  return <div className="space-y-4">{loggedIn && <AccountCard />}</div>;
}
