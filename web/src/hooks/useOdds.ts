'use client';

import { useState } from 'react';
import type { BetOdds } from '@/types/prediction';

/**
 * 배당률 실시간 구독 Hook
 * Supabase Broadcast 채널로 odds 업데이트 수신
 */
export function useOdds(predictionId: string | null) {
  const [odds, setOdds] = useState<BetOdds | null>(null);

  // TODO: Supabase Broadcast 구독 (useChat.ts 패턴 참조)
  // predictionId가 null이면 구독하지 않음

  return { odds, setOdds };
}
