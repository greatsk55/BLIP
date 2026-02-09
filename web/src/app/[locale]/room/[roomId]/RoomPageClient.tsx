'use client';

import { useState, useEffect } from 'react';
import { getRoomStatus } from '@/lib/room/actions';
import ChatRoom from '@/components/chat/ChatRoom';
import { ThemeToggle } from '@/components/ThemeToggle';

interface RoomPageClientProps {
  roomId: string;
}

export default function RoomPageClient({ roomId }: RoomPageClientProps) {
  const [roomExists, setRoomExists] = useState<boolean | null>(null);
  const [roomError, setRoomError] = useState<string | null>(null);

  // URL fragment에서 비밀번호 추출 (#p=XXXX-XXXX)
  // fragment는 서버로 전송되지 않으므로 서버 로그에 남지 않음
  const [creatorPassword, setCreatorPassword] = useState<string | undefined>(undefined);
  const [hashParsed, setHashParsed] = useState(false);

  useEffect(() => {
    const hash = window.location.hash;
    if (hash) {
      const params = new URLSearchParams(hash.slice(1));
      const p = params.get('p');
      if (p) {
        setCreatorPassword(decodeURIComponent(p));
        // fragment 즉시 제거 (브라우저 히스토리에서도 숨김)
        window.history.replaceState(null, '', window.location.pathname);
      }
    }
    setHashParsed(true);
  }, []);

  useEffect(() => {
    if (!hashParsed) return;
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
  }, [roomId, hashParsed]);

  const floatingToggle = (
    <div className="fixed top-4 right-4 z-50 pt-[env(safe-area-inset-top)]">
      <ThemeToggle />
    </div>
  );

  if (roomExists === null) {
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
        <a
          href="/"
          className="min-h-[48px] flex items-center px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider"
        >
          GO HOME
        </a>
      </div>
    );
  }

  const isCreator = !!creatorPassword;

  return (
    <>
      {floatingToggle}
      <ChatRoom
        roomId={roomId}
        isCreator={isCreator}
        initialPassword={creatorPassword}
      />
    </>
  );
}
