'use client';

import { motion } from 'framer-motion';
import { RANK_THRESHOLDS } from '@/lib/prediction/constants';
import type { Rank } from '@/types/prediction';

interface RankBadgeProps {
  rank: Rank;
  size?: 'sm' | 'md';
}

const COLOR_CLASS: Record<string, string> = {
  grey: 'bg-ghost-grey/20 text-ghost-grey border-ghost-grey/30',
  green: 'bg-signal-green/20 text-signal-green border-signal-green/30',
  blue: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  orange: 'bg-orange-500/20 text-orange-400 border-orange-500/30',
  purple: 'bg-purple-500/20 text-purple-400 border-purple-500/30',
  gold: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
};

export default function RankBadge({ rank, size = 'sm' }: RankBadgeProps) {
  const threshold = RANK_THRESHOLDS.find((t) => t.name === rank) ?? RANK_THRESHOLDS[0];
  const colorClass = COLOR_CLASS[threshold.color] ?? COLOR_CLASS.grey;
  const sizeClass = size === 'sm' ? 'text-xs px-2 py-0.5' : 'text-sm px-3 py-1';

  return (
    <motion.span
      className={`inline-flex items-center gap-1 rounded-full border font-mono ${colorClass} ${sizeClass} ${threshold.color}`}
      initial={{ scale: 0.9, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
    >
      <span>{threshold.emoji}</span>
      <span>{threshold.name}</span>
    </motion.span>
  );
}
