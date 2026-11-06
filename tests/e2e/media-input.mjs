/** Installed only in dedicated E2E clients, before the application loads. */
export function installMediaProbe({synthetic}) {
  window.__meetingE2E={peers:[],captures:[]};
  const Peer=window.RTCPeerConnection;
  window.RTCPeerConnection=new Proxy(Peer,{construct(target,args,newTarget){
    const peer=Reflect.construct(target,args,newTarget);
    window.__meetingE2E.peers.push(peer);
    return peer;
  }});
  const display=navigator.mediaDevices.getDisplayMedia?.bind(navigator.mediaDevices);
  if(display)navigator.mediaDevices.getDisplayMedia=async options=>{
    const stream=await display(options);
    window.__meetingE2E.captures.push(stream.getVideoTracks()[0]?.getSettings());
    return stream;
  };
  if(!synthetic)return;
  navigator.mediaDevices.getUserMedia=async constraints=>{
    const stream=new MediaStream();
    if(constraints.audio){
      const context=new AudioContext(),oscillator=context.createOscillator(),gain=context.createGain(),destination=context.createMediaStreamDestination();
      gain.gain.value=.04;oscillator.connect(gain);gain.connect(destination);
      await context.resume();oscillator.start();
      const track=destination.stream.getAudioTracks()[0],stop=track.stop.bind(track);
      track.stop=()=>{oscillator.stop();void context.close();stop();};stream.addTrack(track);
    }
    if(constraints.video){
      const canvas=document.createElement('canvas');canvas.width=640;canvas.height=360;
      const context=canvas.getContext('2d');let frame=0;
      const draw=()=>{context.fillStyle=`hsl(${frame++%360} 70% 40%)`;context.fillRect(0,0,640,360);context.fillStyle='white';context.font='28px sans-serif';context.fillText(`Meeting E2E ${frame}`,20,100);};
      draw();const timer=setInterval(draw,50),track=canvas.captureStream(20).getVideoTracks()[0],stop=track.stop.bind(track);
      track.stop=()=>{clearInterval(timer);stop();};stream.addTrack(track);
    }
    return stream;
  };
}
