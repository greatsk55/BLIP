'use client';

import { useState, useEffect, useCallback } from 'react';
import { getGroupRoomStatus, verifyGroupPassword } from '@/lib/group/actions';
import GroupChatRoom from '@/components/group/GroupChatRoom';
import GroupCreatedView from '@/components/group/GroupCreatedView';
import PasswordEntry from '@/components/chat/PasswordEntry';
import RoomDestroyedOverlay from '@/components/chat/RoomDestroyedOverlay';
import { ThemeToggle } from '@/components/ThemeToggle';

interface GroupRoomClientProps {
  roomId: string;
}

export default function GroupRoomClient({ roomId }: GroupRoomClientProps) {
  const [roomExists, setRoomExists] = useState<boolean | null>(null);
  const [roomError, setRoomError] = useState<string | null>(null);
  const [roomTitle, setRoomTitle] = useState<string>('');
  const [creatorPassword, setCreatorPassword] = useState<string | undefined>();
  const [adminToken, setAdminToken] = useState<string | undefined>();
  const [linkPassword, setLinkPassword] = useState<string | undefined>();
  const [linkVerified, setLinkVerified] = useState(false);
  const [hashParsed, setHashParsed] = useState(false);

  // URL fragment 파싱
  useEffect(() => {
    let p: string | null = null;
    let k: string | null = null;
    let a: string | null = null;

    const hash = window.location.hash;
    if (hash) {
      const hashParams = new URLSearchParams(hash.slice(1));
      p = hashParams.get('p');
      k = hashParams.get('k');
      a = hashParams.get('a');
    }

    if (!p && !k) {
      const searchParams = new URLSearchParams(window.location.search);
      p = searchParams.get('p');
      k = searchParams.get('k');
      a = searchParams.get('a');
    }

    if (p) {
      setCreatorPassword(decodeURIComponent(p));
      if (a) setAdminToken(decodeURIComponent(a));
    } else if (k) {
      setLinkPassword(decodeURIComponent(k));
    }

    if (hash || window.location.search.includes('k=') || window.location.search.includes('p=')) {
      window.history.replaceState(null, '', window.location.pathname);
    }
    setHashParsed(true);
  }, []);

  // 링크 자동 검증
  useEffect(() => {
    if (!hashParsed || !linkPassword) return;
    async function autoVerify() {
      const result = await verifyGroupPassword(roomId, linkPassword!);
      if (result.valid) {
        setLinkVerified(true);
        setRoomExists(true);
      } else {
        setRoomError(result.error ?? 'INVALID_PASSWORD');
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
      const result = await getGroupRoomStatus(roomId);
      if (!result.exists) {
        setRoomError(result.error || 'ROOM_NOT_FOUND');
        setRoomExists(false);
      } else if (result.status === 'destroyed') {
        setRoomError('ROOM_DESTROYED');
        setRoomExists(false);
      } else if (result.status === 'expired') {
        setRoomError('ROOM_EXPIRED');
        setRoomExists(false);
      } else {
        setRoomExists(true);
        if (result.title) setRoomTitle(result.title);
      }
    }
    checkRoom();
  }, [roomId, hashParsed, linkPassword]);

  const handlePasswordSubmit = useCallback(async (inputPassword: string) => {
    const result = await verifyGroupPassword(roomId, inputPassword);
    if (result.valid) {
      setLinkPassword(inputPassword);
      setLinkVerified(true);
      setRoomExists(true);
    } else {
      throw new Error(result.error ?? 'INVALID_PASSWORD');
    }
  }, [roomId]);

  const floatingToggle = (
    <div className="fixed top-4 right-4 z-50 pt-[env(safe-area-inset-top)]">
      <ThemeToggle />
    </div>
  );

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
          This group no longer exists.
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

  const [enteredChat, setEnteredChat] = useState(false);

  const isCreator = !!creatorPassword;
  const resolvedPassword = creatorPassword ?? (linkVerified ? linkPassword : undefined);

  if (!resolvedPassword) {
    return (
      <>
        {floatingToggle}
        <PasswordEntry
          onSubmit={handlePasswordSubmit}
          error={null}
          loading={false}
        />
      </>
    );
  }

  if (isCreator && adminToken && !enteredChat) {
    return (
      <>
        {floatingToggle}
        <GroupCreatedView
          roomId={roomId}
          password={resolvedPassword}
          adminToken={adminToken}
          title={roomTitle}
          onEnter={() => setEnteredChat(true)}
        />
      </>
    );
  }

  return (
    <>
      {floatingToggle}
      <GroupChatRoom
        roomId={roomId}
        password={resolvedPassword}
        isAdmin={!!adminToken}
        adminToken={adminToken}
        title={roomTitle}
      />
    </>
  );
}
