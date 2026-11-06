import http from 'node:http';
const longTitle='产品设计评审与跨团队协作会议：窗口缩放、长标题和内容滚动的完整验收';
export async function startLayoutBackend() {
  const sessions=new Map(),calls=[];
  const user={id:'layout-self',phone:'13800138000',name:'响应式测试账号',has_password:true,created_at:null,last_login_at:null};
  const authConfig={registration_open:true,sms_ready:true,code_length:6,resend_interval_sec:60,password_min_length:8,password_max_length:64,server_version:'layout-fixture'};
  const create=()=>({loggedIn:false,participants:5,empty:false,detailError:false,joinError:false,scheduleError:false,delay:0,permission:false,recording:false,rooms:[],scheduled:[]});
  const state=id=>{if(!sessions.has(id))sessions.set(id,create());return sessions.get(id);};
  const transcripts=Array.from({length:65},(_,i)=>({id:`segment-${i}`,text:i===2?'超长无空格文本：'+ 'OverflowContent0123456789'.repeat(20):`第 ${i+1} 条转写，讨论响应式布局和邀请入会占位卡片。`,speaker:i%2?'测试成员二':'测试成员一',audio_start_time:i*10,audio_end_time:i*10+8,timestamp:`00:${String(i).padStart(2,'0')}`}));
  const meetings=Array.from({length:26},(_,i)=>({id:`meeting-layout-${i}`,title:i===0?longTitle:`响应式验收会议记录 ${i+1}`,created_at:'2026-10-23T08:00:00Z',updated_at:'2026-10-23T08:00:00Z',transcript_count:65,has_audio:false,audio_duration:650}));
  const notification={recording_notifications:true,time_based_reminders:true,meeting_reminders:true,respect_do_not_disturb:true,notification_sound:false,system_permission_granted:false,consent_given:true,manual_dnd_mode:false,notification_preferences:{show_recording_started:true,show_recording_stopped:true,show_recording_paused:true,show_recording_resumed:true,show_transcription_complete:true,show_meeting_reminders:true,show_system_errors:true,meeting_reminder_minutes:[5]}};
  const roster=n=>Array.from({length:n},(_,i)=>({id:i?`member-${i}`:'layout-self',userId:i?`member-${i}`:'layout-self',name:i===2?'参会成员的超长姓名用于检查截断和悬浮信息':i?`测试成员 ${i}`:user.name,isSelf:i===0,isHost:i===0,micOn:false,camOn:false,mutedByHost:false,handRaised:false,screenSharing:false,joinedAt:'2026-10-23T08:00:00Z'}));
  const room=s=>({id:s.chatLifecycle?`room-layout-${s.roomSequence||0}`:'room-layout',code:'654321',title:longTitle,hostId:'layout-self',status:'active',participants:roster(s.participants),waiting:[],pwdEnabled:false,waitRoom:false,startedAt:null,endedAt:null,meetingId:null,scheduledMeetingId:null});
  const respond=(res,status,data)=>{res.writeHead(status,{'Content-Type':'application/json','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'*'});res.end(JSON.stringify(data));};
  const server=http.createServer(async(req,res)=>{
    if(req.method==='OPTIONS')return respond(res,200,{});
    try{
      let body='';for await(const part of req)body+=part;
      const input=body?JSON.parse(body):{},s=state(input.session||'default');
      if(req.url==='/control'){Object.assign(s,input.patch);return respond(res,200,{...s,fixtures:true});}
      if(req.url==='/health')return respond(res,200,{fixture:'desktop-layout',sessions:sessions.size});
      const {command,args={}}=input;calls.push({session:input.session,command});
      if(s.delay&&['sched_create','sched_update','api_get_summary','room_join'].includes(command))await new Promise(resolve=>setTimeout(resolve,s.delay));
      const fail=(detail,status=503,code)=>{throw {detail,status,code};};
      let value=null;
      switch(command){
        case 'server_get_config':value={loggedIn:s.loggedIn,clientId:'layout-test'};break;
        case 'server_get_status':case 'server_test_connection':value={configured:true,connected:true,loggedIn:s.loggedIn,authenticated:s.loggedIn,user:s.loggedIn?user:null,authConfig,capabilities:{server_version:'layout-fixture',user,stt:{engine:'fixture',model:'layout',ready:true,error:null},llm:{name:'fixture',model:'layout',ready:true,error:null}},error:null,lastCheck:new Date().toISOString()};break;
        case 'auth_login':if(args.password!=='LayoutTest123!')fail('测试夹具：账号或密码不正确。',401);s.loggedIn=true;value=user;break;
        case 'auth_get_user':value=s.loggedIn?user:null;break;
        case 'auth_logout':s.loggedIn=false;break;
        case 'get_onboarding_status':value={completed:true};break;
        case 'get_audio_devices':value=s.permission?[]:[{name:'布局测试麦克风',device_type:'Input',is_default:true},{name:'布局测试扬声器',device_type:'Output',is_default:true}];break;
        case 'get_audio_backend_info':value=[{id:'cpal',name:'系统音频',description:'显式布局测试夹具'}];break;
        case 'get_current_audio_backend':value='cpal';break;
        case 'get_recording_state':value={is_recording:s.recording,is_paused:false,is_active:s.recording,recording_duration:0,active_duration:0};break;
        case 'is_recording':value=s.recording;break;
        case 'get_recording_preferences':value={auto_save:true,save_folder:'E:/会议录音/'+longTitle.repeat(4),file_format:'wav',preferred_mic_device:'布局测试麦克风',preferred_system_device:'布局测试扬声器'};break;
        case 'get_notification_settings':value=notification;break;
        case 'get_default_recordings_folder_path':value='E:/会议录音/'+longTitle.repeat(4);break;
        case 'plugin:app|version':value='0.4.1-layout-test';break;
        case 'api_get_meetings':value=s.empty?[]:meetings;break;
        case 'api_search_transcripts':case 'api_search_meetings':value=[];break;
        case 'api_get_meeting':case 'api_get_meeting_metadata':if(s.detailError)fail('测试夹具：会议内容加载失败。'+'错误详情用于验证长文本换行。'.repeat(12));value={...meetings[0],id:args.meetingId,transcripts:transcripts.slice(0,50),transcript_count:65,total_transcripts:65};break;
        case 'api_get_meeting_transcripts':value={transcripts:transcripts.slice(args.offset||0,(args.offset||0)+(args.limit||50)),total_count:65,offset:args.offset||0,limit:args.limit||50,has_more:(args.offset||0)+(args.limit||50)<65};break;
        case 'api_get_summary':value={status:'completed',data:{markdown:'# 响应式验收纪要\n\n## 讨论内容\n\n'+longTitle+'\n\n'+('| 检查项 | 结论 |\n| --- | --- |\n| '+longTitle+' | 内容可换行、滚动 |\n')+'\n'+ '说明与跟进事项。'.repeat(120)},error:null};break;
        case 'recording_sync_pending':value=false;break;
        case 'room_recording_status':value={status:'completed',stt_status:'completed',summary_status:'completed',has_audio:false};break;
        case 'server_fetch_meeting_audio':value=null;break;
        case 'sched_list':value=s.scheduled;break;
        case 'sched_create':if(s.scheduleError)fail('测试夹具：预定服务暂不可用。'+'请保留输入，稍后重试。'.repeat(15));value={...args,id:'schedule-layout',code:'654321',host:{id:user.id,name:user.name},createdAt:new Date().toISOString(),updatedAt:new Date().toISOString(),cancelled:false,meetingId:null,reminderEnabled:false};s.scheduled.push(value);break;
        case 'sched_update':{if(s.scheduleError)fail('测试夹具：预定修改暂不可用。');const index=s.scheduled.findIndex(row=>row.id===args.id);if(index<0)fail('测试夹具：预定不存在。',404);value={...s.scheduled[index],...args};s.scheduled[index]=value;break;}
        case 'sched_delete':s.scheduled=[];break;
        case 'room_get_code':if(s.entryCode)fail(s.entryCode==='not_started'?'会议尚未开始，请等待房主进入后重试':'会议号不存在',404,s.entryCode);value=room(s);break;
        case 'room_create':case 'room_get':value=room(s);break;
        case 'room_join':if(s.joinDomainCode)fail('会议尚未开始，请等待房主进入后重试',404,s.joinDomainCode);if(s.joinError)fail('测试夹具：会议不存在。',404);value={room:room(s),self:roster(s.participants)[0],state:'joined',media:{transport:'dr-rtc',channelId:'layout',ticket:'fixture',expiresAt:'2099-01-01T00:00:00Z'}};break;
        case 'room_patch':value={...room(s),...args};break;
        case 'room_chat_session':if(s.chatError)fail('测试夹具：聊天暂不可用');value={transport:'dr-im-group',groupId:s.chatLifecycle?`meeting-layout-group-${s.roomSequence||0}`:'meeting-layout-group'};break;
        case 'room_end':if(s.chatLifecycle)s.roomSequence=(s.roomSequence||0)+1;value={meetingId:'meeting-layout-0'};break;
        default:if(command?.includes('list')||command?.includes('recovery'))value=[];
      }
      respond(res,200,{value});
    }catch(error){respond(res,error.status||500,{error:{detail:error.detail||String(error),status:error.status||500,code:error.code}});}
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const base=`http://127.0.0.1:${server.address().port}`;
  return {base,calls,close:()=>new Promise(resolve=>server.close(resolve))};
}

export function installLayoutBridge({base,session,locale='zh-CN'}) {
  localStorage.setItem('dr.locale',locale);localStorage.setItem('openmeeting:meeting-audio',JSON.stringify({autoJoin:true,microphoneId:'default',speakerId:'default',unmuteSound:false}));
  window.__layoutIm={mode:'ready'};
  window.__layoutRemovedCache=[];
  const callbacks=new Map(),listeners=new Map();let next=1;
  const emit=(event,payload)=>{for(const [id,item]of listeners)if(item.event===event)callbacks.get(item.handler)?.({event,id,payload});};
  window.__layoutEmit=emit;
  window.__TAURI_EVENT_PLUGIN_INTERNALS__={unregisterListener:(_event,id)=>listeners.delete(id)};
  window.__TAURI_INTERNALS__={metadata:{currentWindow:{label:'main'},currentWebview:{label:'main'}},transformCallback(fn){const id=next++;callbacks.set(id,fn);return id;},unregisterCallback:id=>callbacks.delete(id),convertFileSrc:path=>path,
    async invoke(command,args={}){
      if(command==='plugin:fs|remove'){window.__layoutRemovedCache.push(args.path);return;}
      if(command==='plugin:event|listen'){const id=next++;listeners.set(id,args);return id;}
      if(command==='plugin:event|unlisten'){listeners.delete(args.eventId);return;}
      if(command==='plugin:event|emit'){emit(args.event,args.payload);return;}
      if(command==='plugin:store|load')return 1;
      if(command==='plugin:store|get')return [null,false];
      if(command==='plugin:store|has')return false;
      if(command==='plugin:path|resolve_directory')return 'E:/layout-test/';
      if(command==='plugin:path|join')return args.paths.join('/');
      if(command==='plugin:fs|read_text_file')return Array.from(new TextEncoder().encode('会议附件预览\n<script>这里只是文本，不会执行</script>\n'+ '长文本内容用于检查换行。'.repeat(80)));
      const response=await fetch(base+'/invoke',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({session,command,args})});
      const data=await response.json();if(data.error)throw data.error.detail;
      if(command==='room_signal_connect')setTimeout(()=>emit('room-connection',{roomId:args.roomId,state:'connected'}),10);
      return data.value;
    }};
  Object.defineProperty(navigator.clipboard,'writeText',{configurable:true,value:async text=>{if(window.__layoutDenyClipboard)throw new DOMException('Denied','NotAllowedError');window.__layoutClipboard=text;}});
}
