'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import { getRank, getRankBadge, type RankBadge } from '@/lib/prediction/rank';
import type { RankThreshold } from '@/lib/prediction/constants';
import { getDeviceToken, setDeviceToken, getPointsCache, setPointsCache } from '@/lib/prediction/storage';
import { generateDeviceFingerprint, hashFingerprint } from '@/lib/prediction/device';
import { registerDevice, getDevicePoints } from '@/lib/prediction/actions';

export function usePoints() {
  const [balance, setBalance] = useState(() => getPointsCache()?.balance ?? 0);
  const [loading, setLoading] = useState(true);
  const [deviceFingerprint, setDeviceFingerprint] = useState<string | null>(null);

  const rank: RankThreshold = useMemo(() => getRank(balance), [balance]);
  const rankInfo: RankBadge = useMemo(() => getRankBadge(balance), [balance]);

  // 디바이스 등록 + 포인트 조회
  useEffect(() => {
    let cancelled = false;

    async function init() {
      try {
        // 기존 토큰 확인
        let fp = getDeviceToken();

        if (!fp) {
          // 새 fingerprint 생성
          fp = await generateDeviceFingerprint({
            hardwareConcurrency: navigator.hardwareConcurrency,
            screenWidth: screen.width,
            screenHeight: screen.height,
            colorDepth: screen.colorDepth,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            language: navigator.language,
            userAgent: navigator.userAgent,
          });
          setDeviceToken(fp);
        }

        if (cancelled) return;
        setDeviceFingerprint(fp);

        // hardware hash (리셋 방지용)
        const hwHash = await hashFingerprint(
          `${navigator.userAgent}|${screen.width}x${screen.height}|${navigator.hardwareConcurrency}`
        );

        // 서버에 디바이스 등록 (이미 있으면 기존 잔액 반환)
        const result = await registerDevice(fp, hwHash);

        if (cancelled) return;

        if ('error' in result) {
          console.error('Device registration failed:', result.error);
          setLoading(false);
          return;
        }

        setBalance(result.balance);
        setPointsCache({ balance: result.balance });
        setLoading(false);
      } catch (e) {
        console.error('usePoints init error:', e);
        if (!cancelled) setLoading(false);
      }
    }

    init();
    return () => { cancelled = true; };
  }, []);

  // 잔액 새로고침 함수
  const refreshBalance = useCallback(async () => {
    const fp = deviceFingerprint ?? getDeviceToken();
    if (!fp) return;

    const result = await getDevicePoints(fp);
    if ('error' in result) return;

    setBalance(result.balance);
    setPointsCache({ balance: result.balance });
  }, [deviceFingerprint]);

  return {
    balance,
    rank,
    rankInfo,
    loading,
    deviceFingerprint,
    setBalance,
    setLoading,
    refreshBalance,
  };
}
