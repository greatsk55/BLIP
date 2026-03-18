'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import { supabase } from '@/lib/supabase/client';
import {
  deriveKeysFromPassword,
  hashAuthKey,
} from '@/lib/crypto';
import { encryptSymmetric, decryptSymmetric } from '@/lib/crypto/symmetric';
import { generateUsername } from '@/lib/username';
import { updateGroupParticipantCount } from '@/lib/group/actions';
import type { DecryptedMessage, ChatStatus } from '@/types/chat';

function generateUUID(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

const MAX_VISIBLE_MESSAGES = 50;

function limitMessages(messages: DecryptedMessage[]): DecryptedMessage[] {
  if (messages.length <= MAX_VISIBLE_MESSAGES) return messages;
  return messages.slice(-MAX_VISIBLE_MESSAGES);
}

export interface GroupPresenceUser {
  userId: string;
  username: string;
  joinedAt?: number;
  isAdmin?: boolean;
}

interface UseGroupChatOptions {
  roomId: string;
  password: string;
  isAdmin: boolean;
  adminToken?: string;
  onMessageReceived?: (senderName: string) => void;
}

interface UseGroupChatReturn {
  messages: DecryptedMessage[];
  status: ChatStatus;
  myUsername: string;
  myId: string;
  participants: GroupPresenceUser[];
  sendMessage: (content: string) => void;
  disconnect: () => void;
  kickUser: (userId: string) => void;
  channel: ReturnType<typeof supabase.channel> | null;
  authKeyHash: string | null;
}

export function useGroupChat({
  roomId,
  password,
  isAdmin,
  adminToken,
  onMessageReceived,
}: UseGroupChatOptions): UseGroupChatReturn {
  const [messages, setMessages] = useState<DecryptedMessage[]>([]);
  const [status, setStatus] = useState<ChatStatus>('connecting');
  const [participants, setParticipants] = useState<GroupPresenceUser[]>([]);
  const [channelState, setChannelState] = useState<ReturnType<typeof supabase.channel> | null>(null);
  const [authKeyHashState, setAuthKeyHashState] = useState<string | null>(null);

  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const myUsernameRef = useRef(generateUsername());
  const myIdRef = useRef(generateUUID());
  const selfTrackedRef = useRef(false);
  const authKeyHashRef = useRef<string | null>(null);
  const sharedKeyRef = useRef<Uint8Array | null>(null);
  const onMessageReceivedRef = useRef(onMessageReceived);
  onMessageReceivedRef.current = onMessageReceived;

  const sendMessage = useCallback(
    (content: string) => {
      if (!channelRef.current || !sharedKeyRef.current || !content.trim()) return;

      const encrypted = encryptSymmetric(content.trim(), sharedKeyRef.current);
      const messageId = generateUUID();

      channelRef.current.send({
        type: 'broadcast',
        event: 'message',
        payload: {
          id: messageId,
          senderId: myIdRef.current,
          senderName: myUsernameRef.current,
          ciphertext: encrypted.ciphertext,
          nonce: encrypted.nonce,
          timestamp: Date.now(),
        },
      });

      setMessages((prev) =>
        limitMessages([
          ...prev,
          {
            id: messageId,
            senderId: myIdRef.current,
            senderName: myUsernameRef.current,
            content: content.trim(),
            timestamp: Date.now(),
            isMine: true,
            type: 'text',
          },
        ])
      );
    },
    []
  );

  const kickUser = useCallback(
    (userId: string) => {
      if (!channelRef.current || !isAdmin) return;
      channelRef.current.send({
        type: 'broadcast',
        event: 'kick_user',
        payload: { userId, adminId: myIdRef.current },
      });
    },
    [isAdmin]
  );

  const disconnect = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.untrack();
      channelRef.current.send({
        type: 'broadcast',
        event: 'user_left',
        payload: {
          userId: myIdRef.current,
          username: myUsernameRef.current,
        },
      });
      channelRef.current.unsubscribe();
      supabase.removeChannel(channelRef.current);
      channelRef.current = null;
      setChannelState(null);
    }
    setMessages([]);
    setStatus('destroyed');
  }, []);

  useEffect(() => {
    if (!password) return;
    if (!globalThis.isSecureContext) {
      setStatus('error');
      return;
    }

    let isMounted = true;

    async function init() {
      try {
        const { authKey, encryptionSeed } = await deriveKeysFromPassword(password, roomId);
        if (!isMounted) return;
        const authHash = await hashAuthKey(authKey);
        authKeyHashRef.current = authHash;
        setAuthKeyHashState(authHash);

        // 그룹채팅은 비밀번호 기반 대칭키로 암호화 (nacl.secretbox)
        sharedKeyRef.current = encryptionSeed;

        const channel = supabase.channel(`group:${roomId}`, {
          config: { broadcast: { self: false } },
        });

        channelRef.current = channel;
        setChannelState(channel);

        // 메시지 수신
        channel.on('broadcast', { event: 'message' }, (raw) => {
          if (!isMounted || !sharedKeyRef.current) return;
          const msg = raw?.payload ?? raw;
          if (!msg?.ciphertext) return;

          const decrypted = decryptSymmetric(
            { ciphertext: msg.ciphertext, nonce: msg.nonce },
            sharedKeyRef.current
          );

          if (decrypted) {
            setMessages((prev) =>
              limitMessages([
                ...prev,
                {
                  id: msg.id,
                  senderId: msg.senderId,
                  senderName: msg.senderName,
                  content: decrypted,
                  timestamp: msg.timestamp,
                  isMine: false,
                  type: 'text',
                },
              ])
            );
            onMessageReceivedRef.current?.(msg.senderName);
          }
        });

        // 유저 퇴장
        channel.on('broadcast', { event: 'user_left' }, (raw) => {
          if (!isMounted) return;
          const msg = raw?.payload ?? raw;
          setMessages((prev) =>
            limitMessages([
              ...prev,
              {
                id: generateUUID(),
                senderId: 'system',
                senderName: 'SYSTEM',
                content: `${msg?.username || 'USER'} LEFT`,
                timestamp: Date.now(),
                isMine: false,
                type: 'text',
              },
            ])
          );
        });

        // 강퇴 수신
        channel.on('broadcast', { event: 'kick_user' }, (raw) => {
          if (!isMounted) return;
          const msg = raw?.payload ?? raw;
          if (msg?.userId === myIdRef.current) {
            // 나를 강퇴
            if (channelRef.current) {
              channelRef.current.untrack();
              channelRef.current.unsubscribe();
              supabase.removeChannel(channelRef.current);
              channelRef.current = null;
              setChannelState(null);
            }
            setStatus('destroyed');
          }
        });

        // 방 폭파
        channel.on('broadcast', { event: 'room_destroyed' }, () => {
          if (!isMounted) return;
          if (channelRef.current) {
            channelRef.current.untrack();
            channelRef.current.unsubscribe();
            supabase.removeChannel(channelRef.current);
            channelRef.current = null;
            setChannelState(null);
          }
          setMessages([]);
          setStatus('destroyed');
        });

        // Presence 동기화
        channel.on('presence', { event: 'sync' }, () => {
          if (!isMounted || !selfTrackedRef.current) return;
          const state = channel.presenceState();
          const users = Object.values(state).flat() as unknown as GroupPresenceUser[];
          setParticipants(users);

          if (authKeyHashRef.current) {
            updateGroupParticipantCount(roomId, users.length, authKeyHashRef.current).catch(() => {});
          }
        });

        channel.on('presence', { event: 'join' }, ({ newPresences }) => {
          if (!isMounted) return;
          const joined = newPresences as unknown as GroupPresenceUser[];
          joined.forEach((u) => {
            if (u.userId !== myIdRef.current) {
              setMessages((prev) =>
                limitMessages([
                  ...prev,
                  {
                    id: generateUUID(),
                    senderId: 'system',
                    senderName: 'SYSTEM',
                    content: `${u.username} JOINED`,
                    timestamp: Date.now(),
                    isMine: false,
                    type: 'text',
                  },
                ])
              );
            }
          });
        });

        channel.on('presence', { event: 'leave' }, ({ leftPresences }) => {
          if (!isMounted || !selfTrackedRef.current) return;
          const state = channel.presenceState();
          const users = Object.values(state).flat();

          if (authKeyHashRef.current) {
            updateGroupParticipantCount(roomId, users.length, authKeyHashRef.current).catch(() => {});
          }

          // 자기 혼자 남으면 방 자동 파쇄
          if (users.length <= 1 && selfTrackedRef.current) {
            // 혼자 남은 경우 30초 후 파쇄 (재접속 여유)
            setTimeout(() => {
              if (!isMounted || !channelRef.current) return;
              const currentState = channelRef.current.presenceState();
              const currentUsers = Object.values(currentState).flat();
              if (currentUsers.length <= 1) {
                if (authKeyHashRef.current) {
                  updateGroupParticipantCount(roomId, 0, authKeyHashRef.current).catch(() => {});
                }
                // 혼자라도 방은 유지 (그룹은 관리자 폭파 또는 24시간 만료)
              }
            }, 30_000);
          }
        });

        channel.subscribe(async (subscribeStatus) => {
          if (subscribeStatus === 'SUBSCRIBED' && isMounted) {
            await channel.track({
              userId: myIdRef.current,
              username: myUsernameRef.current,
              joinedAt: Date.now(),
              isAdmin,
            });
            selfTrackedRef.current = true;
            setStatus('chatting');
          } else if (subscribeStatus === 'TIMED_OUT' || subscribeStatus === 'CHANNEL_ERROR') {
            if (isMounted) setStatus('error');
          }
        });
      } catch {
        if (isMounted) setStatus('error');
      }
    }

    init();

    return () => {
      isMounted = false;
      if (channelRef.current) {
        const ch = channelRef.current;
        channelRef.current = null;
        setChannelState(null);
        ch.untrack();
        ch.send({
          type: 'broadcast',
          event: 'user_left',
          payload: {
            userId: myIdRef.current,
            username: myUsernameRef.current,
          },
        });
        ch.unsubscribe();
        supabase.removeChannel(ch);
      }
      sharedKeyRef.current = null;
      authKeyHashRef.current = null;
      selfTrackedRef.current = false;
    };
  }, [roomId, password, isAdmin]);

  // 페이지 이탈 감지
  useEffect(() => {
    if (!password) return;

    const handlePageLeave = () => {
      const blob = new Blob(
        [JSON.stringify({ roomId, authKeyHash: authKeyHashRef.current, type: 'group' })],
        { type: 'application/json' }
      );
      navigator.sendBeacon('/api/group/leave', blob);

      if (channelRef.current) {
        channelRef.current.untrack();
        channelRef.current.send({
          type: 'broadcast',
          event: 'user_left',
          payload: {
            userId: myIdRef.current,
            username: myUsernameRef.current,
          },
        });
        channelRef.current.unsubscribe();
        channelRef.current = null;
        setChannelState(null);
      }
    };

    window.addEventListener('beforeunload', handlePageLeave);
    window.addEventListener('pagehide', handlePageLeave);

    return () => {
      window.removeEventListener('beforeunload', handlePageLeave);
      window.removeEventListener('pagehide', handlePageLeave);
    };
  }, [roomId, password]);

  return {
    messages,
    status,
    myUsername: myUsernameRef.current,
    myId: myIdRef.current,
    participants,
    sendMessage,
    disconnect,
    kickUser,
    channel: channelState,
    authKeyHash: authKeyHashState,
  };
}
