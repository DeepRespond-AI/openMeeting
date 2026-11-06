// Explicit SDK substitute, independent of React so failure branches can be smoked first.
export function installMeetingFixture(client, read, change = () => {}) {
  const listeners = new Set(), events = new Map();
  let messages = [];
  let activeGroup;
  const histories = new Map();
  let pending = [];
  const calls = () => read().chatCalls ||= [];
  const emit = (name, value) => { for (const cb of events.get(name) || []) cb(value); };
  const changed = () => { listeners.forEach(cb => cb()); change(); };
  const raw = (message, seq = messages.length + 1) => ({
    conversation_id: 'meeting-layout-group', conversation_key: 'meeting-layout-group',
    message_id: `m-${seq}`, client_msg_id: `client-${seq}`, seq, sender: 'layout-self',
    sender_type: 'user', created_at: '2026-10-23T08:00:00Z',
    _local: { status: 'sent', trusted: false }, ...message,
  });
  const file = index => ({file_id:`file-${index}`,url:`https://im.fixture/file/${index}`,name:`${index}-会议文件-LongFilename0123456789.txt`,size:100,owner:'layout-self',owner_nickname:'测试上传者'});
  client.on = (name, cb) => { if (!events.has(name)) events.set(name, new Set()); events.get(name).add(cb); return () => events.get(name)?.delete(cb); };
  client.auth = {currentUser:{username:'layout-self'}};
  client.config = {group_read_ack_enabled:true};
  client.users = {
    get: username => ({username,nickname:'IM 公开昵称',avatar_url:''}),
    fetch: async names => {
      if (read().profileError) throw Error('资料服务暂不可用');
      return new Map(names.map(username => [username,{username,nickname:'IM 公开昵称',avatar_url:''}]));
    },
  };
  client.conversations.refresh = async (group='meeting-layout-group') => {
    if (activeGroup !== group) {
      if (activeGroup) histories.set(activeGroup,messages);
      activeGroup=group;messages=histories.get(group)||[];
    }
    return {conversation_key:group,conversation_id:group,unread_count:read().unread || 0};
  };
  client.conversations.get = async () => ({unread_count:read().unread || 0});
  const markRead = () => { calls().push({operation:'read'}); read().unread=0; emit('conversations.changed', {}); };
  client.messages.open = () => ({
    getSnapshot: () => ({items:messages,hasOlder:!read().olderLoaded,hasNewer:false,loading:read().chatLoading?'initial':'none'}),
    subscribe: cb => { listeners.add(cb); return () => listeners.delete(cb); },
    setViewing: value => calls().push({operation:'viewing',...value}), markRead,dispose:()=>{},
    loadOlder: async () => {
      if (read().historyError) throw Error('历史消息加载失败');
      read().olderLoaded=true; messages=[raw({sender:'member-1',body:{text:'更早的会议消息'},type:'text'},0),...messages]; changed();
    },
  });
  const workbenchSend = client.messages.send;
  client.messages.send = async (target, message, options) => {
    calls().push({operation:'send',target,message,options});
    if (!target.to_group) return workbenchSend?.(target,message,options);
    const item=raw({...message,reply_to:options?.reply_to,need_receipt:options?.need_receipt});
    if(read().sendError)item._local.status='failed';
    messages=[...messages,item]; changed();
    if(read().sendError)throw Error('发送失败，请重试');
    return item;
  };
  client.messages.canRecall = m => m.sender==='layout-self' && !m.recalled && m._local.status==='sent';
  client.messages.recall = async (_id,seq) => {
    if(read().actionDenied)throw Error('权限不足，无法撤回此消息');
    messages=messages.map(m=>m.seq===seq?{...m,recalled:{}}:m); changed();
  };
  client.messages.react = async (_id,seq,key) => {
    if(read().actionDenied)throw Error('权限不足，无法操作消息');
    messages=messages.map(m=>m.seq===seq?{...m,reactions:[{key,count:1,reacted:true}]}:m);changed();
  };
  client.messages.unreact = async (_id,seq) => {messages=messages.map(m=>m.seq===seq?{...m,reactions:[]}:m);changed();};
  client.messages.resend = async id => {messages=messages.map(m=>m.client_msg_id===id?{...m,_local:{status:'sent'}}:m);changed();};
  client.messages.discard = async id => {messages=messages.filter(m=>m.client_msg_id!==id);changed();};
  client.messages.receipts = async (_id,seqs) => seqs.map(seq=>({seq,read_count:2,unread_count:1}));
  client.messages.forward = async (message,target) => {calls().push({operation:'forward',message,target});};
  client.files = {
    prepare: async file => ({blob:file,duration_seconds:3,format:'mp4',width:640,height:360}),
    isFileUrl:url=>url.startsWith('https://im.fixture/'),
    upload:async (file,options)=>{
      calls().push({operation:'upload',purpose:options.purpose,group_id:options.group_id,kind:options.kind});
      options.onProgress(50,100);
      if(read().uploadError)throw Error('文件上传失败');
      if(read().pauseUpload)await new Promise((resolve,reject)=>options.signal.addEventListener('abort',()=>reject(Error('已取消上传')),{once:true}));
      options.onProgress(100,100);return{url:'https://im.fixture/file/report',name:file.name,size:file.size};
    },
    groupFiles:async (_id, page)=>{
      calls().push({operation:'files',cursor:page?.cursor});
      if(read().pauseFiles)await new Promise(resolve=>pending.push(resolve));
      if(read().fileError)throw Error('群文件读取失败，请重试');
      if(read().fileDenied)throw Error('权限不足：你已不在该会议群');
      return {items:read().emptyFiles?[]:Array.from({length:page?.cursor?2:14},(_,i)=>file((page?.cursor?14:0)+i)),next_cursor:read().emptyFiles||page?.cursor?null:'page-2'};
    },
    fetchBlob:async()=>new Blob(['<svg xmlns="http://www.w3.org/2000/svg" width="400" height="240"><rect width="400" height="240" fill="#2563eb"/><text x="80" y="130" fill="white" font-size="28">IM image preview</text></svg>'],{type:'image/svg+xml'}),
  };
  client.desktop={
    fileUrl: path => path,
    download:async (source, options={})=>{
      calls().push({operation:'download',source,saveTo:options.saveTo});
      if(read().downloadError)throw Error('下载失败，请重试');
      if(read().previewDenied)throw Error('权限不足，无法预览此附件');
      options.onProgress?.(1,2);
      if(read().pausePreview)await new Promise((resolve,reject)=>{
        pending.push(resolve);
        options.signal?.addEventListener('abort',()=>{calls().push({operation:'downloadCancelled',saveTo:options.saveTo});reject(Error('已取消预览'));},{once:true});
      });
      options.onProgress?.(2,2);
      return {path:read().previewSources?.[source.message?.body?.url]||read().previewSrc||'data:image/svg+xml,'+encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360"><rect width="640" height="360" fill="teal"/><text x="120" y="180" fill="white" font-size="28">Meeting attachment preview</text></svg>'),size:2};
    },
  };
  return {
    control(patch) {
      Object.assign(read(),patch);
      if(patch.messages)messages=patch.messages.map((m,i)=>raw(m,i+1));
      if(patch.seed){ messages=Array.from({length:18},(_,i)=>raw({sender:i%2?'member-1':'layout-self',type:'text',body:{text:i===17?'LongText0123456789'.repeat(30):`会议历史 ${i+1}`}},i+1)); }
      if(patch.emptyMessages)messages=[];
      if(patch.unread!==undefined)emit('conversations.changed',{});
      if(patch.pauseFiles===false){pending.forEach(resolve=>resolve());pending=[];}
      if(patch.pausePreview===false){pending.forEach(resolve=>resolve());pending=[];}
      if(patch.receive)emit('message.received',{message:patch.receive});
      changed();
    },
    calls, raw,
  };
}
