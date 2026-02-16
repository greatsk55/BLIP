'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useChat } from '@/hooks/useChat';
import { useWebRTC } from '@/hooks/useWebRTC';
import { useNotification } from '@/hooks/useNotification';
import { useVisualViewport } from '@/hooks/useVisualViewport';
import { useScreenProtection } from '@/hooks/useScreenProtection';
import { verifyPassword, getRoomStatus, updateParticipantCount } from '@/lib/room/actions';
import { compressImage, createImageThumbnail } from '@/lib/media/compress';
import { createVideoThumbnail, getMediaType } from '@/lib/media/thumbnail';
import type { ChatStatus, DecryptedMessage } from '@/types/chat';
import ChatHeader from './ChatHeader';
import ChatMessageArea, { type ChatMessageAreaHandle } from './ChatMessageArea';
import ChatInput from './ChatInput';
import PasswordEntry from './PasswordEntry';
import RoomCreatedView from './RoomCreatedView';
import LeaveConfirmModal from './LeaveConfirmModal';
import RoomDestroyedOverlay from './RoomDestroyedOverlay';
import SystemMessage from './SystemMessage';
import ImageViewer from './ImageViewer';

interface ChatRoomProps {
  roomId: string;
  isCreator: boolean;
  initialPassword?: string;
}

export default function ChatRoom({ roomId, isCreator, initialPassword }: ChatRoomProps) {
  const router = useRouter();
  useVisualViewport();
  const screenCaptured = useScreenProtection();
  const { notifyMessage, requestPermission } = useNotification();
  const [password, setPassword] = useState<string | null>(initialPassword ?? null);
  const [viewState, setViewState] = useState<'password' | 'created' | 'chat' | 'destroyed'>(
    isCreator ? 'created' : 'password'
  );
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [showLeaveModal, setShowLeaveModal] = useState(false);
  const [viewerImage, setViewerImage] = useState<string | null>(null);
  const messageAreaRef = useRef<ChatMessageAreaHandle>(null);

  // 채팅 입장 시 브라우저 알림 권한 요청
  useEffect(() => {
    if (viewState === 'chat') {
      requestPermission();
    }
  }, [viewState, requestPermission]);

  // 비밀번호가 확인되면 채팅 훅 활성화
  const chat = useChat({
    roomId,
    password: password ?? '',
    onMessageReceived: notifyMessage,
  });

  // 미디어 수신 콜백
  const handleMediaReceived = useCallback(
    (message: Omit<DecryptedMessage, 'isMine'>) => {
      chat.addMediaMessage({
        ...message,
        isMine: false,
        senderName: chat.peerUsername ?? 'PEER',
      });
      notifyMessage(chat.peerUsername ?? 'PEER');
    },
    [chat, notifyMessage]
  );

  // WebRTC 연결 (미디어 전송용)
  const webrtc = useWebRTC({
    enabled: chat.peerConnected && chat.sharedSecret !== null,
    channel: chat.channel,
    sharedSecret: chat.sharedSecret,
    isInitiator: chat.isInitiator,
    myId: chat.myId,
    onMediaReceived: handleMediaReceived,
    onTransferProgress: chat.updateTransferProgress,
  });

  // 파일 전송 핸들러
  const handleSendFile = useCallback(
    async (file: File) => {
      const mediaType = getMediaType(file.type);
      if (!mediaType) return;

      const transferId = typeof crypto.randomUUID === 'function'
        ? crypto.randomUUID()
        : `${Date.now()}-${Math.random().toString(36).slice(2)}`;

      // 전송 중 placeholder 메시지 추가
      let thumbnailUrl: string | undefined;
      let metadata: DecryptedMessage['mediaMetadata'];

      if (mediaType === 'image') {
        const thumb = await createImageThumbnail(file);
        thumbnailUrl = URL.createObjectURL(thumb.blob);
        metadata = {
          fileName: file.name,
          mimeType: file.type,
          size: file.size,
          width: thumb.width,
          height: thumb.height,
        };
      } else {
        try {
          const { thumbnail, metadata: videoMeta } = await createVideoThumbnail(file);
          thumbnailUrl = URL.createObjectURL(thumbnail);
          metadata = {
            fileName: file.name,
            mimeType: file.type,
            size: file.size,
            width: videoMeta.width,
            height: videoMeta.height,
            duration: videoMeta.duration,
          };
        } catch {
          metadata = {
            fileName: file.name,
            mimeType: file.type,
            size: file.size,
          };
        }
      }

      // 전송 중 메시지 (프로그레스 표시)
      const localUrl = URL.createObjectURL(file);
      chat.addMediaMessage({
        id: transferId,
        senderId: chat.myId,
        senderName: chat.myUsername,
        content: '',
        timestamp: Date.now(),
        isMine: true,
        type: mediaType,
        mediaUrl: localUrl,
        mediaThumbnail: thumbnailUrl,
        mediaMetadata: metadata,
        transferProgress: 0,
      });

      // WebRTC로 전송 (동일한 transferId 사용)
      await webrtc.sendFile(file, transferId);
    },
    [chat, webrtc]
  );

  // 퇴장 시 WebRTC도 정리
  const handleConfirmLeave = useCallback(async () => {
    setShowLeaveModal(false);
    webrtc.cleanup();
    chat.disconnect();
    await updateParticipantCount(roomId, 0);
    setViewState('destroyed');
  }, [chat, webrtc, roomId]);

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

  const handleEnterChat = useCallback(() => {
    setViewState('chat');
  }, []);

  const handleLeave = useCallback(() => {
    setShowLeaveModal(true);
  }, []);

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

      <ChatMessageArea
        ref={messageAreaRef}
        messages={chat.messages}
        onImageClick={setViewerImage}
        screenCaptured={screenCaptured}
      />

      <ChatInput
        onSend={chat.sendMessage}
        onSendFile={handleSendFile}
        disabled={!chat.peerConnected}
        mediaDisabled={webrtc.webrtcState !== 'connected'}
      />

      <LeaveConfirmModal
        isOpen={showLeaveModal}
        isLastPerson={!chat.peerConnected}
        onConfirm={handleConfirmLeave}
        onCancel={() => setShowLeaveModal(false)}
      />

      {/* 이미지 전체화면 뷰어 */}
      <ImageViewer
        src={viewerImage}
        onClose={() => setViewerImage(null)}
      />
    </div>
  );
}
