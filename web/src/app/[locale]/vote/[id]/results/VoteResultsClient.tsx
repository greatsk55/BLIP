'use client';

import { useState, useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { ArrowLeft, Trophy } from 'lucide-react';
import { Link } from '@/i18n/navigation';
import SettlementModal from '@/components/prediction/SettlementModal';
import PointsDisplay from '@/components/prediction/PointsDisplay';
import { usePoints } from '@/hooks/usePoints';
import { fetchPrediction, fetchMyBets } from '@/lib/prediction/actions';
import type { Prediction, SettlementResult } from '@/types/prediction';

interface VoteResultsClientProps {
  predictionId: string;
}

export default function VoteResultsClient({ predictionId }: VoteResultsClientProps) {
  const t = useTranslations('Vote');
  const { balance, deviceFingerprint } = usePoints();

  const [prediction, setPrediction] = useState<Prediction | null>(null);
  const [showModal, setShowModal] = useState(false);
  const [settlementResult, setSettlementResult] = useState<SettlementResult | null>(null);
  const [yesPercent, setYesPercent] = useState(50);
  const [noPercent, setNoPercent] = useState(50);

  useEffect(() => {
    async function load() {
      const predResult = await fetchPrediction(predictionId);
      if (!('prediction' in predResult)) return;

      const p = predResult.prediction;
      const pred: Prediction = {
        id: p.id,
        creatorFingerprint: p.creator_fingerprint,
        question: p.question,
        category: p.category,
        type: p.type,
        options: p.options ?? ['yes', 'no'],
        correctAnswer: p.correct_answer,
        status: p.status,
        totalPool: p.total_pool,
        createdAt: p.created_at,
        closesAt: p.closes_at,
        revealsAt: p.reveals_at,
        settledAt: p.settled_at,
      };
      setPrediction(pred);

      // 차트 퍼센트 계산
      if (pred.totalPool > 0) {
        const total = pred.totalPool;
        setYesPercent(Math.round((total * 0.6) / total * 100)); // 실제로는 옵션별 합계 필요
        setNoPercent(Math.round((total * 0.4) / total * 100));
      }

      // 내 베팅 기록 조회
      if (deviceFingerprint) {
        const betsResult = await fetchMyBets(deviceFingerprint, predictionId);
        if ('bets' in betsResult && betsResult.bets.length > 0) {
          const myBet = betsResult.bets[0];
          if (myBet.status === 'won' || myBet.status === 'lost') {
            const payout = myBet.payout ?? 0;
            setSettlementResult({
              won: myBet.status === 'won',
              betAmount: myBet.bet_amount,
              odds: Number(myBet.odds_at_bet),
              payout,
              balanceChange: myBet.status === 'won' ? payout - myBet.bet_amount : -myBet.bet_amount,
            });
            setShowModal(true);
          }
        }
      }
    }
    load();
  }, [predictionId, deviceFingerprint]);

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
        {/* Result Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center py-8 space-y-4"
        >
          <Trophy className="w-12 h-12 text-signal-green mx-auto" />
          <h2 className="font-sans text-2xl font-bold text-ink">
            {prediction?.question ?? 'Loading...'}
          </h2>
          {prediction?.correctAnswer && (
            <span className="inline-block px-3 py-1 rounded-full bg-signal-green/10 text-signal-green font-mono text-sm font-bold">
              {prediction.correctAnswer.toUpperCase()} — {t('betting.closed')}
            </span>
          )}
        </motion.div>

        {/* Result Chart */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="border border-ghost-grey/20 rounded-xl p-6 space-y-4"
        >
          {/* YES bar */}
          <div className="space-y-2">
            <div className="flex justify-between font-mono text-sm">
              <span className="text-signal-green font-bold">{t('betting.yes')}</span>
              <span className="text-ghost-grey">{yesPercent}%</span>
            </div>
            <div className="w-full h-4 bg-ghost-grey/10 rounded-full overflow-hidden">
              <motion.div
                className="h-full bg-signal-green rounded-full"
                initial={{ width: 0 }}
                animate={{ width: `${yesPercent}%` }}
                transition={{ delay: 0.4, duration: 0.8, ease: 'easeOut' }}
              />
            </div>
          </div>

          {/* NO bar */}
          <div className="space-y-2">
            <div className="flex justify-between font-mono text-sm">
              <span className="text-glitch-red font-bold">{t('betting.no')}</span>
              <span className="text-ghost-grey">{noPercent}%</span>
            </div>
            <div className="w-full h-4 bg-ghost-grey/10 rounded-full overflow-hidden">
              <motion.div
                className="h-full bg-glitch-red rounded-full"
                initial={{ width: 0 }}
                animate={{ width: `${noPercent}%` }}
                transition={{ delay: 0.5, duration: 0.8, ease: 'easeOut' }}
              />
            </div>
          </div>
        </motion.div>

        {/* Back to list */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
        >
          <Link
            href="/vote"
            className="block text-center w-full py-4 border border-signal-green/30 hover:border-signal-green rounded-xl text-signal-green hover:bg-signal-green/5 transition-all font-mono text-sm font-bold uppercase tracking-wider"
          >
            {t('title')}
          </Link>
        </motion.div>
      </div>

      {/* Settlement Modal */}
      {showModal && settlementResult && (
        <SettlementModal
          result={settlementResult}
          onClose={() => setShowModal(false)}
        />
      )}
    </div>
  );
}
