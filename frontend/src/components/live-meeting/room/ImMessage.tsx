'use client';
import type { ChatMessage } from '@/services/live-meeting';
import ChatMessageBubble from '@/components/im/ChatMessage';

export default function ImMessage({ message, showTime = false }: { message: ChatMessage; showTime?: boolean }) {
  return <ChatMessageBubble message={message.sdk!} name={message.sender.name} own={message.sender.isSelf} showTime={showTime} />;
}
