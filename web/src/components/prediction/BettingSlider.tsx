'use client';

import { motion } from 'framer-motion';
import { MIN_BET } from '@/lib/prediction/constants';

interface BettingSliderProps {
  amount: number;
  maxBet: number;
  odds: number;
  onChange: (amount: number) => void;
}

export default function BettingSlider({ amount, maxBet, odds, onChange }: BettingSliderProps) {
  const expectedPayout = Math.floor(amount * odds);
  const poolAmount = Math.floor(amount * 0.9);

  return (
    <motion.div
      className="flex flex-col gap-2 w-full"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
    >
      <div className="flex justify-between items-center">
        <span className="font-mono text-sm text-ghost-grey">{amount} BP</span>
        <span className="font-mono text-sm text-signal-green">+{expectedPayout} BP</span>
      </div>
      <input
        type="range"
        role="slider"
        min={MIN_BET}
        max={maxBet}
        value={amount}
        onChange={(e) => onChange(Number(e.target.value))}
        className="w-full accent-signal-green cursor-pointer"
      />
      <div className="flex items-center gap-1.5 mt-1 px-1">
        <span className="text-orange-400 text-xs">⚠</span>
        <span className="font-mono text-xs text-orange-400/80">
          10% fee — {amount} BP vote → {poolAmount} BP in pool. Non-refundable.
        </span>
      </div>
    </motion.div>
  );
}
