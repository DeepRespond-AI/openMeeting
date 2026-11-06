import {createDRClient} from '../../../frontend/node_modules/@deeprespond/im-web/dist/index.js';
import {ImChannelMediaClient as ProductionMedia} from '../../../frontend/src/services/live-meeting/media/imChannel';
import {withScreenFailures} from './im-rtc-screen-failures.mjs';

/** Real patched SDK and deployed RTC; only business IPC/chat and capture are fixtures. */
export class ImChannelMediaClient extends ProductionMedia {
  private client:ReturnType<typeof createDRClient>|null=null;
  async connect() {
    const fixture=(window as any).__shareFixture;
    fixture.rtcScope ||= crypto.randomUUID();
    const config=await fetch(`http://127.0.0.1:3177/config/${fixture.session}?scope=${fixture.rtcScope}`).then(async r=>{if(!r.ok)throw Error(`IM setup HTTP ${r.status}`);return r.json();});
    // The business fixture binds this alias to the independently authenticated IM user.
    await fetch(`${(window as any).__rtcBackend}/control`,{method:'POST',body:JSON.stringify({session:fixture.session,patch:{username:config.username}})});
    // Production IM authentication outlives individual meetings. Retain this
    // browser's SDK/device identity while its previous RTC session releases.
    const client=fixture.im||this.client||createDRClient({apiUrl:config.apiUrl,appKey:config.appKey,storage:'memory',tokenStorage:'memory',sessionScope:'tab'});
    this.client=client;
    if(client.auth.currentUser?.username!==config.username)await client.auth.loginWithTicket({ticket:config.loginTicket});
    await client.connection.waitUntilReady({timeoutMs:15000});
    const channels=client.channels;
    const wrap=async(handle:any)=>withScreenFailures(handle,fixture);
    const proxy=new Proxy(channels,{get(target,key){if(key==='join')return async(...args:any[])=>wrap(await (target.join as any)(...args));const value=Reflect.get(target,key,target);return typeof value==='function'?value.bind(target):value;}});
    fixture.media=this;fixture.im=client;
    this.subscribe(s=>fixture.mediaState={status:s.status,reason:s.reason});
    await super.connect({transport:'dr-rtc',channelId:config.channelId,ticket:config.ticket,expiresAt:config.expiresAt},proxy);
  }
  async leave(preserve=false){await super.leave(preserve);}
}
