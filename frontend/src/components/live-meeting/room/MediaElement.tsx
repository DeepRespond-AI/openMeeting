'use client';
import {useEffect,useRef,useState} from 'react';
import type {MediaTrack} from '@/services/live-meeting';
import {useT} from '@/i18n';
import { routeAudio } from '@/services/live-meeting/media/audioDevices';

/** MediaStreamTracks belong to the media client; elements only bind/detach them. */
export default function MediaElement({item,muted=false,speakerId='default'}:{item:MediaTrack;muted?:boolean;speakerId?:string}) {
  const t=useT();
  const ref=useRef<HTMLMediaElement|null>(null);
  const [blocked,setBlocked]=useState(false);
  const [routingError,setRoutingError]=useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    let active = true;
    el.srcObject = new MediaStream([item.track]);
    // Route before unmuting or playing, including newly subscribed tracks.
    el.muted = true;
    void (async () => {
      if (item.kind === 'audio') {
        try { await routeAudio(el, speakerId); }
        catch { if (active) setRoutingError(true); return; }
      }
      if (!active) return;
      setRoutingError(false);
      el.muted = muted || item.kind === 'video' || item.local;
      try { await el.play(); if (active) setBlocked(false); }
      catch { if (active && item.kind === 'audio') setBlocked(true); }
    })();
    return () => { active = false; el.pause(); el.srcObject = null; };
  }, [speakerId, item.track, item.kind, item.local, muted]);
  if(item.kind==='video')return <video ref={el=>{ref.current=el;}} data-media-track={item.key} autoPlay playsInline muted
    className={`absolute inset-0 h-full w-full ${item.source==='screen'?'object-contain':'object-cover'} ${item.local&&item.source!=='screen'?'-scale-x-100':''}`} />;
  return <>
    <audio ref={el=>{ref.current=el;}} data-media-track={item.key} autoPlay muted />
    {routingError&&<span role="alert" className="rounded-lg bg-destructive/15 px-3 py-2 text-xs text-destructive">{t('liveMeeting.room.audio.outputFailed')}</span>}
    {blocked&&<button type="button" className="relative z-20 rounded-lg bg-primary px-3 py-2 text-xs"
      onClick={()=>void ref.current?.play().then(()=>setBlocked(false)).catch(()=>setBlocked(true))}>{t('liveMeeting.room.rtc.playAudio')}</button>}
  </>;
}
