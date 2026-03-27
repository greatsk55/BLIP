'use client';

import { motion } from 'framer-motion';
import { getRank } from '@/lib/prediction/rank';
import type { Rank } from '@/types/prediction';
import RankBadge from './RankBadge';

interface PointsDisplayProps {
  balance: number;
}

function formatNumber(n: number): string {
  return n.toLocaleString('en-US');
}

export default function PointsDisplay({ balance }: PointsDisplayProps) {
  const rank = getRank(balance);

  return (
    <motion.div
      className="flex items-center gap-3"
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
    >
      <div className="flex items-baseline gap-1">
        <span className="font-mono text-xl text-ink font-bold">
          {formatNumber(balance)}
        </span>
        <span className="font-mono text-sm text-ghost-grey">BP</span>
      </div>
      <RankBadge rank={rank.name as Rank} />
    </motion.div>
  );
}
