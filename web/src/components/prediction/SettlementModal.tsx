'use client';

import { motion, AnimatePresence } from 'framer-motion';
import type { SettlementResult } from '@/types/prediction';

interface SettlementModalProps {
  result: SettlementResult;
  onClose: () => void;
}

export default function SettlementModal({ result, onClose }: SettlementModalProps) {
  const { won, betAmount, odds, payout, balanceChange } = result;

  return (
    <AnimatePresence>
      <motion.div
        className="fixed inset-0 z-50 flex items-center justify-center bg-void-black/80 backdrop-blur-sm"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
      >
        <motion.div
          className="bg-void-black border border-ghost-grey/20 rounded-2xl p-6 max-w-sm w-full mx-4 space-y-4 text-center"
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ type: 'spring', damping: 20, stiffness: 300 }}
        >
          {/* Result emoji */}
          <div className="text-5xl">
            {won ? '🎯' : '💥'}
          </div>

          {/* Title */}
          <h2 className={`text-2xl font-mono font-bold ${won ? 'text-signal-green' : 'text-glitch-red'}`}>
            {won ? 'WIN' : 'LOSE'}
          </h2>

          {/* Details */}
          <div className="space-y-2 text-sm font-mono">
            <div className="flex justify-between text-ghost-grey">
              <span>BET</span>
              <span>{betAmount} BP</span>
            </div>
            <div className="flex justify-between text-ghost-grey">
              <span>ODDS</span>
              <span>{odds.toFixed(2)}x</span>
            </div>
            <div className={`flex justify-between font-bold text-lg ${won ? 'text-signal-green' : 'text-glitch-red'}`}>
              <span>RESULT</span>
              <span>{balanceChange > 0 ? '+' : ''}{balanceChange} BP</span>
            </div>
          </div>

          {/* Close button */}
          <motion.button
            onClick={onClose}
            className="w-full py-3 rounded-lg font-mono font-bold bg-signal-green text-void-black hover:bg-signal-green/90 transition-colors"
          >
            OK
          </motion.button>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
