'use client';
import ClientOnly from '@/components/shared/ClientOnly';
import { readInvitation } from '@/lib/room/invitation';
import Link from 'next/link';

import { useState, useEffect } from 'react';
import { getRoomStatus, verifyPassword } from '@/lib/room/actions';
import ChatRoom from '@/components/chat/ChatRoom';
import { postToParent } from '@/lib/embed/postMessage';

interface EmbedRoomClientProps {
  roomId: string;
}

function EmbedRoomClientContent({ roomId }: EmbedRoomClientProps) {
  const [roomExists, setRoomExists] = useState<boolean | null>(null);
  const [roomError, setRoomError] = useState<string | null>(null);
  const [invitation] = useState(() => readInvitation(window.location.href));
  const creatorPassword = invitation.creator;
  const [linkPassword, setLinkPassword] = useState(invitation.creator ? undefined : invitation.password);
  const hashParsed = true;
  const [linkVerified, setLinkVerified] = useState(false);
  useEffect(() => {
    if (window.location.hash || /[?&][kp]=/.test(window.location.search)) {
      window.history.replaceState(null, '', window.location.pathname);
    }
  }, []);

  // 링크 검증
  useEffect(() => {
    if (!hashParsed || !linkPassword) return;
    async function autoVerify() {
      const result = await verifyPassword(roomId, linkPassword!);
      if (result.valid) {
        setLinkVerified(true);
        setRoomExists(true);
        postToParent({ type: 'blip:room-joined', roomId });
      } else {
        const errorMap: Record<string, string> = {
          ROOM_NOT_FOUND: 'ROOM_NOT_FOUND',
          ROOM_FULL: 'ROOM_FULL',
          ROOM_DESTROYED: 'ROOM_DESTROYED',
          ROOM_EXPIRED: 'ROOM_EXPIRED',
          INVALID_PASSWORD: 'INVALID_PASSWORD',
        };
        setRoomError(errorMap[result.error ?? ''] ?? 'INVALID_PASSWORD');
        setRoomExists(false);
        setLinkPassword(undefined);
      }
    }
    autoVerify();
  }, [hashParsed, linkPassword, roomId]);

  // 방 상태 확인
  useEffect(() => {
    if (!hashParsed || linkPassword) return;
    async function checkRoom() {
      const result = await getRoomStatus(roomId);
      if (!result.exists) {
        setRoomError('ROOM_NOT_FOUND');
        setRoomExists(false);
      } else if (result.status === 'destroyed') {
        setRoomError('ROOM_DESTROYED');
        setRoomExists(false);
      } else if (result.status === 'expired') {
        setRoomError('ROOM_EXPIRED');
        setRoomExists(false);
      } else {
        setRoomExists(true);
        if (creatorPassword) {
          postToParent({ type: 'blip:room-joined', roomId });
        }
      }
    }
    checkRoom();
  }, [roomId, hashParsed, linkPassword, creatorPassword]);

  // 방이 존재하지 않으면 부모에게 알림
  useEffect(() => {
    if (roomExists === false) {
      postToParent({ type: 'blip:room-destroyed', roomId });
    }
  }, [roomExists, roomId]);

  const linkVerifying = !!linkPassword && !linkVerified && !roomError;

  if (roomExists === null || linkVerifying) {
    return (
      <div className="h-dvh bg-void-black flex items-center justify-center">
        <span className="font-mono text-xs text-ghost-grey/40 uppercase tracking-widest animate-pulse">
          CONNECTING...
        </span>
      </div>
    );
  }

  if (!roomExists) {
    return (
      <div className="h-dvh bg-void-black flex flex-col items-center justify-center px-6 text-center">
        <p className="font-mono text-xs text-glitch-red tracking-[0.3em] uppercase mb-6">
          {roomError}
        </p>
        <p className="font-mono text-sm text-ghost-grey mb-10">
          This channel no longer exists.
        </p>
        <Link
          href="/embed"
          className="min-h-[48px] flex items-center px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300 font-mono text-sm uppercase tracking-wider"
        >
          CREATE NEW
        </Link>
      </div>
    );
  }

  const isCreator = !!creatorPassword;
  const resolvedPassword = creatorPassword ?? (linkVerified ? linkPassword : undefined);

  return (
    <ChatRoom
      roomId={roomId}
      isCreator={isCreator}
      initialPassword={resolvedPassword}
    />
  );
}

export default function EmbedRoomClient(props: EmbedRoomClientProps) {
  return <ClientOnly><EmbedRoomClientContent {...props} /></ClientOnly>;
}
