/** Deterministic camera input. Does not replace SDK publication or WebRTC transport. */
export function installRtcCamera(){
  const original=navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
  Object.defineProperty(navigator.mediaDevices,'getUserMedia',{configurable:true,value:async constraints=>{
    if(!constraints?.video)return original(constraints);
    const canvas=document.createElement('canvas');canvas.width=640;canvas.height=360;
    const ctx=canvas.getContext('2d');let frame=0;
    const draw=()=>{ctx.fillStyle='#164e63';ctx.fillRect(0,0,640,360);ctx.fillStyle='#fff';ctx.font='30px sans-serif';ctx.fillText(`CAMERA / frame ${++frame}`,30,100);};
    draw();const timer=setInterval(draw,80),stream=canvas.captureStream(12),track=stream.getVideoTracks()[0],stop=track.stop.bind(track);
    track.stop=()=>{clearInterval(timer);stop();};return stream;
  }});
}
