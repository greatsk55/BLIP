'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useBetting } from '@/hooks/useBetting';
import type { Prediction } from '@/types/prediction';
import BettingSlider from './BettingSlider';

interface BettingCardProps {
  prediction: Prediction;
  yesOdds: number;
  noOdds: number;
  balance: number;
  onBet: (option: string, amount: number) => void;
}

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
}

export default function BettingCard({
  prediction,
  yesOdds,
  noOdds,
  balance,
  onBet,
}: BettingCardProps) {
  const [selectedOption, setSelectedOption] = useState<'YES' | 'NO' | null>(null);
  const odds = selectedOption === 'NO' ? noOdds : yesOdds;
  const { betAmount, setBetAmount, maxBet } = useBetting(balance, odds);

  const isDisabled = prediction.status !== 'active';

  const handleBet = (option: 'YES' | 'NO') => {
    if (isDisabled) return;
    if (selectedOption === option) {
      onBet(option.toLowerCase(), betAmount);
      setSelectedOption(null); // 리셋 → 추가 베팅 가능
    } else {
      setSelectedOption(option);
    }
  };

  return (
    <motion.div
      className="rounded-xl border border-ghost-grey/20 bg-void-black p-4 space-y-4"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
    >
      {/* Category */}
      <span className="inline-block text-xs font-mono text-ghost-grey bg-ghost-grey/10 px-2 py-0.5 rounded">
        {prediction.category}
      </span>

      {/* Question */}
      <h3 className="font-sans text-lg text-ink font-semibold">
        {prediction.question}
      </h3>

      {/* Odds */}
      <div className="grid grid-cols-2 gap-3">
        <motion.button
          disabled={isDisabled}
          onClick={() => handleBet('YES')}
          className={`flex flex-col items-center p-3 rounded-lg border font-mono transition-colors
            ${selectedOption === 'YES' ? 'border-signal-green bg-signal-green/10' : 'border-ghost-grey/20'}
            ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'hover:border-signal-green/50'}`}
        >
          <span className="text-sm text-ghost-grey">YES</span>
          <span className="text-lg font-bold text-signal-green">{yesOdds.toFixed(2)}x</span>
        </motion.button>

        <motion.button
          disabled={isDisabled}
          onClick={() => handleBet('NO')}
          className={`flex flex-col items-center p-3 rounded-lg border font-mono transition-colors
            ${selectedOption === 'NO' ? 'border-glitch-red bg-glitch-red/10' : 'border-ghost-grey/20'}
            ${isDisabled ? 'opacity-50 cursor-not-allowed' : 'hover:border-glitch-red/50'}`}
        >
          <span className="text-sm text-ghost-grey">NO</span>
          <span className="text-lg font-bold text-glitch-red">{noOdds.toFixed(2)}x</span>
        </motion.button>
      </div>

      {/* Slider (selected option) */}
      <AnimatePresence>
        {selectedOption && !isDisabled && (
          <BettingSlider
            amount={betAmount}
            maxBet={maxBet}
            odds={odds}
            onChange={setBetAmount}
          />
        )}
      </AnimatePresence>

      {/* 시작일 / 마감일 */}
      <div className="flex items-center justify-between text-xs font-mono text-ghost-grey border-t border-ghost-grey/10 pt-3">
        <span>
          <span className="text-ghost-grey/50 mr-1">START</span>
          {formatDate(prediction.createdAt)}
        </span>
        <span className="text-ghost-grey/30">→</span>
        <span className={prediction.status !== 'active' ? 'text-glitch-red' : ''}>
          <span className="text-ghost-grey/50 mr-1">END</span>
          {formatDate(prediction.closesAt)}
        </span>
      </div>
    </motion.div>
  );
}
