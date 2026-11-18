'use client';
import ClientOnly from '@/components/shared/ClientOnly';
import { readInvitation } from '@/lib/room/invitation';
import Link from 'next/link';

import { useState, useEffect, useCallback } from 'react';
import { getGroupRoomStatus, verifyGroupPassword } from '@/lib/group/actions';
import { saveRoom, saveRoomPassword, saveAdminToken } from '@/lib/room/storage';
import GroupChatRoom from '@/components/group/GroupChatRoom';
import GroupCreatedView from '@/components/group/GroupCreatedView';
import PasswordEntry from '@/components/chat/PasswordEntry';
import RoomDestroyedOverlay from '@/components/chat/RoomDestroyedOverlay';
import { ThemeToggle } from '@/components/ThemeToggle';

interface GroupRoomClientProps {
  roomId: string;
}

function GroupRoomClientContent({ roomId }: GroupRoomClientProps) {
  const [roomExists, setRoomExists] = useState<boolean | null>(null);
  const [roomError, setRoomError] = useState<string | null>(null);
  const [roomTitle, setRoomTitle] = useState<string>('');
  const [invitation] = useState(() => readInvitation(window.location.href));
  const creatorPassword = invitation.creator;
  const [linkPassword, setLinkPassword] = useState(invitation.creator ? undefined : invitation.password);
  const hashParsed = true;
  const adminToken = invitation.admin;
  const [linkVerified, setLinkVerified] = useState(false);
  const [enteredChat, setEnteredChat] = useState(false);
  useEffect(() => {
    if (window.location.hash || /[?&][kp]=/.test(window.location.search)) {
      window.history.replaceState(null, '', window.location.pathname);
    }
  }, []);

  // 링크 자동 검증
  useEffect(() => {
    if (!hashParsed || !linkPassword) return;
    async function autoVerify() {
      const result = await verifyGroupPassword(roomId, linkPassword!);
      if (result.valid) {
        const hasAdmin = !!adminToken;
        saveRoom({
          roomId,
          roomType: 'group',
          isCreator: false,
          isAdmin: hasAdmin,
          createdAt: Date.now(),
          lastAccessedAt: Date.now(),
          status: 'active',
        });
        saveRoomPassword(roomId, linkPassword!);
        if (hasAdmin) saveAdminToken(roomId, adminToken!);
        setLinkVerified(true);
        setRoomExists(true);
      } else {
        setRoomError(result.error ?? 'INVALID_PASSWORD');
        setRoomExists(false);
        setLinkPassword(undefined);
      }
    }
    autoVerify();
  }, [hashParsed, linkPassword, adminToken, roomId]);

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
        <Link
          href="/"
          className="min-h-[48px] flex items-center px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider"
        >
          GO HOME
        </Link>
      </div>
    );
  }

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

export default function GroupRoomClient(props: GroupRoomClientProps) {
  return <ClientOnly><GroupRoomClientContent {...props} /></ClientOnly>;
}
