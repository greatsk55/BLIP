'use client';

import { useState, useCallback, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useGroupChat, type GroupPresenceUser } from '@/hooks/useGroupChat';
import { useNotification } from '@/hooks/useNotification';
import { useVisualViewport } from '@/hooks/useVisualViewport';
import { deriveKeysFromPassword, hashAuthKey } from '@/lib/crypto';
import { updateGroupParticipantCount, destroyGroupRoom, toggleGroupLock, banUserFromGroup } from '@/lib/group/actions';
import GroupChatHeader from './GroupChatHeader';
import ChatMessageArea, { type ChatMessageAreaHandle } from '@/components/chat/ChatMessageArea';
import ChatInput from '@/components/chat/ChatInput';
import LeaveConfirmModal from '@/components/chat/LeaveConfirmModal';
import RoomDestroyedOverlay from '@/components/chat/RoomDestroyedOverlay';
import SystemMessage from '@/components/chat/SystemMessage';
import ParticipantSidebar from './ParticipantSidebar';

interface GroupChatRoomProps {
  roomId: string;
  password: string;
  isAdmin: boolean;
  adminToken?: string;
  title: string;
}

export default function GroupChatRoom({
  roomId,
  password,
  isAdmin,
  adminToken,
  title,
}: GroupChatRoomProps) {
  const router = useRouter();
  useVisualViewport();
  const { notifyMessage } = useNotification();
  const [showLeaveModal, setShowLeaveModal] = useState(false);
  const [showSidebar, setShowSidebar] = useState(false);
  const messageAreaRef = useRef<ChatMessageAreaHandle>(null);

  const chat = useGroupChat({
    roomId,
    password,
    isAdmin,
    adminToken,
    onMessageReceived: notifyMessage,
  });

  const handleConfirmLeave = useCallback(async () => {
    setShowLeaveModal(false);
    chat.disconnect();
    if (password) {
      const { authKey } = await deriveKeysFromPassword(password, roomId);
      const authHash = await hashAuthKey(authKey);
      await updateGroupParticipantCount(roomId, Math.max(0, chat.participants.length - 1), authHash);
    }
  }, [chat, roomId, password]);

  const handleKick = useCallback(
    (userId: string) => {
      chat.kickUser(userId);
    },
    [chat]
  );

  const handleBan = useCallback(
    async (userId: string) => {
      if (!adminToken) return;
      await banUserFromGroup(roomId, adminToken, userId);
      chat.kickUser(userId);
    },
    [roomId, adminToken, chat]
  );

  const handleLock = useCallback(
    async (lock: boolean) => {
      if (!adminToken) return;
      await toggleGroupLock(roomId, adminToken, lock);
    },
    [roomId, adminToken]
  );

  const handleDestroy = useCallback(async () => {
    if (!adminToken) return;
    // 방 폭파 브로드캐스트
    if (chat.channel) {
      chat.channel.send({
        type: 'broadcast',
        event: 'room_destroyed',
        payload: {},
      });
    }
    await destroyGroupRoom(roomId, adminToken);
    chat.disconnect();
  }, [roomId, adminToken, chat]);

  if (chat.status === 'destroyed') {
    return <RoomDestroyedOverlay />;
  }

  return (
    <div className="flex flex-col h-(--app-height,100dvh) bg-void-black text-ink overflow-hidden">
      <GroupChatHeader
        roomId={roomId}
        title={title}
        participantCount={chat.participants.length}
        isAdmin={isAdmin}
        onLeave={() => setShowLeaveModal(true)}
        onToggleSidebar={() => setShowSidebar(!showSidebar)}
        onLock={() => handleLock(true)}
        onUnlock={() => handleLock(false)}
        onDestroy={handleDestroy}
      />

      <div className="flex flex-1 overflow-hidden relative">
        <div className="flex-1 flex flex-col overflow-hidden">
          {chat.messages.length === 0 && (
            <div className="px-4 pt-4">
              <SystemMessage content="E2E ENCRYPTION ACTIVE" />
              <SystemMessage content={`YOU ARE ${chat.myUsername}`} />
              {chat.participants.length <= 1 && (
                <SystemMessage content="WAITING FOR PARTICIPANTS..." />
              )}
            </div>
          )}

          <ChatMessageArea
            ref={messageAreaRef}
            messages={chat.messages}
            onImageClick={() => {}}
            screenCaptured={false}
          />

          <ChatInput
            onSend={chat.sendMessage}
            onSendFile={async () => {}}
            disabled={chat.participants.length <= 1}
            mediaDisabled={true}
          />
        </div>

        {/* 참여자 사이드바 */}
        <ParticipantSidebar
          isOpen={showSidebar}
          participants={chat.participants}
          myId={chat.myId}
          isAdmin={isAdmin}
          onClose={() => setShowSidebar(false)}
          onKick={handleKick}
          onBan={handleBan}
        />
      </div>

      <LeaveConfirmModal
        isOpen={showLeaveModal}
        isLastPerson={chat.participants.length <= 1}
        onConfirm={handleConfirmLeave}
        onCancel={() => setShowLeaveModal(false)}
      />
    </div>
  );
}
