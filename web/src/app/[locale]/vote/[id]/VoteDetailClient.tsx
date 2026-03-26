'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { ArrowLeft, MessageSquare, Users, Clock } from 'lucide-react';
import { Link } from '@/i18n/navigation';
import BettingCard from '@/components/prediction/BettingCard';
import PointsDisplay from '@/components/prediction/PointsDisplay';
import { usePoints } from '@/hooks/usePoints';
import { useOdds } from '@/hooks/useOdds';
import type { Prediction } from '@/types/prediction';

interface VoteDetailClientProps {
  predictionId: string;
}

export default function VoteDetailClient({ predictionId }: VoteDetailClientProps) {
  const t = useTranslations('Vote');
  const { balance } = usePoints();
  const { odds } = useOdds(predictionId);

  // TODO: Supabase에서 prediction 데이터 조회
  const prediction: Prediction = {
    id: predictionId,
    creatorFingerprint: 'demo',
    question: 'Will Bitcoin break $100k by 2027?',
    category: 'crypto',
    type: 'yes_no',
    options: ['YES', 'NO'],
    correctAnswer: null,
    status: 'active',
    totalPool: 2400,
    createdAt: new Date().toISOString(),
    closesAt: new Date(Date.now() + 86400000 * 3).toISOString(),
    revealsAt: new Date(Date.now() + 86400000 * 4).toISOString(),
    settledAt: null,
  };

  const yesOdds = odds?.['YES'] ?? 1.85;
  const noOdds = odds?.['NO'] ?? 2.10;

  const handleBet = (option: string, amount: number) => {
    // TODO: placeBet server action 연동
    console.log('Bet placed:', option, amount);
  };

  return (
    <div className="min-h-screen bg-void-black text-white">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-void-black/80 backdrop-blur-md border-b border-ghost-grey/10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link href="/vote" className="text-ghost-grey hover:text-ink transition-colors">
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <h1 className="font-mono text-sm font-bold text-ghost-grey uppercase tracking-wider">
              {t('title')}
            </h1>
          </div>
          <PointsDisplay balance={balance} />
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {/* Extended Betting Card */}
        <BettingCard
          prediction={prediction}
          yesOdds={yesOdds}
          noOdds={noOdds}
          balance={balance}
          onBet={handleBet}
        />

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="grid grid-cols-3 gap-3"
        >
          <div className="flex flex-col items-center p-4 border border-ghost-grey/20 rounded-xl">
            <Users className="w-5 h-5 text-ghost-grey mb-2" />
            <span className="font-mono text-lg font-bold text-ink">
              {Math.floor(prediction.totalPool / 50)}
            </span>
            <span className="font-mono text-xs text-ghost-grey">
              {t('betting.participants')}
            </span>
          </div>
          <div className="flex flex-col items-center p-4 border border-ghost-grey/20 rounded-xl">
            <span className="font-mono text-xs text-ghost-grey mb-2">{t('points.bp')}</span>
            <span className="font-mono text-lg font-bold text-signal-green">
              {prediction.totalPool.toLocaleString()}
            </span>
            <span className="font-mono text-xs text-ghost-grey">Total Pool</span>
          </div>
          <div className="flex flex-col items-center p-4 border border-ghost-grey/20 rounded-xl">
            <Clock className="w-5 h-5 text-ghost-grey mb-2" />
            <span className="font-mono text-lg font-bold text-ink">
              {Math.ceil((new Date(prediction.closesAt).getTime() - Date.now()) / 86400000)}d
            </span>
            <span className="font-mono text-xs text-ghost-grey">
              {t('betting.closesIn')}
            </span>
          </div>
        </motion.div>

        {/* Betting History (placeholder) */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="border border-ghost-grey/20 rounded-xl p-4 space-y-3"
        >
          <h3 className="font-mono text-sm text-ghost-grey uppercase tracking-wider">
            Recent Bets
          </h3>
          {[1, 2, 3].map((i) => (
            <div key={i} className="flex justify-between items-center py-2 border-b border-ghost-grey/10 last:border-0">
              <div className="flex items-center gap-2">
                <span className={`w-2 h-2 rounded-full ${i % 2 === 0 ? 'bg-signal-green' : 'bg-glitch-red'}`} />
                <span className="font-mono text-xs text-ghost-grey">
                  Anonymous #{Math.floor(Math.random() * 9999).toString().padStart(4, '0')}
                </span>
              </div>
              <div className="flex items-center gap-3">
                <span className={`font-mono text-xs font-bold ${i % 2 === 0 ? 'text-signal-green' : 'text-glitch-red'}`}>
                  {i % 2 === 0 ? t('betting.yes') : t('betting.no')}
                </span>
                <span className="font-mono text-xs text-ghost-grey">
                  {Math.floor(Math.random() * 100 + 10)} {t('points.bp')}
                </span>
              </div>
            </div>
          ))}
        </motion.div>

        {/* Discussion CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <Link
            href="/"
            className="flex items-center justify-center gap-3 w-full py-4 border border-signal-green/30 hover:border-signal-green rounded-xl text-signal-green hover:bg-signal-green/5 transition-all font-mono text-sm font-bold uppercase tracking-wider"
          >
            <MessageSquare className="w-4 h-4" />
            {t('landing.feature2Title')}
          </Link>
        </motion.div>
      </div>
    </div>
  );
}
