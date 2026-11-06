'use client';
// Explicit development E2E fixture. Uses real app pages, never a native/IM claim.
import {installMeetingFixture} from './meeting-im-sdk.mjs';
import React, {useEffect, useState} from 'react';
const conversation = {conversation_key:'single:layout-peer',conversation_id:'layout-chat',conversation_type:'single',peer:'layout-peer',unread_count:0,muted:false,state:{},last_message:{type:'text',body:{text:'响应式布局验收消息'},created_at:'2026-10-23T08:00:00Z',sender_type:'user'}};
const initial = Array.from({length:20},(_,i)=>({client_msg_id:`layout-${i}`,conversation_id:'layout-chat',type:'text',body:{text:i===19?'长消息：'+('LongContentWithoutSpaces0123456789'.repeat(10)):`布局验收消息 ${i+1}`},sender:i%2?'layout-self':'layout-peer',sender_type:'user',created_at:'2026-10-23T08:00:00Z',seq:i+1,_local:{status:'sent'}}));
const noop=async()=>{};
const read=()=>typeof window==='undefined'?{}:window.__layoutIm||{};
function useRevision(){const [version,setVersion]=useState(0);useEffect(()=>{const change=()=>setVersion(v=>v+1);window.addEventListener('layout-im-change',change);return()=>window.removeEventListener('layout-im-change',change);},[]);return version;}
function change(){window.dispatchEvent(new Event('layout-im-change'));}
const client={on:()=>()=>{},conversations:{list:()=>({kind:'conversations'}),markAllRead:noop,markRead:noop,setDraft:noop,setPinned:noop,remove:noop},friends:{list:()=>({kind:'friends'}),requests:{received:async()=>({items:[],next_cursor:null})}},groups:{list:()=>({kind:'groups'})},messages:{canRecall:()=>false,send:async(_target,message)=>{window.__layoutIm.messages=[...(read().messages||initial),{...initial[0],...message,client_msg_id:crypto.randomUUID(),sender:'layout-self'}];change();}},push:{mute:noop,unmute:noop},channels:null};
const meetingFixture = installMeetingFixture(client, read, change);
client.conversations.list = () => ({kind:'conversations',getSnapshot:()=>({items:[]}),subscribe:()=>()=>{},dispose:()=>{}});
if (typeof window !== 'undefined') window.__meetingFixture = meetingFixture;
export const ImProvider=({children})=><>{children}</>;
export const DRProvider=ImProvider;
export function useIm(){useRevision();return {status:read().mode||'ready',errorText:read().mode==='error'?'测试夹具：消息连接失败，请重试。'+ '长错误说明。'.repeat(15):null,client,relogin:()=>{window.__layoutIm.mode='ready';change();}};}
client.conversations.typing=noop;
export const useDRClient=()=>client;
export const useUnreadTotal=()=>0;
export const useMe=()=>({username:'layout-self'});
export const useConnectionState=()=>({kind:'ready'});
export const useConversationTitle=()=> '项目验收讨论组与超长会话标题的显示检查';
export const useDisplayName=()=> '测试成员';
export function useUser(username){useRevision();return client.users.get(username);}
export function useLiveList(factory){useRevision();const kind=factory(client).kind;return {snapshot:{items:kind==='conversations'&&read().mode!=='empty'?[conversation]:[],loading:false,error:null,hasMore:false},list:{loadMore:noop}};}
export function useMessageList(){useRevision();return {snapshot:{items:read().messages||initial,loading:false,error:null,hasMore:false},list:{loadMore:noop}};}
