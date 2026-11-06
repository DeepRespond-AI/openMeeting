/** Wait for authenticated deployment configuration instead of binding a fresh
 * installation to the demo app before its first login. */
import {createDRTauriEngine,type DREngine} from '@deeprespond/im-tauri/engine';
import {invoke} from '@tauri-apps/api/core';
import {listen} from '@tauri-apps/api/event';
import {createMeetingNotifications} from './meeting-notifications';

interface ImTicketResponse {ticket:string;apiUrl:string;appKey:string;}
let engine:DREngine|null=null;
let booting=false;
async function fetchTicket(){return (await invoke<ImTicketResponse>('im_get_ticket')).ticket;}
async function bootstrap(){
  if(engine||booting)return;
  booting=true;
  try{
    const config=await invoke<ImTicketResponse>('im_get_ticket');
    let notifications: ReturnType<typeof createMeetingNotifications> | undefined;
    engine=createDRTauriEngine({
      appKey:config.appKey,apiUrl:config.apiUrl,ticketProvider:fetchTicket,
      badge:'manual',
      notifications:{notices:false,calls:'manual',format:alert=>notifications?.format(alert)??null},
    });
    notifications=createMeetingNotifications(engine.client);
    document.title='deeprespond-im-engine';
  }catch{
    document.title='deeprespond-im-engine-waiting-for-config';
  }finally{booting=false;}
}
void listen<{loggedIn:boolean}>('server-status',({payload})=>{
  if(payload.loggedIn)void bootstrap();
  else if(engine)void engine.client.auth.logout().catch(()=>{});
}).then(()=>bootstrap()).catch(()=>bootstrap());
