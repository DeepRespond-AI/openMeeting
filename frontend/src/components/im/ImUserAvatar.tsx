'use client';
import { useMe, useUser } from '@deeprespond/im-web-react';
import { UserAvatar } from '@/components/auth/UserAvatar';

/** Subscribe to SDK-owned profiles; users.get also hydrates its shared cache. */
export function useImUser(username: string | undefined, fallbackName?: string | null) {
  const me = useMe();
  const profile = useUser(username ?? '');
  const user = me?.username === username ? me : profile;
  return { name: user?.nickname?.trim() || fallbackName || username || '?', avatarUrl: user?.avatar_url || '' };
}

export function ImUserAvatar({ username, name, ...props }: Omit<React.ComponentProps<typeof UserAvatar>, 'src'> & { username?: string }) {
  const profile = useImUser(username, name);
  return <UserAvatar {...props} name={profile.name} src={profile.avatarUrl} />;
}

/** Identity lives outside the bubble, with the small name underneath the avatar. */
export function MessageSender({ username, name }: { username: string; name?: string }) {
  const profile = useImUser(username, name);
  return <div data-testid="message-sender" className="flex w-12 shrink-0 flex-col items-center gap-1 pt-0.5">
    <UserAvatar name={profile.name} src={profile.avatarUrl} label={profile.name} size="sm" />
    <span data-testid="message-sender-name" title={profile.name} className="line-clamp-2 w-full break-words text-center text-[10px] leading-[14px] text-muted-foreground [overflow-wrap:anywhere]">{profile.name}</span>
  </div>;
}
