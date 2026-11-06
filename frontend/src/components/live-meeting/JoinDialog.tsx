'use client';
import { meetingUi } from '@/config/meeting-ui';
import { LimitedInput } from '@/components/ui/limited-input';
import { limitText, ROOM_NAME_MAX } from '@/lib/field-limits';

/**
 * Join-meeting dialog (V2 design, prototype join.js): 6-digit segmented code input
 * (2 groups × 3 digits with auto-advance, backspace jump-back and paste distribution),
 * nickname, mic/cam pre-toggles. Password-protected rooms get an extra password step.
 *
 * The dialog only *collects* the join intent (sessionStorage `liveMeeting.joinIntent`) and
 * navigates to /room?code=… — the room page performs the actual join so refreshing
 * or deep-linking behaves the same way.
 */
import { useEffect, useRef, useState } from 'react';
import { KeyRound, LogIn, Mic, Video } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';
import { Dialog, DialogContent, DialogDescription, DialogTitle } from '@/components/ui/dialog';
import { Switch } from '@/components/ui/switch';
import { useT } from '@/i18n';
import { cn } from '@/lib/utils';
import { LiveMeetingApiError, getLiveMeetingApi } from '@/services/live-meeting';
import type { LiveRoom } from '@/services/live-meeting';
import { useMeetingEntry } from './MeetingEntry';
import { useOptionalServer } from '@/contexts/ServerContext';

export const JOIN_INTENT_KEY = 'liveMeeting.joinIntent';

export interface JoinIntent {
  code: string;
  name: string;
  micOn: boolean;
  camOn: boolean;
  pwd?: string;
}

interface JoinDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  defaultName: string;
  /** Prefilled code (e.g. "Join" from the home today panel). */
  initialCode?: string | null;
}

export default function JoinDialog({ open, onOpenChange, defaultName, initialCode }: JoinDialogProps) {
  const t = useT();
  const router = useRouter();
  const user = useOptionalServer()?.user;
  const { beginEntry, finishEntry } = useMeetingEntry();

  const [digits, setDigits] = useState<string[]>(Array(6).fill(''));
  const [nickname, setNickname] = useState(() => limitText(defaultName, ROOM_NAME_MAX));
  const [micOn, setMicOn] = useState(true);
  const [camOn, setCamOn] = useState(true);
  const [checking, setChecking] = useState(false);
  /** Password step for protected rooms; holds the resolved room title. */
  const [pwdRoom, setPwdRoom] = useState<LiveRoom | null>(null);
  const [pwd, setPwd] = useState('');
  const boxRefs = useRef<(HTMLInputElement | null)[]>([]);

  // Reset per open, applying any prefilled code.
  useEffect(() => {
    if (!open) return;
    const prefill = (initialCode ?? '').replace(/\D/g, '').slice(0, 6).split('');
    setDigits([...prefill, ...Array(6 - prefill.length).fill('')]);
    setNickname(limitText(defaultName, ROOM_NAME_MAX));
    setMicOn(meetingUi.audio);
    setCamOn(meetingUi.video);
    setPwdRoom(null);
    setPwd('');
    setChecking(false);
  }, [open, initialCode, defaultName]);

  const code = digits.join('');
  const codeComplete = /^\d{6}$/.test(code);

  const setDigit = (i: number, raw: string) => {
    const v = raw.replace(/\D/g, '');
    if (!v) {
      setDigits((prev) => {
        const next = [...prev];
        next[i] = '';
        return next;
      });
      return;
    }
    if (v.length === 1) {
      setDigits((prev) => {
        const next = [...prev];
        next[i] = v;
        return next;
      });
      if (i < 5) boxRefs.current[i + 1]?.focus();
      return;
    }
    // Multiple characters at once (fast typing, autofill, paste into one box):
    // distribute across the remaining boxes.
    setDigits((prev) => {
      const next = [...prev];
      for (let k = 0; k < v.length && i + k < 6; k++) next[i + k] = v[k];
      return next;
    });
    const last = Math.min(i + v.length, 5);
    boxRefs.current[last]?.focus();
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const text = (e.clipboardData.getData('text') ?? '').replace(/\D/g, '').slice(0, 6);
    if (!text) return;
    setDigits([...text.split(''), ...Array(6 - text.length).fill('')]);
    boxRefs.current[Math.min(text.length, 5)]?.focus();
  };

  const proceed = (room: LiveRoom, finalPwd?: string) => {
    const intent: JoinIntent = {
      code: room.code,
      name: limitText(nickname.trim() || defaultName, ROOM_NAME_MAX),
      micOn: meetingUi.audio && micOn,
      camOn: meetingUi.video && camOn,
      ...(finalPwd ? { pwd: finalPwd } : {}),
    };
    try {
      sessionStorage.setItem(JOIN_INTENT_KEY, JSON.stringify(intent));
    } catch {
      /* storage unavailable — room page falls back to defaults */
    }
    onOpenChange(false);
    router.push(`/room?code=${room.code}`);
  };

  const join = async () => {
    if (!codeComplete) {
      toast.error(t('liveMeeting.join.errIncomplete'));
      return;
    }
    setChecking(true);
    beginEntry();
    try {
      const room = await getLiveMeetingApi().checkRoomCode(code);
      if (room.pwdEnabled && (!user?.id || room.hostUserId !== user.id) && !pwdRoom) {
        setPwdRoom(room); // host password check happens server-side at join time
        setChecking(false);
        finishEntry();
        return;
      }
      proceed(room, pwd || undefined);
    } catch (err) {
      finishEntry();
      setChecking(false);
      if (err instanceof LiveMeetingApiError) {
        const keys: Record<LiveMeetingApiError['code'], Parameters<typeof t>[0]> = {
          not_found: 'liveMeeting.join.errNotFound',
          not_started: 'liveMeeting.join.errNotStarted',
          ended: 'liveMeeting.join.errEnded',
          wrong_pwd: 'liveMeeting.join.errWrongPwd',
          full: 'liveMeeting.join.errFull',
        };
        toast.error(t(keys[err.code]));
      } else {
        toast.error(t('liveMeeting.join.errGeneric'));
      }
    }
  };

  return (
    <Dialog open={open} onOpenChange={(next) => { if (!checking) onOpenChange(next); }}>
      <DialogContent className="max-h-[92vh] max-w-[400px] overflow-y-auto rounded-2xl border-white/10 bg-[#12151D]/95 backdrop-blur-xl">
        {pwdRoom ? (
          /* ------- password step ------- */
          <div className="flex flex-col items-center gap-5 text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-gradient text-white shadow-[0_6px_16px_rgba(59,130,246,0.35)]">
              <KeyRound className="h-6 w-6" />
            </div>
            <div>
              <DialogTitle className="text-lg font-semibold text-foreground">{t('liveMeeting.join.pwdTitle')}</DialogTitle>
              <DialogDescription className="mt-1 text-[13px] text-muted-foreground">
                {t('liveMeeting.join.pwdDesc', { title: pwdRoom.title })}
              </DialogDescription>
            </div>
            <input
              type="text"
              inputMode="numeric"
              maxLength={6}
              autoFocus
              placeholder={t('liveMeeting.join.pwdPlaceholder')}
              value={pwd}
              onChange={(e) => setPwd(e.target.value.replace(/\D/g, '').slice(0, 6))}
              onKeyDown={(e) => { if (e.key === 'Enter') void join(); }}
              className="flex h-11 w-full rounded-lg border border-white/10 bg-white/[0.06] px-3 text-center text-lg font-semibold tracking-[0.3em] text-white placeholder:tracking-normal placeholder:text-muted-foreground/60 focus:border-brand-cyan focus:outline-none focus:ring-2 focus:ring-brand-cyan/25"
            />
            <button
              type="button"
              disabled={checking}
              onClick={() => void join()}
              className="inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-brand-gradient text-sm font-semibold text-white shadow-[0_6px_16px_rgba(59,130,246,0.35)] transition-all hover:brightness-110 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-40 disabled:shadow-none"
            >
              <LogIn className="h-4 w-4" />
              {t('liveMeeting.join.join')}
            </button>
          </div>
        ) : (
          /* ------- entry step ------- */
          <div className="flex flex-col items-center gap-5 text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-gradient text-white shadow-[0_6px_16px_rgba(59,130,246,0.35)]">
              <Video className="h-6 w-6" />
            </div>
            <div>
              <DialogTitle className="text-lg font-semibold text-foreground">{t('liveMeeting.join.title')}</DialogTitle>
              <DialogDescription className="mt-1 text-[13px] text-muted-foreground">
                {t('liveMeeting.join.subtitle')}
              </DialogDescription>
            </div>

            {/* 6-digit segmented input: 2 groups × 3 digits */}
            <div className="flex items-center gap-1.5" aria-label={t('liveMeeting.join.codeLabel')}>
              {[0, 1].map((g) => (
                <div key={g} className="flex items-center gap-1.5">
                  {g > 0 && <span className="h-7 w-1.5 rounded-full bg-white/15" aria-hidden="true" />}
                  <div className="flex gap-1">
                    {[0, 1, 2].map((i) => {
                      const idx = g * 3 + i;
                      return (
                        <input
                          key={idx}
                          ref={(el) => { boxRefs.current[idx] = el; }}
                          type="text"
                          inputMode="numeric"
                          maxLength={1}
                          value={digits[idx]}
                          aria-label={t('liveMeeting.join.digitLabel', { n: idx + 1 })}
                          onChange={(e) => setDigit(idx, e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Backspace' && !digits[idx] && idx > 0) {
                              boxRefs.current[idx - 1]?.focus();
                              setDigits((prev) => {
                                const next = [...prev];
                                next[idx - 1] = '';
                                return next;
                              });
                              e.preventDefault();
                            }
                          }}
                          onPaste={handlePaste}
                          className={cn(
                            'h-12 w-10 rounded-lg border border-white/10 bg-white/[0.06] text-center text-lg font-semibold text-white transition-colors',
                            'placeholder:text-muted-foreground/40 focus:border-brand-cyan focus:bg-white/[0.09] focus:outline-none focus:ring-2 focus:ring-brand-cyan/25',
                            digits[idx] && 'border-brand-cyan',
                          )}
                        />
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>

            {/* Nickname */}
            <div className="w-full text-left">
              <label htmlFor="join-name" className="mb-1.5 block text-[13px] font-medium text-foreground/70">
                {t('liveMeeting.join.nickname')}
              </label>
              <LimitedInput
                id="join-name"
                type="text"
                maxLength={ROOM_NAME_MAX}
                value={nickname}
                onChange={(e) => setNickname(e.target.value)}
                className="flex h-10 w-full rounded-lg border border-white/10 bg-white/[0.06] px-3 text-sm text-white placeholder:text-muted-foreground/60 focus:border-brand-cyan focus:outline-none focus:ring-2 focus:ring-brand-cyan/25"
              />
            </div>

            {/* Media pre-toggles */}
            {(meetingUi.audio || meetingUi.video) && <div className="w-full rounded-xl bg-white/[0.04] px-4 py-1 text-left">
              {meetingUi.audio && <div className="flex items-center justify-between py-2.5">
                <span className="flex items-center gap-2.5 text-sm text-foreground/80">
                  <Mic className="h-4 w-4" />
                  {t('liveMeeting.join.micOn')}
                </span>
                <Switch checked={micOn} onCheckedChange={setMicOn} />
              </div>}
              {meetingUi.video && <div className="flex items-center justify-between py-2.5">
                <span className="flex items-center gap-2.5 text-sm text-foreground/80">
                  <Video className="h-4 w-4" />
                  {t('liveMeeting.join.camOn')}
                </span>
                <Switch checked={camOn} onCheckedChange={setCamOn} />
              </div>}
            </div>}

            <button
              type="button"
              disabled={!codeComplete || checking}
              onClick={() => void join()}
              className="inline-flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-brand-gradient text-sm font-semibold text-white shadow-[0_6px_16px_rgba(59,130,246,0.35)] transition-all enabled:hover:brightness-110 enabled:active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-40 disabled:shadow-none"
            >
              <LogIn className="h-4 w-4" />
              {t('liveMeeting.join.join')}
            </button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
