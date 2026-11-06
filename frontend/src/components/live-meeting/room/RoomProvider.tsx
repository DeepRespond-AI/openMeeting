'use client';

/**
 * RoomProvider — join lifecycle + live room state (plan P1.d).
 *
 * The authenticated app shell owns the join (dialogs collect the intent via
 * sessionStorage), keeping media alive across page navigation. All signaling
 * flows through LiveMeetingEventBus; this provider folds events into React state and
 * exposes every room action the UI needs.
 */
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { RoomRecorder, type RecordingState } from '@/services/live-meeting/recording';
import { toast } from 'sonner';
import { useT } from '@/i18n';
import { useServer } from '@/contexts/ServerContext';
import { useIm } from '@/contexts/IMContext';
import { useAudioLevels } from '@/hooks/useAudioLevels';
import { readAudioPreferences, saveAudioPreferences, createSpeakerTest, routeAudio, microphoneErrorMessage, type AudioPreferences } from '@/services/live-meeting/media/audioDevices';
import { JOIN_INTENT_KEY, type JoinIntent } from '@/components/live-meeting/JoinDialog';
import type {ScreenState} from '@/services/live-meeting/media/screenShare';
import { ImMeetingChat } from '@/services/live-meeting/chat';
import { MediaReleaseTimeout, recoverRoomRtc, rtcWait } from '@/services/live-meeting/media/recovery';
import { meetingUi } from '@/config/meeting-ui';
import { isRoomInvalidation } from '@/services/live-meeting/imEvents';
import type { MockMeetingChatApi } from '@/services/live-meeting/api';
import type { ChatAttachment, RecordingAction, RecordingRequest } from '@/services/live-meeting/types';
import {
  LiveMeetingApiError,
  getMediaClient,
  getLiveMeetingApi,
  getLiveMeetingDataSource,
  type ChatMessage,
  type LiveRoom,
  type Participant,
  type RoomEvent,
  type RoomMediaConfig,
  type MediaState,
} from '@/services/live-meeting';

export type RoomPhase = 'joining' | 'waiting' | 'joined' | 'ended' | 'error';
export type PanelTab = 'members' | 'chat' | null;

interface RoomContextValue {
  updateSettings: (patch: import('@/services/live-meeting').RoomSettingsPatch) => Promise<void>;
  recordingState: RecordingState;
  recordingError: string | null;
  recordingBusy: boolean;
  recordingControlError: string | null;
  controlRecording: (action: RecordingAction, request?: RecordingRequest) => Promise<void>;
  retryRecording: () => Promise<void>;
  phase: RoomPhase;
  entryStatus: 'loading' | 'ready' | 'error';
  retryEntry: () => void;
  /** Abandon only this unfinished entry; other devices keep their membership. */
  cancelEntry: () => void;
  room: LiveRoom | null;
  self: Participant | null;
  isHost: boolean;
  activeSpeakerId: string | null;
  messages: ChatMessage[];
  /** Translated failure text for the error screen. */
  errorText: string | null;
  panelTab: PanelTab;
  chatGroupId: string | null;
  chatUnread: number;
  setChatAtBottom: (bottom: boolean) => void;
  connectionState: string;
  mediaAvailable: boolean;
  mediaState: MediaState;
  audioLevels: Record<string, number>;
  audioConnected: boolean;
  audioPreferences: AudioPreferences;
  setAudioPreferences: (patch: Partial<AudioPreferences>) => void;
  connectAudio: () => Promise<void>;
  disconnectAudio: () => Promise<void>;
  screenState: ScreenState;
  mediaDeviceError: boolean;
  retryMedia: () => Promise<void>;
  mediaRecovering: boolean;
  mediaRecoveryError: string | null;
  retryScreen: () => void;
  fileSending: boolean;
  fileProgress: number;
  cancelFile: () => void;
  chatStatus: 'connecting' | 'ready' | 'error';
  chatError: string | null;
  retryChat: () => void;
  chatHasOlder: boolean;
  chatLoadingOlder: boolean;
  loadOlderChat: () => Promise<void>;
  setPanelTab: (tab: PanelTab) => void;
  toggleMic: () => void;
  toggleCam: () => void;
  toggleHand: () => void;
  toggleShare: () => void;
  admit: (participantId: string) => Promise<boolean>;
  deny: (participantId: string) => Promise<boolean>;
  approveHand: (participantId: string) => Promise<boolean>;
  setParticipantMuted: (participantId: string, muted: boolean) => Promise<boolean>;
  removeParticipant: (participantId: string) => Promise<boolean>;
  transferHost: (participantId: string) => Promise<boolean>;
  setAllMuted: (muted: boolean) => Promise<boolean>;
  chatReply: ChatMessage | null;
  setChatReply: (message: ChatMessage | null) => void;
  sendChat: (text: string) => Promise<void>;
  sendFile: (file: File) => Promise<void>;
  downloadFile: (attachment: ChatAttachment) => Promise<void>;
  /** Member leave / waiting-room cancel. */
  leave: () => Promise<void>;
  /** Host only. Returns the notes id (null in mock) for navigation. */
  end: () => Promise<string | null>;
  backHome: () => void;
}

const RoomContext = createContext<RoomContextValue | null>(null);

export function useRoom(): RoomContextValue {
  const ctx = useContext(RoomContext);
  if (!ctx) throw new Error('useRoom must be used within RoomProvider');
  return ctx;
}

export function RoomProvider({ children, code: sessionCode, onClose, visible = true }: { children: ReactNode; code?: string; onClose?: () => void; visible?: boolean }) {
  const t = useT();
  const router = useRouter();
  const searchParams = useSearchParams();
  const { user } = useServer();
  const { client: imClient, status: imStatus, relogin } = useIm();
  const api = getLiveMeetingApi();
  const media = getMediaClient();

  const [phase, setPhase] = useState<RoomPhase>('joining');
  const [room, setRoom] = useState<LiveRoom | null>(null);
  const roomRef = useRef<LiveRoom | null>(null);
  roomRef.current = room;
  const [self, setSelf] = useState<Participant | null>(null);
  const [activeSpeakerId, setActiveSpeakerId] = useState<string | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [errorText, setErrorText] = useState<string | null>(null);
  const [panelTab, setPanelTab] = useState<PanelTab>(null);
  const [chatUnread, setChatUnread] = useState(0);
  const [connectionState, setConnectionState] = useState('connecting');
  const isMock = getLiveMeetingDataSource() === 'mock';
  const mockChat = api as typeof api & MockMeetingChatApi;
  const [chatReply, setChatReply] = useState<ChatMessage | null>(null);
  const [chatGroupId, setChatGroupId] = useState<string | null>(null);
  const imChatRef = useRef<ImMeetingChat | null>(null);
  const [chatStatus, setChatStatus] = useState<'connecting' | 'ready' | 'error'>(isMock ? 'ready' : 'connecting');
  const [chatError, setChatError] = useState<string | null>(null);
  const [chatRetry, setChatRetry] = useState(0);
  const [chatHasOlder, setChatHasOlder] = useState(false);
  const [chatLoadingOlder, setChatLoadingOlder] = useState(false);
  const [fileProgress, setFileProgress] = useState(0);
  const [audioPreferences, updateAudioPreferences] = useState(readAudioPreferences);
  const [audioConnected, setAudioConnected] = useState(() => meetingUi.audio && (isMock || readAudioPreferences().autoJoin));
  const audioConnectedRef = useRef(audioConnected);
  audioConnectedRef.current = audioConnected;
  const setAudioPreferences = useCallback((patch: Partial<AudioPreferences>) => {
    updateAudioPreferences(previous => {
      const next = { ...previous, ...patch };
      saveAudioPreferences(next);
      return next;
    });
  }, []);
  const [mediaConfig, setMediaConfig] = useState<RoomMediaConfig | null>(null);
  const [mediaState, setMediaState] = useState<MediaState>({status:'idle',tracks:[],speakerEnabled:true});
  const [mediaRecovering, setMediaRecovering] = useState(false);
  const [mediaRecoveryError, setMediaRecoveryError] = useState<string | null>(null);
  const mediaRetryRef = useRef<AbortController | null>(null);
  const mediaRetryMountedRef = useRef(true);
  useEffect(() => {
    mediaRetryMountedRef.current=true;
    return () => {mediaRetryMountedRef.current=false;mediaRetryRef.current?.abort();};
  }, []);
  const [mediaDeviceError, setMediaDeviceError] = useState(false);
  const [devicesReady, setDevicesReady] = useState(isMock);
  const [entryReady, setEntryReady] = useState(false);
  const [entryTimedOut, setEntryTimedOut] = useState(false);
  const [entryAttempt, setEntryAttempt] = useState(0);
  const captureGeneration = useRef(0);
  const [screenState,setScreenState]=useState<ScreenState>({status:'idle',tracks:[],viewers:0});
  const trackAudioLevels = useAudioLevels(mediaState.tracks, !isMock && phase === 'joined' && mediaState.status === 'connected');
  const audioLevels = useMemo(() => Object.fromEntries((room?.participants ?? []).map(p => [p.id,
    !p.micOn || p.mutedByHost ? 0 : Math.max(0, ...mediaState.tracks
      .filter(track => track.kind === 'audio' && track.source !== 'screen' && ((track.local && p.isSelf) || (!track.local && !!p.userId && track.username === p.userId)))
      .map(track => track.track.enabled && !track.track.muted && track.track.readyState === 'live' ? trackAudioLevels[track.key] ?? 0 : 0)),
  ])), [room, mediaState.tracks, trackAudioLevels]);
  const [fileSending, setFileSending] = useState(false);
  const [recordingState, setRecordingState] = useState<RecordingState>('waiting');
  const [recordingError, setRecordingError] = useState<string | null>(null);
  const [recordingBusy, setRecordingBusy] = useState(false);
  const [recordingControlError, setRecordingControlError] = useState<string | null>(null);
  const recordingPendingRef = useRef(false);
  const recorderRef = useRef<RoomRecorder | null>(null);
  const [recorderVersion, setRecorderVersion] = useState(0);
  useEffect(() => {
    if (!meetingUi.recording || isMock || phase !== 'joined' || !self?.isHost || !room?.startedAt || !room.recording?.active) return;
    setRecordingState('waiting'); setRecordingError(null);
    const recorder = new RoomRecorder(room.id, room.startedAt, (state, error) => {
      setRecordingState(state); setRecordingError(error || null);
    }, room.recording.epoch);
    recorderRef.current = recorder;
    const resume = () => { void recorder.resume(); };
    window.addEventListener('pointerdown', resume);
    return () => { recorder.dispose(); if (recorderRef.current === recorder) recorderRef.current = null; window.removeEventListener('pointerdown', resume); };
  }, [isMock, phase, self?.isHost, room?.id, room?.startedAt, room?.recording?.active, room?.recording?.epoch, recorderVersion]);
  useEffect(() => { recorderRef.current?.sync(mediaState.tracks, room?.participants || []); }, [mediaState.tracks, room?.participants, phase, self?.isHost, room?.recording?.active, room?.recording?.epoch, recorderVersion]);
  const mediaAvailable = isMock || mediaState.status === 'connected';
  const needsMedia = meetingUi.audio || meetingUi.video;
  const entryFailed = entryTimedOut || (needsMedia && !isMock && (mediaState.status === 'error' || mediaState.status === 'unavailable'))
    || (meetingUi.chat && chatStatus === 'error');
  const entryStatus = entryReady ? 'ready' : entryFailed ? 'error' : 'loading';
  useEffect(() => {
    if (phase === 'joined' && (!needsMedia || (mediaAvailable && devicesReady)) && (!meetingUi.chat || chatStatus === 'ready')) {
      setEntryReady(true);
    }
  }, [phase, needsMedia, mediaAvailable, devicesReady, chatStatus]);
  useEffect(() => {
    if (phase !== 'joined' || entryReady) return;
    const timer = setTimeout(() => setEntryTimedOut(true), 45000);
    return () => clearTimeout(timer);
  }, [phase, entryReady, entryAttempt]);
  const requestedMediaRef = useRef({micOn:false,camOn:false});
  const captureStartedRef = useRef(false);
  const filePendingRef = useRef(false);

  // Refs mirrored for use inside the (stable) event handler and cleanup.
  const phaseRef = useRef<RoomPhase>('joining');
  phaseRef.current = phase;
  const selfRef = useRef<Participant | null>(null);
  selfRef.current = self;
  const loweringHandRef = useRef(false);
  const chatIdsRef = useRef(new Set<string>());
  const roomIdRef = useRef<string | null>(null);
  const controlPendingRef = useRef(false);
  const allMutePendingRef = useRef(false);
  const lastChatRef = useRef<string | undefined>(undefined);
  const panelTabRef = useRef<PanelTab>(null);
  panelTabRef.current = panelTab;
  const visibleRef = useRef(visible);
  visibleRef.current = visible;

  // Local controls and participant tiles must commit the same state even when
  // the signalling echo is delayed or missing.
  const patchSelf = useCallback((patch: Partial<Participant>) => {
    const id = selfRef.current?.id;
    setSelf((prev) => (prev ? { ...prev, ...patch } : prev));
    setRoom((prev) => prev ? { ...prev, participants: prev.participants.map(
      (participant) => participant.id === id ? { ...participant, ...patch } : participant,
    ) } : prev);
  }, []);

  const backHome = useCallback(() => {
    if (phaseRef.current === 'ended' || phaseRef.current === 'error') onClose?.();
    router.replace('/');
  }, [router, onClose]);

  const cancelEntry = useCallback(() => {
    if (entryReady) return;
    // Membership is shared by account. Mark this attempt terminal before the
    // persistent session unmounts, so member cleanup cannot leave the other device.
    phaseRef.current = 'ended';
    setPhase('ended');
    ++captureGeneration.current;
    requestedMediaRef.current = {micOn:false,camOn:false};
    recorderRef.current?.dispose();
    recorderRef.current = null;
    imChatRef.current?.dispose();
    imChatRef.current = null;
    void media.leave().catch(() => {});
    if (roomIdRef.current) void api.disconnectRoom?.(roomIdRef.current).catch(() => {});
    try { sessionStorage.removeItem(JOIN_INTENT_KEY); } catch { /* storage unavailable */ }
    onClose?.();
    router.replace('/');
  }, [entryReady, media, api, onClose, router]);

  const failJoin = useCallback((err: unknown) => {
    const text = err instanceof LiveMeetingApiError
      ? t(({
        not_found: 'liveMeeting.join.errNotFound',
        not_started: 'liveMeeting.join.errNotStarted',
        ended: 'liveMeeting.join.errEnded',
        wrong_pwd: 'liveMeeting.join.errWrongPwd',
        full: 'liveMeeting.join.errFull',
      } as const)[err.code])
      : t('liveMeeting.join.errGeneric');
    setErrorText(text);
    setPhase('error');
  }, [t]);

  /* ---------- event folding ---------- */
  const mergeChat = useCallback((incoming: ChatMessage[]) => {
    const fresh = incoming.filter((message) => {
      if (chatIdsRef.current.has(message.id)) return false;
      chatIdsRef.current.add(message.id);
      return true;
    });
    if (fresh.length) {
      lastChatRef.current = fresh[fresh.length - 1].id;
      setMessages((previous) => [...previous, ...fresh]);
    }
  }, []);
  const refreshChat = useCallback(async (roomId: string) => {
    if (!meetingUi.chat || !isMock) return; // Real history/recovery belongs to the IM SDK.
    let after = lastChatRef.current;
    for (;;) {
      const page = await mockChat.listChat(roomId, after);
      if (roomIdRef.current !== roomId) return;
      mergeChat(page.messages);
      if (!page.hasMore || !page.messages.length || !after) break;
      after = page.messages[page.messages.length - 1].id;
    }
  }, [isMock, mockChat, mergeChat]);
  const handleEvent = useCallback((e: RoomEvent) => {
    switch (e.type) {
      case 'screen_signal':
        // Legacy P2P clients use this event. Screen media now belongs to IM RTC.
        break;
      case 'connection_state':
        setConnectionState(e.data.state);
        if (e.data.state === 'connected' && roomIdRef.current) {
          void refreshChat(roomIdRef.current).catch(() => toast.error(t('liveMeeting.room.errors.generic')));
        }
        if (e.data.state === 'removed') {
          setErrorText(t('liveMeeting.room.errors.removed'));
          setPhase('error');
        }
        if (e.data.state === 'failed') {
          setErrorText(t('liveMeeting.room.connectionLost'));
          setPhase('error');
        }
        break;
      case 'participant_joined': {
        const p = e.data.participant;
        setRoom((r) => (r ? { ...r,
          participants: r.participants.some((x) => x.id === p.id) ? r.participants : [...r.participants, p],
          waiting: r.waiting.filter((entry) => entry.participantId !== p.id),
        } : r));
        break;
      }
      case 'participant_left': {
        const id = e.data.participantId;
        if (id === selfRef.current?.id) {
          setErrorText(t('liveMeeting.room.errors.removed'));
          setPhase('error');
        }
        setRoom((r) => (r ? { ...r, participants: r.participants.filter((x) => x.id !== id) } : r));
        break;
      }
      case 'participant_updated': {
        const p = e.data.participant;
        if (p.isSelf) {
          const prev = selfRef.current;
          // Bot host auto-approved my raised hand (mock demo) — distinct from my own lower.
          if (prev?.handRaised && !p.handRaised && !loweringHandRef.current) {
            toast.success(t('liveMeeting.room.hand.approvedMeToast'));
          }
          loweringHandRef.current = false;
          setSelf(p);
        }
        setRoom((r) => (r
          ? { ...r, participants: r.participants.map((x) => (x.id === p.id ? p : x)) }
          : r));
        break;
      }
      case 'waiting_requested': {
        const { participantId, name } = e.data;
        setRoom((r) => (r && !r.waiting.some((w) => w.participantId === participantId)
          ? { ...r, waiting: [...r.waiting, { participantId, name, requestedAt: e.ts }] }
          : r));
        toast.info(t('liveMeeting.room.waitingRoom.requestToast', { name }));
        break;
      }
      case 'waiting_resolved': {
        const { participantId, admitted } = e.data;
        if (selfRef.current && participantId === selfRef.current.id) {
          if (admitted) {
            setPhase('joined');
            if (roomIdRef.current && api.getRoomMedia) void api.getRoomMedia(roomIdRef.current).then(setMediaConfig).catch(()=>setMediaState({status:'error',reason:'connectionFailed',tracks:[],speakerEnabled:true}));
            if (roomIdRef.current) void refreshChat(roomIdRef.current).catch(() => toast.error(t('liveMeeting.room.errors.generic')));
          } else {
            toast.error(t('liveMeeting.room.waitingRoom.deniedMeToast'));
            backHome();
          }
        } else {
          setRoom((r) => (r ? { ...r, waiting: r.waiting.filter((w) => w.participantId !== participantId) } : r));
        }
        break;
      }
      case 'chat': {
        if (!meetingUi.chat || !isMock) break; // Business WS never supplies real chat messages.
        const m = e.data.message;
        if (chatIdsRef.current.has(m.id)) break;
        chatIdsRef.current.add(m.id);
        setMessages((prev) => [...prev, m]);
        if (!m.sender.isSelf && panelTabRef.current !== 'chat') setChatUnread((n) => n + 1);
        break;
      }
      case 'active_speaker':
        setActiveSpeakerId(e.data.participantId);
        break;
      case 'room_ended':
        phaseRef.current = 'ended';
        setPhase('ended');
        break;
      case 'room_state':
        setRoom(e.data.room);
        setSelf((current) => e.data.room.participants.find((p) => p.isSelf || p.id === current?.id) ?? current);
        break;
    }
  }, [t, backHome, refreshChat, api, media, isMock]);

  useEffect(() => {
    if (!meetingUi.chat || isMock || phase !== 'joined' || !room?.id) return;
    setChatStatus('connecting');
    setChatGroupId(null);
    setChatError(null);
    if (imStatus === 'connecting') return;
    if (!imClient || !api.getChatSession) {
      setChatStatus('error');
      setChatError(t('liveMeeting.room.chat.unavailable'));
      return;
    }
    let disposed = false;
    let owned: ImMeetingChat | null = null;
    const deadline = setTimeout(() => {
      if (disposed) return;
      disposed = true;
      owned?.dispose();
      if (imChatRef.current === owned) imChatRef.current = null;
      setChatStatus('error');
      setChatError(t('liveMeeting.room.chat.unavailable'));
    }, 30000);
    const roomId = room.id;
    setMessages([]);
    void (async () => {
      const session = await api.getChatSession!(roomId);
      if (disposed) return;
      setChatGroupId(session.groupId);
      owned = new ImMeetingChat(imClient, roomId, session.groupId,
        imClient.auth.currentUser?.username ?? '',
        () => roomRef.current?.participants ?? [],
        snapshot => {
          if (disposed) return;
          if (snapshot.status !== 'connecting') clearTimeout(deadline);
          setChatStatus(snapshot.status);
          setChatError(snapshot.error ?? null);
          setChatHasOlder(snapshot.hasOlder);
          setChatLoadingOlder(snapshot.loadingOlder);
          setMessages(snapshot.messages);
          setChatUnread(snapshot.unread);
        });
      imChatRef.current = owned;
      owned.setViewing(visibleRef.current && panelTabRef.current === 'chat');
      await owned.connect();
      if (!disposed) owned.setViewing(visibleRef.current && panelTabRef.current === 'chat');
    })().catch(error => {
      clearTimeout(deadline);
      if (!disposed) {
        setChatStatus('error');
        setChatError(error instanceof Error ? error.message : t('liveMeeting.room.chat.unavailable'));
      }
    });
    return () => {
      clearTimeout(deadline);
      disposed = true;
      if (phaseRef.current === 'ended') void owned?.close().catch(() => console.warn('Could not hide ended meeting conversation'));
      else owned?.dispose();
      if (imChatRef.current === owned) imChatRef.current = null;
    };
  }, [isMock, phase, room?.id, api, imClient, imStatus, chatRetry, t]);

  useEffect(() => { imChatRef.current?.setViewing(visible && panelTab === 'chat'); }, [panelTab, visible]);

  useEffect(() => {
    if (isMock || !imClient || phase !== 'joined' || !room?.id) return;
    const id = room.id;
    let disposed = false;
    let timer: ReturnType<typeof setTimeout> | null = null;
    const unsubscribe = imClient.on('message.received', ({ message }) => {
      if (!isRoomInvalidation(message, id) || timer) return;
      timer = setTimeout(() => {
        timer = null;
        void api.getRoom(id).then(snapshot => {
          if (disposed || roomIdRef.current !== id) return;
          setRoom(snapshot);
          setSelf(current => snapshot.participants.find(p => p.id === current?.id) ?? current);
        }).catch(() => { /* authoritative WS/reconnect continues recovery */ });
      }, 150);
    });
    return () => { disposed = true; unsubscribe(); if (timer) clearTimeout(timer); };
  }, [isMock, imClient, phase, room?.id, api]);

  useEffect(() => media.subscribe?.(setMediaState), [media]);
  useEffect(()=>media.screen?.subscribe(setScreenState),[media]);
  useEffect(()=>{
    if(meetingUi.screenShare&&!isMock&&phase==='joined'&&room&&self){media.screen?.bind(api,room.id,self.id);media.screen?.sync(room);}
    if(phase==='error'||phase==='ended')void media.screen?.close();
  },[isMock,phase,room,self,media,api]);
  useEffect(() => {
    if (phase !== 'ended' && phase !== 'error') return;
    mediaRetryRef.current?.abort();
    // Ended sessions must not retain messages, reply targets or upload state.
    imChatRef.current?.dispose();
    imChatRef.current = null;
    setMessages([]);
    setChatReply(null);
    setChatGroupId(null);
    setChatUnread(0);
    setChatHasOlder(false);
    setChatLoadingOlder(false);
    setFileProgress(0);
    chatIdsRef.current.clear();
    void media.leave();
    if (roomIdRef.current) void api.disconnectRoom?.(roomIdRef.current).catch(() => {});
  }, [phase, media, api]);
  useEffect(()=>()=>{void media.screen?.close();},[media]);
  useEffect(()=>{
    if(!isMock&&connectionState==='reconnecting')void media.stopScreenShare().catch(()=>{});
  },[isMock,connectionState,media]);

  useEffect(() => {
    if((!meetingUi.audio && !meetingUi.video) || isMock || phase!=='joined' || !mediaConfig)return;
    if(mediaConfig.transport==='dr-rtc' && imStatus==='connecting')return;
    captureStartedRef.current=false;
    setDevicesReady(false);
    ++captureGeneration.current;
    let disposed=false;
    void (async()=>{
      // The adapter first checks for a resumable SDK session. Do not issue a
      // replacement ticket merely because the original one-use ticket expired.
      if(!disposed) {
        await media.connect?.(mediaConfig,imClient?.channels??null);
        if (!disposed) await media.setSpeakerEnabled(meetingUi.audio && audioConnectedRef.current);
      }
    })().catch(()=>{if (!disposed) setMediaState({status:'error',reason:'connectionFailed',tracks:[],speakerEnabled:true});});
    return ()=>{disposed=true;++captureGeneration.current;void media.leave();};
  },[isMock,phase,mediaConfig,imClient,imStatus,media,api]);

  // Start only the devices requested in the join UI, once per media connection.
  useEffect(()=>{
    if(isMock || phase!=='joined' || mediaState.status!=='connected' || captureStartedRef.current || !roomIdRef.current)return;
    captureStartedRef.current=true;
    const generation = captureGeneration.current;
    const roomId=roomIdRef.current;
    const isCurrentCapture = () => roomIdRef.current === roomId && captureGeneration.current === generation;
    void (async()=>{
      if (mediaState.reason==='restored') {
        requestedMediaRef.current={micOn:false,camOn:false};
        await api.updateSelf(roomId,{micOn:false,camOn:false});
        if(roomIdRef.current===roomId)patchSelf({micOn:false,camOn:false});
        return;
      }
      const desired=requestedMediaRef.current;
      for(const kind of ['micOn','camOn'] as const){
        if (!isCurrentCapture()) return;
        if(!desired[kind] || (kind === 'micOn' ? !meetingUi.audio || !audioConnectedRef.current : !meetingUi.video))continue;
        try{
          await api.updateSelf(roomId,{[kind]:true});
          if (!isCurrentCapture()) return;
          await (kind==='micOn'?media.setMicEnabled(true):media.setCamEnabled(true));
          if (isCurrentCapture()) patchSelf({[kind]:true});
        }catch{
          if (!isCurrentCapture()) return;
          await (kind==='micOn'?media.setMicEnabled(false):media.setCamEnabled(false)).catch(()=>{});
          await api.updateSelf(roomId,{[kind]:false}).catch(()=>{});
          if(isCurrentCapture()){patchSelf({[kind]:false});setMediaDeviceError(true);}
        }
      }
    })().catch(()=>{if (isCurrentCapture()) setMediaDeviceError(true);}).finally(() => {
      if (isCurrentCapture()) setDevicesReady(true);
    });
  },[isMock,phase,mediaState.status,mediaState.reason,api,media,patchSelf]);

  // Host mute and server snapshots must stop physical capture as well as its icon.
  useEffect(()=>{if(self?.micOn===false)void media.setMicEnabled(false).catch(()=>{});},[self?.micOn,media]);
  useEffect(()=>{if(self?.camOn===false)void media.setCamEnabled(false).catch(()=>{});},[self?.camOn,media]);

  const retryMedia=useCallback(async()=>{
    if((!meetingUi.audio && !meetingUi.video)||!roomIdRef.current||!api.getRoomMedia||mediaRetryRef.current)return;
    const roomId = roomIdRef.current;
    const sessionId = mediaState.releasingSessionId;
    const controller = new AbortController();
    mediaRetryRef.current = controller;
    const active = () => !controller.signal.aborted && phaseRef.current==='joined' && roomIdRef.current===roomId;
    if(imStatus==='error')relogin();
    setMediaRecoveryError(null);
    setMediaDeviceError(false);
    ++captureGeneration.current;
    setDevicesReady(false);
    if (entryReady) requestedMediaRef.current={micOn:meetingUi.audio && !!selfRef.current?.micOn,camOn:meetingUi.video && !!selfRef.current?.camOn};
    try {
      if (sessionId) {
        setMediaRecovering(true);
        // Cancel the old attach without leaving the business room or chat.
        setMediaConfig(null);
        await rtcWait(media.leave(), controller.signal, Date.now()+8_000);
        if (!active()) return;
        setMediaState({status:'connecting',reason:'sessionReleasing',releasingSessionId:sessionId,
          tracks:[],speakerEnabled:audioConnectedRef.current});
        const config = await recoverRoomRtc(api, roomId, sessionId, controller.signal);
        if (active()) setMediaConfig(config);
      } else {
        setMediaState({status:'connecting',tracks:[],speakerEnabled:audioConnectedRef.current});
        const config = await rtcWait(api.getRoomMedia(roomId), controller.signal, Date.now()+20_000);
        if (active()) setMediaConfig(config);
      }
    } catch (error) {
      if (active()) {
        if (sessionId) setMediaRecoveryError(error instanceof MediaReleaseTimeout
          ? t('liveMeeting.room.rtc.releasePending') : error instanceof Error ? error.message : t('liveMeeting.room.rtc.releaseFailed'));
        setMediaState({status:'error',reason:sessionId?'sessionReleaseTimeout':'connectionFailed',
          releasingSessionId:sessionId,tracks:[],speakerEnabled:audioConnectedRef.current});
      }
    } finally {
      if (mediaRetryRef.current===controller) {
        mediaRetryRef.current=null;
        if (mediaRetryMountedRef.current) {
          setMediaRecovering(false);
          if (controller.signal.aborted && phaseRef.current==='joined' && sessionId) {
            setMediaState({status:'error',reason:'sessionReleaseTimeout',releasingSessionId:sessionId,
              tracks:[],speakerEnabled:audioConnectedRef.current});
          }
        }
      }
    }
  },[api,imStatus,relogin,entryReady,mediaState.releasingSessionId,media,t]);

  const retryEntry = useCallback(() => {
    setEntryTimedOut(false);
    setEntryAttempt(n => n + 1);
    if (needsMedia && (!mediaAvailable || !devicesReady)) void retryMedia();
    if (meetingUi.chat && chatStatus !== 'ready') {
      setChatStatus('connecting');
      setChatError(null);
      setChatRetry(n => n + 1);
    }
    if (imStatus === 'error') relogin();
  }, [needsMedia, mediaAvailable, devicesReady, retryMedia, chatStatus, imStatus, relogin]);

  /* ---------- join on mount ---------- */
  useEffect(() => {
    // Consume the join intent written by JoinDialog first — it also carries the
    // code for entry paths without a `?code=` query (preview/deep-link intents).
    let intent: JoinIntent | null = null;
    try {
      const raw = sessionStorage.getItem(JOIN_INTENT_KEY);
      if (raw) {
        intent = JSON.parse(raw) as JoinIntent;
        sessionStorage.removeItem(JOIN_INTENT_KEY);
      }
    } catch {
      /* storage unavailable */
    }
    const code = sessionCode ?? searchParams.get('code') ?? intent?.code ?? '';
    if (!code) {
      failJoin(new LiveMeetingApiError('not_found', 'Missing code'));
      return;
    }

    const off = api.onRoomEvent(handleEvent);

    // Fall back to defaults for quick meetings and deep links.
    // Empty nickname lets the authenticated server supply the actual account
    // name when context hydration has not completed on a direct room link.
    const joinIntent: JoinIntent = intent?.code === code ? intent : { code, name: user?.name || '', micOn: true, camOn: false };
    requestedMediaRef.current={micOn:meetingUi.audio && joinIntent.micOn,camOn:meetingUi.video && joinIntent.camOn};

    let disposed = false;
    void (async () => {
      try {
        const res = await api.joinRoom({
          code: joinIntent.code,
          name: joinIntent.name,
          micOn: isMock && requestedMediaRef.current.micOn,
          camOn: isMock && requestedMediaRef.current.camOn,
          pwd: joinIntent.pwd,
        });
        if (disposed) {
          if (!res.self.isHost) void api.leaveRoom(res.room.id).catch(() => {});
          void api.disconnectRoom?.(res.room.id).catch(() => {});
          return;
        }
        setRoom(res.room);
        roomIdRef.current = res.room.id;
        setSelf(res.self);
        setMediaConfig(res.media);
        setPhase(res.state === 'waiting' ? 'waiting' : 'joined');
        // Seed the chat panel from history; live messages arrive via events.
        if (res.state === 'joined') await refreshChat(res.room.id);
      } catch (err) {
        if (!disposed) failJoin(err);
      }
    })();

    return () => {
      disposed = true;
      void media.leave();
      off();
      // Releasing the authenticated session also releases non-host membership.
      if (roomIdRef.current) {
        if (['joined', 'waiting'].includes(phaseRef.current) && !selfRef.current?.isHost) {
          void api.leaveRoom(roomIdRef.current).catch(() => {});
        }
        void api.disconnectRoom?.(roomIdRef.current).catch(() => {});
        roomIdRef.current = null;
      }
    };
    // Join exactly once per mounted session; its meeting code stays fixed.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /* ---------- actions ---------- */

  const updateControl = useCallback(async (patch: Partial<Participant>, success: string) => {
    if ((!meetingUi.audio && patch.micOn === true) || (!meetingUi.video && patch.camOn === true) || (!meetingUi.handRaise && patch.handRaised === true)) return;
    if (!room || controlPendingRef.current) return;
    controlPendingRef.current = true;
    try {
      if(!isMock && (patch.micOn===true || patch.camOn===true) && !mediaAvailable)throw new Error(t('liveMeeting.room.rtc.unavailable'));
      if(patch.micOn===false)await media.setMicEnabled(false);
      if(patch.camOn===false)await media.setCamEnabled(false);
      await api.updateSelf(room.id, patch);
      try{
        if(patch.micOn===true)await media.setMicEnabled(true);
        if(patch.camOn===true)await media.setCamEnabled(true);
      }catch(error){
        const rollback={...(patch.micOn!==undefined?{micOn:false}:{}),...(patch.camOn!==undefined?{camOn:false}:{})};
        await api.updateSelf(room.id,rollback).catch(()=>{});
        patchSelf(rollback);setMediaDeviceError(true);
        if (patch.micOn === true) {
          const key = microphoneErrorMessage(error);
          throw new Error(t(`liveMeeting.room.audio.${key === 'inputSwitchFailed' ? 'inputFailed' : key}`));
        }
        throw new Error(t('liveMeeting.room.rtc.permissionDenied'));
      }
      setMediaDeviceError(false);
      patchSelf(patch);
      toast(success);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t('liveMeeting.room.errors.generic'));
    } finally { controlPendingRef.current = false; }
  }, [room, api, patchSelf, t, isMock, mediaAvailable, media]);
  const toggleMic = useCallback(() => {
    if (!self || !room) return;
    const next = !self.micOn;
    void updateControl({ micOn: next }, next ? t('liveMeeting.room.toasts.micOn') : t('liveMeeting.room.toasts.micOff'));
  }, [self, room, updateControl, t]);

  const connectAudio = useCallback(async () => {
    if (!meetingUi.audio) return;
    if (!mediaAvailable) throw new Error(t('liveMeeting.room.rtc.connecting'));
    await media.setSpeakerEnabled(true);
    setAudioConnected(true);
    audioConnectedRef.current = true;
    if (requestedMediaRef.current.micOn && !selfRef.current?.micOn && !selfRef.current?.mutedByHost) {
      await updateControl({ micOn: true }, t('liveMeeting.room.toasts.micOn'));
    }
  }, [mediaAvailable, media, updateControl, t]);

  const disconnectAudio = useCallback(async () => {
    // Stop physical capture before changing signaling or the connection indicator.
    await media.setMicEnabled(false);
    await media.setSpeakerEnabled(false);
    setAudioConnected(false);
    audioConnectedRef.current = false;
    if (selfRef.current?.micOn) await updateControl({ micOn: false }, t('liveMeeting.room.toasts.micOff'));
  }, [media, updateControl, t]);

  const previousMic = useRef(false);
  useEffect(() => {
    const wasOn = previousMic.current;
    previousMic.current = !!self?.micOn;
    if (wasOn || !self?.micOn || !audioConnected || !audioPreferences.unmuteSound || isMock) return;
    const test = createSpeakerTest();
    test.audio.loop = false;
    let active = true;
    void routeAudio(test.audio, mediaState.speakerDeviceId ?? audioPreferences.speakerId)
      .then(() => { if (active) return test.audio.play(); }).catch(() => {});
    const timer = setTimeout(() => { active = false; test.dispose(); }, 450);
    return () => { active = false; clearTimeout(timer); test.dispose(); };
  }, [self?.micOn, audioConnected, audioPreferences.unmuteSound, audioPreferences.speakerId, mediaState.speakerDeviceId, isMock]);

  useEffect(() => {
    if (!meetingUi.audio || phase !== 'joined' || !media.setSpeakerDevice) return;
    void media.setSpeakerDevice(audioPreferences.speakerId).catch(() => {
      toast.error(t('liveMeeting.room.audio.outputFailed'));
    });
  }, [phase, media, audioPreferences.speakerId, t]);

  const toggleCam = useCallback(() => {
    if (!self || !room) return;
    const next = !self.camOn;
    void updateControl({ camOn: next }, next ? t('liveMeeting.room.toasts.camOn') : t('liveMeeting.room.toasts.camOff'));
  }, [self, room, updateControl, t]);

  const toggleHand = useCallback(() => {
    if (!self || !room || self.isHost) return;
    const next = !self.handRaised;
    loweringHandRef.current = !next;
    void updateControl({ handRaised: next }, next ? t('liveMeeting.room.hand.raisedToast') : t('liveMeeting.room.hand.loweredToast'));
  }, [self, room, updateControl, t]);

  const sharingRef = useRef(false);
  const toggleShare = useCallback(() => {
    if (!meetingUi.screenShare || !self || !room) return;
    if(!isMock){
      void (screenState.status==='sharing'||screenState.status==='choosing'||self.screenSharing?media.stopScreenShare():media.startScreenShare())
        .catch(()=>toast.error(t('liveMeeting.room.errors.generic')));
      return;
    }
    const next = !sharingRef.current;
    sharingRef.current = next;
    patchSelf({ screenSharing: next });
    void (next ? media.startScreenShare() : media.stopScreenShare());
    void api.updateSelf(room.id, { screenSharing: next });
    toast(next ? t('liveMeeting.room.toasts.shareOn') : t('liveMeeting.room.toasts.shareOff'));
  }, [self, room, patchSelf, media, api, t, isMock,screenState.status]);

  const runHostAction = useCallback(async (fn: () => Promise<void>) => {
    try {
      await fn();
      return true;
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t('liveMeeting.room.errors.generic'));
      return false;
    }
  }, [t]);

  const admit = useCallback((participantId: string) => {
    if (!room) return Promise.resolve(false);
    return runHostAction(() => api.admitParticipant(room.id, participantId));
  }, [room, api, runHostAction]);

  const deny = useCallback((participantId: string) => {
    if (!room) return Promise.resolve(false);
    return runHostAction(() => api.denyParticipant(room.id, participantId));
  }, [room, api, runHostAction]);

  const approveHand = useCallback((participantId: string) => {
    if (!room) return Promise.resolve(false);
    return runHostAction(() => api.approveHand(room.id, participantId));
  }, [room, api, runHostAction]);

  const setParticipantMuted = useCallback((participantId: string, muted: boolean) => {
    if (!room) return Promise.resolve(false);
    return runHostAction(() => api.setParticipantMuted(room.id, participantId, muted));
  }, [room, api, runHostAction]);

  const removeParticipant = useCallback((participantId: string) => {
    if (!room) return Promise.resolve(false);
    return runHostAction(() => api.removeParticipant(room.id, participantId));
  }, [room, api, runHostAction]);

  const transferHost = useCallback(async (participantId: string) => {
    if (!room) return Promise.resolve(false);
    try { await recorderRef.current?.finish(); }
    catch (error) { toast.error(String(error)); return false; }
    const ok = await runHostAction(() => api.transferHost(room.id, participantId));
    if (!ok) setRecorderVersion(version => version + 1);
    return ok;
  }, [room, api, runHostAction]);

  const setAllMuted = useCallback(async (muted: boolean) => {
    if (!room || !self?.isHost || allMutePendingRef.current) return false;
    allMutePendingRef.current = true;
    try {
      return await runHostAction(async () => {
        // Read the authoritative roster so refreshes, host transfers and missed
        // events cannot leave someone permanently locked out of their microphone.
        const current = await api.getRoom(room.id);
        let failure: PromiseRejectedResult | undefined;
        if (muted) {
          await api.muteAll(room.id);
        } else {
          const results = await Promise.allSettled(current.participants
            .filter((p) => !p.isHost && p.mutedByHost)
            .map((p) => api.setParticipantMuted(room.id, p.id, false)));
          failure = results.find((result): result is PromiseRejectedResult => result.status === 'rejected');
        }
        const updated = await api.getRoom(room.id);
        if (roomIdRef.current === room.id) {
          setRoom(updated);
          setSelf((previous) => updated.participants.find((p) => p.id === previous?.id) ?? previous);
        }
        // Keep the remaining restrictions visible and allow retry after a partial failure.
        if (failure) throw failure.reason;
      });
    } finally { allMutePendingRef.current = false; }
  }, [room, self?.isHost, api, runHostAction]);

  const sendChat = useCallback(async (text: string) => {
    if (!meetingUi.chat || !room || !text.trim()) return;
    if (isMock) { mergeChat([await mockChat.sendChat(room.id, text.trim())]); return; }
    if (!imChatRef.current || chatStatus !== 'ready') throw new Error(t('liveMeeting.room.chat.unavailable'));
    await imChatRef.current.sendText(text.trim(), chatReply?.sequence);
    setChatReply(null);
  }, [room, mockChat, mergeChat, isMock, chatStatus, chatReply, t]);

  const sendFile = useCallback(async (file: File) => {
    if (!meetingUi.chat || !room) return;
    if(filePendingRef.current)throw new Error(t('liveMeeting.room.chat.uploading'));
    filePendingRef.current=true;setFileSending(true);setFileProgress(0);
    try {
      if (isMock) mergeChat([await mockChat.sendChatAttachment(room.id, file)]);
      else {
        if (!imChatRef.current || chatStatus !== 'ready') throw new Error(t('liveMeeting.room.chat.unavailable'));
        await imChatRef.current.sendFile(file, setFileProgress);
      }
    }
    finally{filePendingRef.current=false;setFileSending(false);}
  }, [room, mockChat, mergeChat, t, isMock, chatStatus]);
  const downloadFile=useCallback(async(attachment:ChatAttachment)=>{
    if(!meetingUi.chat || !room)return;
    if(isMock){toast.info(t('liveMeeting.room.chat.downloadDemo'));return;}
    try {
      if (!imChatRef.current) throw new Error(t('liveMeeting.room.chat.unavailable'));
      await imChatRef.current.download(attachment);
      toast.success(t('liveMeeting.room.chat.downloaded'));
    }
    catch(error){toast.error(error instanceof Error?error.message:t('liveMeeting.room.errors.generic'));}
  },[room,isMock,t]);

  const leave = useCallback(async () => {
    if (!room) return;
    mediaRetryRef.current?.abort();
    try {
      await api.leaveRoom(room.id);
      phaseRef.current = 'ended';
      setPhase('ended');
      await media.screen?.close();
      void media.leave();
      toast(t('liveMeeting.room.toasts.left'));
      backHome();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : t('liveMeeting.room.errors.generic'));
    }
  }, [room, api, media, t, backHome, onClose]);

  const end = useCallback(async (): Promise<string | null> => {
    if (!room) return null;
    mediaRetryRef.current?.abort();
    if (recordingPendingRef.current) throw new Error(t('liveMeeting.room.recording.busy'));
    await recorderRef.current?.finish();
    let meetingId: string | null;
    try { ({ meetingId } = await api.endRoom(room.id)); }
    catch (error) { setRecorderVersion(version => version + 1); throw error; }
    void media.leave();
    phaseRef.current = 'ended';
    setPhase('ended'); // keeps the unmount cleanup from firing a redundant leave
    return meetingId;
  }, [room, api, media, t]);

  const controlRecording = useCallback(async (action: RecordingAction, request?: RecordingRequest) => {
    const current = roomRef.current;
    if (recordingPendingRef.current || phaseRef.current !== 'joined' || !current?.recording || !api.controlRecording) return;
    recordingPendingRef.current = true; setRecordingBusy(true); setRecordingControlError(null);
    try {
      if (action === 'stop') await recorderRef.current?.finish();
      const updated = await api.controlRecording(current.id, action, current.recording.epoch, request?.participantId, request?.requestId);
      if (roomRef.current?.id === current.id && phaseRef.current === 'joined') setRoom(updated);
    } catch (error) {
      const message = error instanceof Error ? error.message : t('liveMeeting.room.errors.generic');
      setRecordingControlError(t('liveMeeting.room.recording.failed', {message}));
      // Permission/stale-state errors must recover the authoritative snapshot.
      void api.getRoom(current.id).then(updated => {
        if (roomRef.current?.id === current.id && phaseRef.current === 'joined') setRoom(updated);
      }).catch(() => {});
    } finally { recordingPendingRef.current = false; setRecordingBusy(false); }
  }, [api, t]);

  // Compatibility for rooms created by the previous server before automatic recording.
  useEffect(() => {
    if (meetingUi.recording && self?.isHost && phase === 'joined' && room?.recording && !room.recording.active) void controlRecording('start');
  }, [self?.isHost, phase, room?.id, room?.recording?.active, controlRecording]);

  const recordingNoticeRef = useRef<{roomId: string; active: boolean; epoch: number} | null>(null);
  const seenRecordingRequests = useRef(new Set<string>());
  useEffect(() => {
    if (!self?.isHost || phase !== 'joined') return;
    for (const request of room?.recording?.requests ?? []) {
      if (request.status !== 'pending' || seenRecordingRequests.current.has(request.requestId)) continue;
      seenRecordingRequests.current.add(request.requestId);
      toast.info(t('liveMeeting.room.recording.requestNotice', {name:request.name}));
    }
  }, [self?.isHost, phase, room?.recording?.requests, t]);
  useEffect(() => {
    if (phase !== 'joined' || !room?.recording) return;
    const previous = recordingNoticeRef.current, state = room.recording;
    if (state.active && (!previous || previous.roomId !== room.id || previous.epoch !== state.epoch)) toast.info(t('liveMeeting.room.recording.startedNotice'));
    else if (!state.active && previous?.roomId === room.id && previous.active) toast.info(t('liveMeeting.room.recording.stoppedNotice'));
    recordingNoticeRef.current = {roomId:room.id, active:state.active, epoch:state.epoch};
  }, [phase, room?.id, room?.recording?.active, room?.recording?.epoch, t]);

  const value = useMemo<RoomContextValue>(() => ({
    updateSettings: async (patch) => {
      if (!meetingUi.settings) return;
      if(!room || !self?.isHost) throw new Error(t('liveMeeting.room.settings.hostOnly'));
      const updated=await api.updateRoom(room.id,patch);
      if(roomIdRef.current===room.id)setRoom(updated);
    },
    recordingState, recordingError, recordingBusy, recordingControlError, controlRecording,
    retryRecording: async () => { if (room?.recording && !room.recording.active) await controlRecording('start'); else await recorderRef.current?.retryUploads(); },
    phase, entryStatus, retryEntry, cancelEntry,
    room,
    self,
    isHost: !!self?.isHost,
    activeSpeakerId: isMock?activeSpeakerId:(room?.participants.find(p=>p.micOn&&p.userId===mediaState.activeSpeakerUsername)?.id??null),
    messages,
    chatStatus, chatError, chatHasOlder, chatLoadingOlder, fileProgress,
    cancelFile: () => imChatRef.current?.cancelUpload(),
    retryChat: () => { if (imStatus === 'error') relogin(); setChatRetry(n => n + 1); },
    loadOlderChat: async () => {
      try { await imChatRef.current?.loadOlder(); }
      catch (error) { toast.error(error instanceof Error ? error.message : t('liveMeeting.room.chat.unavailable')); }
    },
    errorText,
    panelTab,
    chatGroupId, chatUnread,
    setChatAtBottom: bottom => imChatRef.current?.setAtBottom(bottom),
    connectionState,
    mediaAvailable,
    mediaState,audioLevels,screenState,mediaDeviceError,retryMedia,mediaRecovering,mediaRecoveryError,retryScreen: () => { if (meetingUi.screenShare) void media.screen?.retry(); },fileSending,downloadFile,
    audioConnected, audioPreferences, setAudioPreferences, connectAudio, disconnectAudio,
    setPanelTab: (tab) => {
      if ((tab === 'chat' && !meetingUi.chat) || (tab === 'members' && !meetingUi.members)) return;
      setPanelTab(tab);
      if (isMock && tab === 'chat') setChatUnread(0);
    },
    toggleMic,
    toggleCam,
    toggleHand,
    toggleShare,
    admit,
    deny,
    approveHand,
    setParticipantMuted,
    removeParticipant,
    transferHost,
    setAllMuted,
    chatReply, setChatReply, sendChat,
    sendFile,
    leave,
    end,
    backHome,
  }), [
    recordingState, recordingError, recordingBusy, recordingControlError, controlRecording,
    phase, entryStatus, retryEntry, cancelEntry, room, self, activeSpeakerId, messages, errorText, panelTab, chatUnread, connectionState, mediaAvailable,
    chatGroupId, chatStatus, chatError, chatHasOlder, chatLoadingOlder, fileProgress, imStatus, relogin,
    mediaState,audioLevels,screenState,mediaDeviceError,retryMedia,mediaRecovering,mediaRecoveryError,fileSending,downloadFile,
    audioConnected, audioPreferences, setAudioPreferences, connectAudio, disconnectAudio,
    toggleMic, toggleCam, toggleHand, toggleShare,
    admit, deny, approveHand, setParticipantMuted, removeParticipant, transferHost, setAllMuted,
    chatReply, sendChat, sendFile, leave, end, backHome,
  ]);

  return <RoomContext.Provider value={value}>{children}</RoomContext.Provider>;
}
