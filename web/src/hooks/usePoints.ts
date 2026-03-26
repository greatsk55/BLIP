'use client';

import { useState, useMemo } from 'react';
import { getRank, getRankBadge, type RankBadge } from '@/lib/prediction/rank';
import type { RankThreshold } from '@/lib/prediction/constants';

export function usePoints() {
  const [balance, setBalance] = useState(0);
  const [loading, setLoading] = useState(true);

  const rank: RankThreshold = useMemo(() => getRank(balance), [balance]);
  const rankInfo: RankBadge = useMemo(() => getRankBadge(balance), [balance]);

  return { balance, rank, rankInfo, loading, setBalance, setLoading };
}
