'use client';

import { useState, useCallback, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useChat } from '@/hooks/useChat';
import { useVisualViewport } from '@/hooks/useVisualViewport';
import { verifyPassword, getRoomStatus, updateParticipantCount } from '@/lib/room/actions';
import type { ChatStatus } from '@/types/chat';
import ChatHeader from './ChatHeader';
import ChatMessageArea, { type ChatMessageAreaHandle } from './ChatMessageArea';
import ChatInput from './ChatInput';
import PasswordEntry from './PasswordEntry';
import RoomCreatedView from './RoomCreatedView';
import LeaveConfirmModal from './LeaveConfirmModal';
import RoomDestroyedOverlay from './RoomDestroyedOverlay';
import SystemMessage from './SystemMessage';

interface ChatRoomProps {
  roomId: string;
  isCreator: boolean;
  initialPassword?: string;
}

export default function ChatRoom({ roomId, isCreator, initialPassword }: ChatRoomProps) {
  const router = useRouter();
  useVisualViewport();
  const [password, setPassword] = useState<string | null>(initialPassword ?? null);
  const [viewState, setViewState] = useState<'password' | 'created' | 'chat' | 'destroyed'>(
    isCreator ? 'created' : 'password'
  );
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [showLeaveModal, setShowLeaveModal] = useState(false);
  const messageAreaRef = useRef<ChatMessageAreaHandle>(null);

  // 비밀번호가 확인되면 채팅 훅 활성화
  const chatEnabled = password !== null && (viewState === 'chat' || viewState === 'created');
  const chat = useChat({
    roomId,
    password: password ?? '',
  });

  // 비밀번호 입력 처리 (참여자)
  const handlePasswordSubmit = useCallback(async (inputPassword: string) => {
    setPasswordLoading(true);
    setPasswordError(null);

    const result = await verifyPassword(roomId, inputPassword);

    if (result.valid) {
      setPassword(inputPassword);
      setViewState('chat');
    } else {
      const errorMap: Record<string, string> = {
        ROOM_FULL: 'CHANNEL_FULL',
        ROOM_DESTROYED: 'CHANNEL_EXPIRED',
        ROOM_EXPIRED: 'CHANNEL_EXPIRED',
        INVALID_PASSWORD: 'INVALID_KEY',
      };
      setPasswordError(errorMap[result.error ?? ''] ?? 'INVALID_KEY');
    }
    setPasswordLoading(false);
  }, [roomId]);

  // 방 생성자가 "입장" 클릭
  const handleEnterChat = useCallback(() => {
    setViewState('chat');
  }, []);

  // 퇴장 처리
  const handleLeave = useCallback(() => {
    setShowLeaveModal(true);
  }, []);

  const handleConfirmLeave = useCallback(async () => {
    setShowLeaveModal(false);
    chat.disconnect();
    await updateParticipantCount(roomId, 0);
    setViewState('destroyed');
  }, [chat, roomId]);

  // 상태별 렌더링
  if (chat.status === 'room_full') {
    return <RoomDestroyedOverlay reason="full" />;
  }

  if (viewState === 'destroyed' || chat.status === 'destroyed') {
    return <RoomDestroyedOverlay />;
  }

  if (viewState === 'password') {
    return (
      <PasswordEntry
        onSubmit={handlePasswordSubmit}
        error={passwordError}
        loading={passwordLoading}
      />
    );
  }

  if (viewState === 'created' && isCreator && password) {
    return (
      <RoomCreatedView
        roomId={roomId}
        password={password}
        onEnter={handleEnterChat}
        peerConnected={chat.peerConnected}
      />
    );
  }

  // 채팅 화면
  return (
    <div className="flex flex-col h-(--app-height,100dvh) bg-void-black text-ink overflow-hidden">
      <ChatHeader
        roomId={roomId}
        peerConnected={chat.peerConnected}
        onLeave={handleLeave}
      />

      {/* E2EE 시스템 메시지 */}
      {chat.messages.length === 0 && (
        <div className="px-4 pt-4">
          <SystemMessage content="E2E ENCRYPTION ACTIVE" />
          <SystemMessage content={`YOU ARE ${chat.myUsername}`} />
          {!chat.peerConnected && (
            <SystemMessage content="WAITING FOR PEER..." />
          )}
        </div>
      )}

      <ChatMessageArea ref={messageAreaRef} messages={chat.messages} />

      <ChatInput
        onSend={chat.sendMessage}
        disabled={!chat.peerConnected}
      />

      <LeaveConfirmModal
        isOpen={showLeaveModal}
        isLastPerson={!chat.peerConnected}
        onConfirm={handleConfirmLeave}
        onCancel={() => setShowLeaveModal(false)}
      />
    </div>
  );
}
