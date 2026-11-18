'use client';
import ClientOnly from '@/components/shared/ClientOnly';
import { readInvitation } from '@/lib/room/invitation';
import Link from 'next/link';

import { useState, useEffect } from 'react';
import { getRoomStatus, verifyPassword } from '@/lib/room/actions';
import { saveRoom, saveRoomPassword } from '@/lib/room/storage';
import ChatRoom from '@/components/chat/ChatRoom';
import { ThemeToggle } from '@/components/ThemeToggle';

interface RoomPageClientProps {
  roomId: string;
}

function RoomPageClientContent({ roomId }: RoomPageClientProps) {
  const [roomExists, setRoomExists] = useState<boolean | null>(null);
  const [roomError, setRoomError] = useState<string | null>(null);

  // URL에서 비밀번호 추출 (fragment 우선, query parameter 폴백)
  // #p= 또는 ?p= → 방 생성자 (RoomCreatedView 표시)
  // #k= 또는 ?k= → 링크로 참여 (자동 검증 후 바로 채팅 입장)
  // fragment(#)는 서버로 전송되지 않아 가장 안전
  // query(?)는 메신저/SNS 공유 시 fragment 유실 대비 폴백
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

  // #k= 링크로 참여한 경우 자동 비밀번호 검증
  // verifyPassword가 방 상태도 확인하므로 별도 getRoomStatus 불필요
  useEffect(() => {
    if (!hashParsed || !linkPassword) return;
    async function autoVerify() {
      const result = await verifyPassword(roomId, linkPassword!);
      if (result.valid) {
        saveRoom({
          roomId,
          roomType: 'chat',
          isCreator: false,
          isAdmin: false,
          createdAt: Date.now(),
          lastAccessedAt: Date.now(),
          status: 'active',
        });
        saveRoomPassword(roomId, linkPassword!);
        setLinkVerified(true);
        setRoomExists(true);
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

  // #p= (생성자) 또는 비밀번호 없이 진입한 경우 방 상태 확인
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
      }
    }
    checkRoom();
  }, [roomId, hashParsed, linkPassword]);

  const floatingToggle = (
    <div className="fixed top-4 right-4 z-50 pt-[env(safe-area-inset-top)]">
      <ThemeToggle />
    </div>
  );

  // 링크 검증 중인 경우 (linkPassword가 있지만 아직 검증 안 됨)
  const linkVerifying = !!linkPassword && !linkVerified && !roomError;

  if (roomExists === null || linkVerifying) {
    return (
      <div className="h-dvh bg-void-black flex items-center justify-center">
        {floatingToggle}
        <span className="font-mono text-xs text-ghost-grey/40 uppercase tracking-widest animate-pulse">
          CONNECTING...
        </span>
      </div>
    );
  }

  if (!roomExists) {
    return (
      <div className="h-dvh bg-void-black flex flex-col items-center justify-center px-6 text-center pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
        {floatingToggle}
        <p className="font-mono text-xs text-glitch-red tracking-[0.3em] sm:tracking-[0.5em] uppercase mb-6">
          {roomError}
        </p>
        <p className="font-mono text-sm text-ghost-grey mb-10">
          This channel no longer exists.
        </p>
        <Link
          href="/"
          className="min-h-[48px] flex items-center px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider"
        >
          GO HOME
        </Link>
      </div>
    );
  }

  // 생성자: #p= 로 진입 → RoomCreatedView 표시
  // 링크 참여자: #k= 로 진입 + 검증 완료 → 바로 채팅 입장
  // 일반 참여자: 비밀번호 없이 진입 → PasswordEntry 표시
  const isCreator = !!creatorPassword;
  const resolvedPassword = creatorPassword ?? (linkVerified ? linkPassword : undefined);

  return (
    <>
      {floatingToggle}
      <ChatRoom
        roomId={roomId}
        isCreator={isCreator}
        initialPassword={resolvedPassword}
      />
    </>
  );
}

export default function RoomPageClient(props: RoomPageClientProps) {
  return <ClientOnly><RoomPageClientContent {...props} /></ClientOnly>;
}
