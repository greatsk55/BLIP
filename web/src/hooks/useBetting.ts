'use client';

import { useState, useMemo } from 'react';
import { MAX_BET_CAP, MAX_BET_PERCENT } from '@/lib/prediction/constants';

export function useBetting(balance: number, odds: number) {
  const [betAmount, setBetAmount] = useState(1);

  const maxBet = useMemo(
    () => Math.min(Math.floor(balance * MAX_BET_PERCENT), MAX_BET_CAP),
    [balance]
  );

  const expectedPayout = useMemo(
    () => Math.floor(betAmount * odds),
    [betAmount, odds]
  );

  return { betAmount, setBetAmount, maxBet, expectedPayout };
}
