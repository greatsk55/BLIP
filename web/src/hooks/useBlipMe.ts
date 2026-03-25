'use client';

import { useEffect, useRef, useCallback, useState } from 'react';
import { supabase } from '@/lib/supabase/client';
import {
  getOwnerToken,
  saveOwnerToken,
  getCachedLinkId,
  saveLinkId,
  removeLinkId,
} from '@/lib/blipme/storage';
import { generateOwnerToken, hashOwnerToken } from '@/lib/blipme/utils';
import {
  createBlipMeLink,
  getMyBlipMeLink,
  deleteBlipMeLink,
  regenerateBlipMeLink,
  registerBlipMeWebPush,
} from '@/lib/blipme/actions';

export interface IncomingConnection {
  roomId: string;
  password: string;
  timestamp: number;
}

interface UseBlipMeReturn {
  /** 현재 활성 링크 ID */
  linkId: string | null;
  /** 로딩 중 여부 */
  loading: boolean;
  /** 에러 메시지 */
  error: string | null;
  /** 총 사용 횟수 */
  useCount: number;
  /** 링크 생성 */
  createLink: () => Promise<void>;
  /** 링크 삭제 */
  deleteLink: () => Promise<void>;
  /** 링크 재생성 (URL 변경) */
  regenerateLink: () => Promise<void>;
  /** 수신된 연결 요청 */
  incomingConnection: IncomingConnection | null;
  /** 연결 알림 초기화 */
  clearIncoming: () => void;
  /** Realtime 리스닝 활성 여부 */
  listening: boolean;
  /** 웹 푸시 구독 상태 */
  webPushEnabled: boolean;
}

/** Service Worker 등록 + Web Push 구독 */
async function subscribeWebPush(
  linkId: string,
  ownerTokenHash: string
): Promise<boolean> {
  try {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) return false;

    const vapidPublicKey = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY;
    if (!vapidPublicKey) return false;

    // Service Worker 등록 (BLIP me 전용)
    const registration = await navigator.serviceWorker.register('/sw-blipme.js');
    await navigator.serviceWorker.ready;

    // 알림 권한 요청
    const permission = await Notification.requestPermission();
    if (permission !== 'granted') return false;

    // 기존 구독 확인
    let subscription = await registration.pushManager.getSubscription();
    if (!subscription) {
      // VAPID 공개키를 Uint8Array로 변환
      const urlBase64ToUint8Array = (base64String: string) => {
        const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
        const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
        const rawData = window.atob(base64);
        return Uint8Array.from(rawData, (char) => char.charCodeAt(0));
      };

      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
      });
    }

    // 서버에 구독 정보 등록
    const result = await registerBlipMeWebPush(
      linkId,
      ownerTokenHash,
      JSON.stringify(subscription.toJSON()),
    );
    return result.success;
  } catch (e) {
    console.error('[WebPush] Subscribe failed:', e);
    return false;
  }
}

/**
 * BLIP me 관리 훅
 * - ownerToken 자동 초기화
 * - 링크 CRUD
 * - Supabase Realtime으로 방문자 연결 알림 수신
 * - Web Push 구독 (브라우저 백그라운드 알림)
 */
export function useBlipMe(): UseBlipMeReturn {
  const [linkId, setLinkId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [useCount, setUseCount] = useState(0);
  const [incomingConnection, setIncomingConnection] = useState<IncomingConnection | null>(null);
  const [listening, setListening] = useState(false);
  const [webPushEnabled, setWebPushEnabled] = useState(false);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const ownerTokenHashRef = useRef<string | null>(null);

  // ownerToken 초기화 + 기존 링크 조회
  useEffect(() => {
    let cancelled = false;

    async function init() {
      let token = getOwnerToken();
      if (!token) {
        setLoading(false);
        return;
      }

      const tokenHash = await hashOwnerToken(token);
      ownerTokenHashRef.current = tokenHash;

      const existing = await getMyBlipMeLink(tokenHash);
      if (!cancelled && existing) {
        setLinkId(existing.linkId);
        setUseCount(existing.useCount);
        saveLinkId(existing.linkId);
        // 웹 푸시 자동 재등록
        subscribeWebPush(existing.linkId, tokenHash).then((ok) => {
          if (!cancelled) setWebPushEnabled(ok);
        });
      } else if (!cancelled) {
        removeLinkId();
      }

      if (!cancelled) setLoading(false);
    }

    init();
    return () => { cancelled = true; };
  }, []);

  // Realtime 구독: 링크가 있을 때만
  useEffect(() => {
    if (!linkId) {
      setListening(false);
      return;
    }

    const channel = supabase.channel(`blipme:${linkId}`);
    channelRef.current = channel;

    channel
      .on('broadcast', { event: 'incoming' }, (payload) => {
        const data = payload.payload as IncomingConnection;
        setIncomingConnection(data);
        setUseCount((prev) => prev + 1);
      })
      .subscribe((status) => {
        setListening(status === 'SUBSCRIBED');
      });

    return () => {
      supabase.removeChannel(channel);
      channelRef.current = null;
      setListening(false);
    };
  }, [linkId]);

  const ensureOwnerToken = useCallback(async (): Promise<string> => {
    if (ownerTokenHashRef.current) return ownerTokenHashRef.current;

    let token = getOwnerToken();
    if (!token) {
      token = generateOwnerToken();
      saveOwnerToken(token);
    }
    const hash = await hashOwnerToken(token);
    ownerTokenHashRef.current = hash;
    return hash;
  }, []);

  const createLink = useCallback(async () => {
    setError(null);
    setLoading(true);
    try {
      const tokenHash = await ensureOwnerToken();
      const result = await createBlipMeLink(tokenHash);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      setLinkId(result.linkId);
      setUseCount(0);
      saveLinkId(result.linkId);
      // 웹 푸시 구독
      const ok = await subscribeWebPush(result.linkId, tokenHash);
      setWebPushEnabled(ok);
    } finally {
      setLoading(false);
    }
  }, [ensureOwnerToken]);

  const deleteLink = useCallback(async () => {
    if (!linkId || !ownerTokenHashRef.current) return;
    setError(null);
    setLoading(true);
    try {
      const result = await deleteBlipMeLink(linkId, ownerTokenHashRef.current);
      if (!result.success) {
        setError(result.error ?? 'DELETE_FAILED');
        return;
      }
      setLinkId(null);
      setUseCount(0);
      setWebPushEnabled(false);
      removeLinkId();
    } finally {
      setLoading(false);
    }
  }, [linkId]);

  const regenerateLink = useCallback(async () => {
    if (!linkId || !ownerTokenHashRef.current) return;
    setError(null);
    setLoading(true);
    try {
      const result = await regenerateBlipMeLink(linkId, ownerTokenHashRef.current);
      if ('error' in result) {
        setError(result.error);
        return;
      }
      setLinkId(result.linkId);
      setUseCount(0);
      saveLinkId(result.linkId);
      // 새 링크에 웹 푸시 재등록
      const ok = await subscribeWebPush(result.linkId, ownerTokenHashRef.current!);
      setWebPushEnabled(ok);
    } finally {
      setLoading(false);
    }
  }, [linkId]);

  const clearIncoming = useCallback(() => {
    setIncomingConnection(null);
  }, []);

  return {
    linkId,
    loading,
    error,
    useCount,
    createLink,
    deleteLink,
    regenerateLink,
    incomingConnection,
    clearIncoming,
    listening,
    webPushEnabled,
  };
}
