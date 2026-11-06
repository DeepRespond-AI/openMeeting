import type {MediaClient,MediaState} from '../../../frontend/src/services/live-meeting/media/types';
/** No device capture: this fixture verifies layout and controls, not media transport. */
export class ImChannelMediaClient implements MediaClient {
  private listeners=new Set<(state:MediaState)=>void>();
  private state:MediaState={status:'idle',tracks:[],speakerEnabled:true};
  subscribe(listener:(state:MediaState)=>void){this.listeners.add(listener);listener(this.state);return()=>{this.listeners.delete(listener);};}
  private update(patch:Partial<MediaState>){this.state={...this.state,...patch};this.listeners.forEach(listener=>listener(this.state));}
  async connect(){this.update({status:'connected'});}
  async setMicEnabled(){}
  async setCamEnabled(){}
  async startScreenShare(){throw new Error('布局夹具不提供系统屏幕捕获');}
  async stopScreenShare(){}
  async setSpeakerEnabled(speakerEnabled:boolean){this.update({speakerEnabled});}
  async setMicrophoneDevice(microphoneDeviceId:string){this.update({microphoneDeviceId});}
  async setSpeakerDevice(speakerDeviceId:string){this.update({speakerDeviceId});}
  async leave(){this.update({status:'idle',tracks:[]});}
}
