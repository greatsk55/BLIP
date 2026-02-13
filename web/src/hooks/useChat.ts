'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import { supabase } from '@/lib/supabase/client';
import {
  generateKeyPair,
  computeSharedSecret,
  encryptMessage,
  decryptMessage,
  publicKeyToString,
  stringToPublicKey,
} from '@/lib/crypto';
import { generateUsername } from '@/lib/username';
import { updateParticipantCount } from '@/lib/room/actions';
import type {
  DecryptedMessage,
  ChatStatus,
  KeyPair,
  EncryptedPayload,
} from '@/types/chat';

interface UseChatOptions {
  roomId: string;
  password: string;
  onMessageReceived?: (senderName: string) => void;
}

interface UseChatReturn {
  messages: DecryptedMessage[];
  status: ChatStatus;
  myUsername: string;
  peerUsername: string | null;
  peerConnected: boolean;
  sendMessage: (content: string) => void;
  disconnect: () => void;
}

export function useChat({ roomId, password, onMessageReceived }: UseChatOptions): UseChatReturn {
  const [messages, setMessages] = useState<DecryptedMessage[]>([]);
  const [status, setStatus] = useState<ChatStatus>('connecting');
  const [peerUsername, setPeerUsername] = useState<string | null>(null);
  const [peerConnected, setPeerConnected] = useState(false);

  const keyPairRef = useRef<KeyPair | null>(null);
  const sharedSecretRef = useRef<Uint8Array | null>(null);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const myUsernameRef = useRef(generateUsername());
  const myIdRef = useRef(crypto.randomUUID());
  const onMessageReceivedRef = useRef(onMessageReceived);
  onMessageReceivedRef.current = onMessageReceived;

  const sendMessage = useCallback(
    (content: string) => {
      if (!channelRef.current || !sharedSecretRef.current || !content.trim()) return;

      const encrypted = encryptMessage(content.trim(), sharedSecretRef.current);
      const messageId = crypto.randomUUID();

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

      // 내 메시지는 바로 표시
      setMessages((prev) => [
        ...prev,
        {
          id: messageId,
          senderId: myIdRef.current,
          senderName: myUsernameRef.current,
          content: content.trim(),
          timestamp: Date.now(),
          isMine: true,
        },
      ]);
    },
    []
  );

  const disconnect = useCallback(() => {
    if (channelRef.current) {
      // Presence에서 명시적으로 나가기 (상대방에게 즉시 leave 이벤트 전달)
      channelRef.current.untrack();

      // 퇴장 알림 브로드캐스트
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
    }
    // 메모리에서 키 + 메시지 완전 삭제
    keyPairRef.current = null;
    sharedSecretRef.current = null;
    setMessages([]);
    setStatus('destroyed');
  }, []);

  useEffect(() => {
    // 비밀번호가 없으면 연결하지 않음 (참여자가 아직 비밀번호 미입력 상태)
    if (!password) return;

    // Secure Context 필수 — HTTP에서는 E2EE가 MITM에 무력화됨
    if (!globalThis.isSecureContext) {
      setStatus('error');
      return;
    }

    let isMounted = true;

    async function init() {
      try {
        // ECDH 키쌍 생성 (랜덤)
        // 양쪽 모두 같은 비밀번호를 사용하므로 seed 기반이 아닌
        // 랜덤 키쌍으로 Perfect Forward Secrecy 보장
        const keyPair = generateKeyPair();
        keyPairRef.current = keyPair;

        // 3. Supabase 채널 구독
        const channel = supabase.channel(`room:${roomId}`, {
          config: { broadcast: { self: false } },
        });

        channelRef.current = channel;

        // 4. 공개키 교환 수신
        channel.on('broadcast', { event: 'key_exchange' }, (payload) => {
          if (!isMounted || !keyPairRef.current) return;

          // 이미 키 교환 완료 → 3번째 사용자의 key_exchange 무시
          if (sharedSecretRef.current) return;

          const peerPublicKey = stringToPublicKey(payload.payload.publicKey);
          const shared = computeSharedSecret(peerPublicKey, keyPairRef.current.secretKey);
          sharedSecretRef.current = shared;

          setPeerUsername(payload.payload.username);
          setPeerConnected(true);
          if (isMounted) setStatus('chatting');

          // 시스템 메시지: 상대방 입장
          setMessages((prev) => [
            ...prev,
            {
              id: crypto.randomUUID(),
              senderId: 'system',
              senderName: 'SYSTEM',
              content: `${payload.payload.username} CONNECTED`,
              timestamp: Date.now(),
              isMine: false,
            },
          ]);
        });

        // 5. 암호화된 메시지 수신
        channel.on('broadcast', { event: 'message' }, (payload) => {
          if (!isMounted || !sharedSecretRef.current) return;

          const msg = payload.payload;
          const decrypted = decryptMessage(
            { ciphertext: msg.ciphertext, nonce: msg.nonce } as EncryptedPayload,
            sharedSecretRef.current
          );

          if (decrypted) {
            setMessages((prev) => [
              ...prev,
              {
                id: msg.id,
                senderId: msg.senderId,
                senderName: msg.senderName,
                content: decrypted,
                timestamp: msg.timestamp,
                isMine: false,
              },
            ]);
            onMessageReceivedRef.current?.(msg.senderName);
          }
        });

        // 6. 상대방 퇴장 감지 → 즉시 방 폭파 (양쪽 모두 파쇄)
        channel.on('broadcast', { event: 'user_left' }, () => {
          if (!isMounted) return;

          // 메시지 전체 삭제 + 상태 초기화
          setMessages([]);
          setPeerConnected(false);
          setPeerUsername(null);
          sharedSecretRef.current = null;
          keyPairRef.current = null;

          // 채널 정리
          if (channelRef.current) {
            channelRef.current.untrack();
            channelRef.current.unsubscribe();
            channelRef.current = null;
          }

          // DB 방 파쇄
          updateParticipantCount(roomId, 0).catch(() => {});
          setStatus('destroyed');
        });

        // 7. Presence로 접속자 추적 + DB 상태 동기화
        channel.on('presence', { event: 'sync' }, () => {
          if (!isMounted) return;
          const state = channel.presenceState();
          const users = Object.values(state).flat();
          const peer = users.find(
            (u: any) => u.userId !== myIdRef.current
          ) as any;

          // DB participant_count + status 업데이트
          updateParticipantCount(roomId, users.length).catch(() => {});

          // 3명 이상 → 후발 참여자 자동 퇴장
          if (users.length > 2) {
            // 가장 늦게 들어온 사용자가 자신이면 퇴장
            const sorted = [...users].sort(
              (a: any, b: any) => (a.joinedAt ?? 0) - (b.joinedAt ?? 0)
            );
            const latestUser = sorted[sorted.length - 1] as any;
            if (latestUser?.userId === myIdRef.current) {
              channel.untrack();
              channel.unsubscribe();
              channelRef.current = null;
              keyPairRef.current = null;
              sharedSecretRef.current = null;
              if (isMounted) setStatus('room_full');
              return;
            }
          }

          if (peer) {
            setPeerConnected(true);
            setPeerUsername(peer.username);

            // 상대방 공개키로 공유 비밀 계산 (이미 완료된 경우 무시)
            if (peer.publicKey && keyPairRef.current && !sharedSecretRef.current) {
              const peerPublicKey = stringToPublicKey(peer.publicKey);
              const shared = computeSharedSecret(
                peerPublicKey,
                keyPairRef.current.secretKey
              );
              sharedSecretRef.current = shared;
              if (isMounted) setStatus('chatting');
            }
          }
        });

        // presence.leave: 네트워크 끊김 등 user_left 브로드캐스트 못 받았을 때 fallback
        channel.on('presence', { event: 'leave' }, () => {
          if (!isMounted) return;
          const state = channel.presenceState();
          const users = Object.values(state).flat();

          updateParticipantCount(roomId, users.length).catch(() => {});

          // 혼자 남음 + 이전에 상대방이 있었던 경우 → 즉시 폭파
          if (users.length <= 1 && sharedSecretRef.current) {
            setMessages([]);
            setPeerConnected(false);
            setPeerUsername(null);
            sharedSecretRef.current = null;
            keyPairRef.current = null;

            if (channelRef.current) {
              channelRef.current.untrack();
              channelRef.current.unsubscribe();
              channelRef.current = null;
            }

            updateParticipantCount(roomId, 0).catch(() => {});
            setStatus('destroyed');
          }
        });

        // 8. 채널 구독 + Presence 등록
        await channel.subscribe(async (status) => {
          if (status === 'SUBSCRIBED' && isMounted) {
            // Presence에 자신 등록
            await channel.track({
              userId: myIdRef.current,
              username: myUsernameRef.current,
              publicKey: publicKeyToString(keyPair.publicKey),
              joinedAt: Date.now(),
            });

            // 공개키 브로드캐스트 (Presence sync보다 빠른 교환)
            await channel.send({
              type: 'broadcast',
              event: 'key_exchange',
              payload: {
                userId: myIdRef.current,
                username: myUsernameRef.current,
                publicKey: publicKeyToString(keyPair.publicKey),
              },
            });

            setStatus('chatting');
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
        // Presence에서 명시적으로 나가기 (상대방에게 즉시 leave 이벤트)
        channelRef.current.untrack();

        // 퇴장 알림
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
      }
      // 키 메모리 정리
      keyPairRef.current = null;
      sharedSecretRef.current = null;
    };
  }, [roomId, password]);

  // 페이지 이탈 감지 (탭 닫기, 새로고침, 브라우저 종료)
  // React useEffect cleanup은 이 경우 실행이 보장되지 않으므로
  // beforeunload/pagehide 이벤트 + navigator.sendBeacon으로 DB 업데이트
  useEffect(() => {
    if (!password) return;

    const handlePageLeave = () => {
      // 1. sendBeacon으로 DB 업데이트 (페이지 unload 중에도 전송 보장)
      const blob = new Blob(
        [JSON.stringify({ roomId })],
        { type: 'application/json' }
      );
      navigator.sendBeacon('/api/room/leave', blob);

      // 2. 채널 정리 (가능한 만큼 실행)
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
      }
    };

    // beforeunload: 데스크탑 브라우저 탭 닫기/새로고침
    // pagehide: 모바일 브라우저 (iOS Safari 등에서 beforeunload 대신 사용)
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
    peerUsername,
    peerConnected,
    sendMessage,
    disconnect,
  };
}
