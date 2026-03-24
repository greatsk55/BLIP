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
}

/**
 * BLIP me 관리 훅
 * - ownerToken 자동 초기화
 * - 링크 CRUD
 * - Supabase Realtime으로 방문자 연결 알림 수신
 */
export function useBlipMe(): UseBlipMeReturn {
  const [linkId, setLinkId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [useCount, setUseCount] = useState(0);
  const [incomingConnection, setIncomingConnection] = useState<IncomingConnection | null>(null);
  const [listening, setListening] = useState(false);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const ownerTokenHashRef = useRef<string | null>(null);

  // ownerToken 초기화 + 기존 링크 조회
  useEffect(() => {
    let cancelled = false;

    async function init() {
      let token = getOwnerToken();
      if (!token) {
        // 아직 ownerToken이 없으면 생성하지 않음 (링크 생성 시 생성)
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
  };
}
