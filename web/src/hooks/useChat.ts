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
  deriveKeysFromPassword,
  hashAuthKey,
} from '@/lib/crypto';
import { generateUsername } from '@/lib/username';
import { updateParticipantCount } from '@/lib/room/actions';
import type {
  DecryptedMessage,
  ChatStatus,
  KeyPair,
  EncryptedPayload,
} from '@/types/chat';

/** crypto.randomUUID() 폴백 — SSR/구형 브라우저 대응 */
function generateUUID(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  // crypto.getRandomValues 기반 v4 UUID
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/**
 * 화면에 유지할 최대 메시지 수.
 * 맥락이 보이지 않도록 최근 N개만 남기고 오래된 메시지를 파쇄한다.
 */
const MAX_VISIBLE_MESSAGES = 4;

/**
 * Presence leave 후 방 파쇄까지 대기 시간 (ms).
 * 모바일 앱이 사진 선택 등으로 일시적으로 백그라운드 전환 시
 * WebSocket이 끊겨 presence leave가 발생하지만, 복귀하면 재접속됨.
 * 이 grace period 내에 peer가 복귀하면 파쇄를 취소한다.
 */
const PRESENCE_LEAVE_GRACE_MS = 60_000;

/** 메시지 배열을 MAX_VISIBLE_MESSAGES 이하로 유지하며, 제거되는 미디어 blob URL 해제 */
function limitMessages(messages: DecryptedMessage[]): DecryptedMessage[] {
  if (messages.length <= MAX_VISIBLE_MESSAGES) return messages;
  const removed = messages.slice(0, messages.length - MAX_VISIBLE_MESSAGES);
  removed.forEach((m) => {
    if (m.mediaUrl) URL.revokeObjectURL(m.mediaUrl);
    if (m.mediaThumbnail) URL.revokeObjectURL(m.mediaThumbnail);
  });
  return messages.slice(-MAX_VISIBLE_MESSAGES);
}

interface PresenceUser {
  userId: string;
  username: string;
  publicKey?: string;
  joinedAt?: number;
}

interface UseChatOptions {
  roomId: string;
  password: string;
  onMessageReceived?: (senderName: string) => void;
}

export type WebRTCSignalingHandlers = {
  onOffer: (raw: Record<string, unknown>) => void;
  onAnswer: (raw: Record<string, unknown>) => void;
  onIce: (raw: Record<string, unknown>) => void;
};

interface UseChatReturn {
  messages: DecryptedMessage[];
  status: ChatStatus;
  myUsername: string;
  peerUsername: string | null;
  peerConnected: boolean;
  sendMessage: (content: string) => void;
  addMediaMessage: (message: DecryptedMessage) => void;
  updateTransferProgress: (transferId: string, progress: number) => void;
  disconnect: () => void;
  // WebRTC 연결에 필요한 값 노출 (ChatRoom에서 useWebRTC 조합용)
  channel: ReturnType<typeof supabase.channel> | null;
  sharedSecret: Uint8Array | null;
  isInitiator: boolean;
  myId: string;
  /** useWebRTC가 시그널링 콜백을 등록하는 setter */
  setWebrtcHandlers: (handlers: WebRTCSignalingHandlers | null) => void;
}

export function useChat({ roomId, password, onMessageReceived }: UseChatOptions): UseChatReturn {
  const [messages, setMessages] = useState<DecryptedMessage[]>([]);
  const [status, setStatus] = useState<ChatStatus>('connecting');
  const [peerUsername, setPeerUsername] = useState<string | null>(null);
  const [peerConnected, setPeerConnected] = useState(false);
  const [sharedSecretState, setSharedSecretState] = useState<Uint8Array | null>(null);
  const [isInitiator, setIsInitiator] = useState(false);
  const [channelState, setChannelState] = useState<ReturnType<typeof supabase.channel> | null>(null);

  const keyPairRef = useRef<KeyPair | null>(null);
  const sharedSecretRef = useRef<Uint8Array | null>(null);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const myUsernameRef = useRef(generateUsername());
  const myIdRef = useRef(generateUUID());
  const selfTrackedRef = useRef(false);
  const authKeyHashRef = useRef<string | null>(null);
  const onMessageReceivedRef = useRef(onMessageReceived);
  onMessageReceivedRef.current = onMessageReceived;

  // Presence leave grace period 타이머 (모바일 백그라운드 전환 허용)
  const peerLeaveTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const clearPeerLeaveTimer = useCallback(() => {
    if (peerLeaveTimerRef.current) {
      clearTimeout(peerLeaveTimerRef.current);
      peerLeaveTimerRef.current = null;
    }
  }, []);

  // WebRTC 시그널링 포워딩 — subscribe 전에 등록, ref 콜백으로 useWebRTC에 전달
  const webrtcHandlersRef = useRef<WebRTCSignalingHandlers | null>(null);
  const setWebrtcHandlers = useCallback((handlers: WebRTCSignalingHandlers | null) => {
    webrtcHandlersRef.current = handlers;
  }, []);

  const sendMessage = useCallback(
    (content: string) => {
      if (!channelRef.current || !sharedSecretRef.current || !content.trim()) return;

      const encrypted = encryptMessage(content.trim(), sharedSecretRef.current);
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

      // 내 메시지는 바로 표시 (최대 N개 유지)
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

  // 미디어 메시지 추가 (useWebRTC에서 호출)
  const addMediaMessage = useCallback((message: DecryptedMessage) => {
    setMessages((prev) => limitMessages([...prev, message]));
  }, []);

  // 전송 진행률 업데이트 (useWebRTC에서 호출)
  const updateTransferProgress = useCallback((transferId: string, progress: number) => {
    setMessages((prev) =>
      prev.map((msg) =>
        msg.id === transferId ? { ...msg, transferProgress: progress } : msg
      )
    );
  }, []);

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
      channelRef.current = null;
      setChannelState(null);
    }

    // 인메모리 미디어 blob URL 해제
    setMessages((prev) => {
      prev.forEach((msg) => {
        if (msg.mediaUrl) URL.revokeObjectURL(msg.mediaUrl);
        if (msg.mediaThumbnail) URL.revokeObjectURL(msg.mediaThumbnail);
      });
      return [];
    });

    keyPairRef.current = null;
    sharedSecretRef.current = null;
    selfTrackedRef.current = false;
    setSharedSecretState(null);
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
        // 방 인증용 authKeyHash 파생 (API 호출 인증에 사용)
        const { authKey } = await deriveKeysFromPassword(password, roomId);
        if (!isMounted) return;
        const authHash = await hashAuthKey(authKey);
        authKeyHashRef.current = authHash;

        // ECDH 키쌍 생성 (랜덤)
        // 양쪽 모두 같은 비밀번호를 사용하므로 seed 기반이 아닌
        // 랜덤 키쌍으로 Perfect Forward Secrecy 보장
        const keyPair = generateKeyPair();
        keyPairRef.current = keyPair;

        // StrictMode double-invocation 방어 — cleanup이 이미 실행됐으면 중단
        if (!isMounted) return;

        // 3. Supabase 채널 구독
        const channel = supabase.channel(`room:${roomId}`, {
          config: { broadcast: { self: false } },
        });

        channelRef.current = channel;
        setChannelState(channel);

        // 4. 공개키 교환 수신
        channel.on('broadcast', { event: 'key_exchange' }, (raw) => {
          if (!isMounted || !keyPairRef.current) return;

          // 이미 키 교환 완료 → 3번째 사용자의 key_exchange 무시
          if (sharedSecretRef.current) return;

          const msg = raw?.payload ?? raw;
          if (!msg?.publicKey) return;

          const peerPublicKey = stringToPublicKey(msg.publicKey);
          const shared = computeSharedSecret(peerPublicKey, keyPairRef.current.secretKey);
          sharedSecretRef.current = shared;
          setSharedSecretState(shared);

          // userId 비교로 WebRTC initiator 결정 (양쪽 동일한 결과)
          setIsInitiator(myIdRef.current < msg.userId);

          setPeerUsername(msg.username);
          setPeerConnected(true);
          if (isMounted) setStatus('chatting');

          // 시스템 메시지: 상대방 입장
          setMessages((prev) =>
            limitMessages([
              ...prev,
              {
                id: generateUUID(),
                senderId: 'system',
                senderName: 'SYSTEM',
                content: `${msg.username} CONNECTED`,
                timestamp: Date.now(),
                isMine: false,
                type: 'text',
              },
            ])
          );
        });

        // 5. 암호화된 메시지 수신
        channel.on('broadcast', { event: 'message' }, (raw) => {
          if (!isMounted || !sharedSecretRef.current) return;

          const msg = raw?.payload ?? raw;
          if (!msg?.ciphertext) return;

          const decrypted = decryptMessage(
            { ciphertext: msg.ciphertext, nonce: msg.nonce } as EncryptedPayload,
            sharedSecretRef.current
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

        // 6. 상대방 퇴장 감지 → 즉시 방 폭파 (양쪽 모두 파쇄)
        channel.on('broadcast', { event: 'user_left' }, () => {
          if (!isMounted) return;
          // 명시적 퇴장 → grace period 타이머 취소 (즉시 파쇄)
          clearPeerLeaveTimer();

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
            setChannelState(null);
          }

          // DB 방 파쇄
          if (authKeyHashRef.current) {
            updateParticipantCount(roomId, 0, authKeyHashRef.current).catch(() => {});
          }
          setStatus('destroyed');
        });

        // 7. Presence로 접속자 추적 + DB 상태 동기화
        channel.on('presence', { event: 'sync' }, () => {
          if (!isMounted) return;
          // track() 완료 전 초기 sync(0명)에서 방 파쇄 방지
          if (!selfTrackedRef.current) return;
          const state = channel.presenceState();
          const users = Object.values(state).flat();
          const peer = users.find(
            (u) => (u as unknown as PresenceUser).userId !== myIdRef.current
          ) as unknown as PresenceUser | undefined;

          // DB participant_count + status 업데이트
          if (authKeyHashRef.current) {
            updateParticipantCount(roomId, users.length, authKeyHashRef.current).catch(() => {});
          }

          // 3명 이상 → 후발 참여자 자동 퇴장
          if (users.length > 2) {
            // 가장 늦게 들어온 사용자가 자신이면 퇴장
            const sorted = [...users].sort(
              (a, b) => ((a as unknown as PresenceUser).joinedAt ?? 0) - ((b as unknown as PresenceUser).joinedAt ?? 0)
            );
            const latestUser = sorted[sorted.length - 1] as unknown as PresenceUser | undefined;
            if (latestUser?.userId === myIdRef.current) {
              channel.untrack();
              channel.unsubscribe();
              channelRef.current = null;
              setChannelState(null);
              keyPairRef.current = null;
              sharedSecretRef.current = null;
              if (isMounted) setStatus('room_full');
              return;
            }
          }

          if (peer) {
            // 상대방 복귀 감지 → presence leave grace period 타이머 취소
            clearPeerLeaveTimer();
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
              setSharedSecretState(shared);
              setIsInitiator(myIdRef.current < peer.userId);
              if (isMounted) setStatus('chatting');
            }
          }
        });

        // presence.leave: 네트워크 끊김 등 user_left 브로드캐스트 못 받았을 때 fallback
        // 모바일 앱이 사진 선택 등으로 일시적 백그라운드 전환 시 WebSocket이 끊겨
        // presence leave가 발생하므로, grace period를 두어 복귀를 기다린다.
        channel.on('presence', { event: 'leave' }, () => {
          if (!isMounted || !selfTrackedRef.current) return;
          const state = channel.presenceState();
          const users = Object.values(state).flat();

          if (authKeyHashRef.current) {
            updateParticipantCount(roomId, users.length, authKeyHashRef.current).catch(() => {});
          }

          // 혼자 남음 + 이전에 상대방이 있었던 경우
          // → grace period 후 파쇄 (모바일 사진 선택 등 일시적 이탈 허용)
          if (users.length <= 1 && sharedSecretRef.current) {
            clearPeerLeaveTimer();
            peerLeaveTimerRef.current = setTimeout(() => {
              if (!isMounted) return;

              // Grace period 후 presence 재확인 — 이미 복귀했을 수 있음
              if (channelRef.current) {
                const currentState = channelRef.current.presenceState();
                const currentUsers = Object.values(currentState).flat();
                if (currentUsers.length > 1) return; // peer 복귀 → 파쇄 취소
              }

              setMessages([]);
              setPeerConnected(false);
              setPeerUsername(null);
              sharedSecretRef.current = null;
              keyPairRef.current = null;

              if (channelRef.current) {
                channelRef.current.untrack();
                channelRef.current.unsubscribe();
                channelRef.current = null;
                setChannelState(null);
              }

              if (authKeyHashRef.current) {
                updateParticipantCount(roomId, 0, authKeyHashRef.current).catch(() => {});
              }
              peerLeaveTimerRef.current = null;
              setStatus('destroyed');
            }, PRESENCE_LEAVE_GRACE_MS);
          }
        });

        // 8. WebRTC 시그널링 이벤트 (subscribe 전에 등록해야 수신 가능)
        channel.on('broadcast', { event: 'webrtc_offer' }, (raw) => {
          webrtcHandlersRef.current?.onOffer(raw);
        });
        channel.on('broadcast', { event: 'webrtc_answer' }, (raw) => {
          webrtcHandlersRef.current?.onAnswer(raw);
        });
        channel.on('broadcast', { event: 'webrtc_ice' }, (raw) => {
          webrtcHandlersRef.current?.onIce(raw);
        });

        // 9. 채널 구독 + Presence 등록
        channel.subscribe(async (subscribeStatus) => {
          if (subscribeStatus === 'SUBSCRIBED' && isMounted) {
            // Presence에 자신 등록
            await channel.track({
              userId: myIdRef.current,
              username: myUsernameRef.current,
              publicKey: publicKeyToString(keyPair.publicKey),
              joinedAt: Date.now(),
            });
            selfTrackedRef.current = true;

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
      clearPeerLeaveTimer();
      if (channelRef.current) {
        const ch = channelRef.current;
        channelRef.current = null;
        setChannelState(null);

        // Presence에서 명시적으로 나가기 (상대방에게 즉시 leave 이벤트)
        ch.untrack();

        // 퇴장 알림
        ch.send({
          type: 'broadcast',
          event: 'user_left',
          payload: {
            userId: myIdRef.current,
            username: myUsernameRef.current,
          },
        });
        ch.unsubscribe();
        // Supabase 내부 채널 목록에서도 제거 (StrictMode 좀비 방지)
        supabase.removeChannel(ch);
      }
      // 키 메모리 정리
      keyPairRef.current = null;
      sharedSecretRef.current = null;
      authKeyHashRef.current = null;
      selfTrackedRef.current = false;
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
        [JSON.stringify({ roomId, authKeyHash: authKeyHashRef.current })],
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
        setChannelState(null);
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
    addMediaMessage,
    updateTransferProgress,
    disconnect,
    channel: channelState,
    sharedSecret: sharedSecretState,
    isInitiator,
    myId: myIdRef.current,
    setWebrtcHandlers,
  };
}
