'use client';
import { useRoom } from './RoomProvider';
import { useT } from '@/i18n';
export default function RecordingBanner() {
  const t = useT();
  const {phase,room,self,isHost,recordingState,recordingError,recordingBusy,recordingControlError,retryRecording}=useRoom();
  if (phase !== 'joined') return null;
  const state=room?.recording, mine=state?.requests.find(r=>r.participantId===self?.id);
  const captureError=isHost&&state?.active&&recordingState==='error';
  const error=recordingControlError||(captureError?t('liveMeeting.room.recording.failed',{message:recordingError||''}):null);
  const text=!state?t('liveMeeting.room.recording.unavailable'):
    recordingBusy?t('liveMeeting.room.recording.busy'):
    state.active?t(isHost&&recordingState==='waiting'?'liveMeeting.room.recording.waitingAudio':'liveMeeting.room.recording.startedNotice'):
    !isHost&&mine?.status==='pending'?t('liveMeeting.room.recording.waitingApproval'):
    !isHost&&mine?.status==='denied'?t('liveMeeting.room.recording.denied'):
    t(state.epoch?'liveMeeting.room.recording.stoppedNotice':'liveMeeting.room.recording.off');
  return <div data-testid="room-recording-status" role={error?'alert':'status'} className={`mx-4 my-1 shrink-0 rounded-lg px-3 py-2 text-center text-xs ${error?'bg-destructive/10 text-destructive':'bg-primary/10 text-muted-foreground'}`}>
    <span className="break-words">{error||text}</span>
    {error&&<button type="button" disabled={recordingBusy} className="ml-2 rounded border border-current px-2 py-1" onClick={()=>void retryRecording().catch(()=>{})}>{t('liveMeeting.room.recording.retryUpload')}</button>}
  </div>;
}
