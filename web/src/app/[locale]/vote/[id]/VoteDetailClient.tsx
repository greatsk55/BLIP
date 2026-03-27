'use client';

import { useState, useEffect, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, MessageSquare, Users, Clock, Gavel, CheckCircle, Loader2 } from 'lucide-react';
import { Link, useRouter } from '@/i18n/navigation';
import BettingCard from '@/components/prediction/BettingCard';
import PointsDisplay from '@/components/prediction/PointsDisplay';
import { usePoints } from '@/hooks/usePoints';
import { fetchPrediction, fetchOdds, placeBet, settlePrediction, fetchMyBets } from '@/lib/prediction/actions';
import { generateIdempotencyKey } from '@/lib/prediction/idempotency';
import { getOrCreateDiscussionRoom } from '@/lib/group/actions';
import { saveRoom, saveRoomPassword } from '@/lib/room/storage';
import type { Prediction } from '@/types/prediction';

interface VoteDetailClientProps {
  predictionId: string;
}

export default function VoteDetailClient({ predictionId }: VoteDetailClientProps) {
  const t = useTranslations('Vote');
  const { balance, deviceFingerprint, refreshBalance } = usePoints();
  const [prediction, setPrediction] = useState<Prediction | null>(null);
  const [yesOdds, setYesOdds] = useState(1.85);
  const [noOdds, setNoOdds] = useState(2.10);
  const [betting, setBetting] = useState(false);
  const [myBets, setMyBets] = useState<any[]>([]);
  const [settling, setSettling] = useState(false);
  const [showSettleConfirm, setShowSettleConfirm] = useState<string | null>(null);
  const [joiningDiscussion, setJoiningDiscussion] = useState(false);
  const router = useRouter();

  const isCreator = prediction?.creatorFingerprint === deviceFingerprint;
  const canSettle = isCreator
    && prediction?.status !== 'settled'
    && prediction?.settledAt === null
    && new Date(prediction?.closesAt ?? 0).getTime() <= Date.now();

  // 토론방 참여
  const handleJoinDiscussion = useCallback(async () => {
    if (!prediction || joiningDiscussion) return;
    setJoiningDiscussion(true);

    const result = await getOrCreateDiscussionRoom(prediction.id, prediction.question);

    if ('error' in result) {
      setJoiningDiscussion(false);
      return;
    }

    saveRoom({
      roomId: result.roomId,
      roomType: 'group',
      isCreator: false,
      isAdmin: false,
      title: `💬 ${prediction.question.slice(0, 40)}`,
      createdAt: Date.now(),
      lastAccessedAt: Date.now(),
      status: 'active',
    });
    saveRoomPassword(result.roomId, result.password);

    router.push(
      `/group/${result.roomId}#k=${encodeURIComponent(result.password)}`
    );
  }, [prediction, joiningDiscussion, router]);

  // 정산 처리
  const handleSettle = useCallback(async (resultOption: string) => {
    if (!deviceFingerprint || !prediction || settling) return;
    setSettling(true);

    const result = await settlePrediction(prediction.id, resultOption, deviceFingerprint);

    if ('success' in result) {
      await refreshBalance();
      router.push(`/vote/${prediction.id}/results`);
    }
    setSettling(false);
    setShowSettleConfirm(null);
  }, [deviceFingerprint, prediction, settling, refreshBalance, router]);

  // 예측 + 배당률 조회
  useEffect(() => {
    async function load() {
      const [predResult, oddsResult] = await Promise.all([
        fetchPrediction(predictionId),
        fetchOdds(predictionId),
      ]);

      if ('prediction' in predResult) {
        const p = predResult.prediction;
        setPrediction({
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
        });
      }

      if ('odds' in oddsResult) {
        setYesOdds(oddsResult.odds['yes'] ?? 1.85);
        setNoOdds(oddsResult.odds['no'] ?? 2.10);
      }

      // 내 베팅 조회
      if (deviceFingerprint) {
        const betsResult = await fetchMyBets(deviceFingerprint, predictionId);
        if ('bets' in betsResult) setMyBets(betsResult.bets);
      }
    }
    load();
  }, [predictionId, deviceFingerprint]);

  const handleBet = useCallback(async (option: string, amount: number) => {
    if (!deviceFingerprint || betting) return;
    setBetting(true);

    const idempotencyKey = generateIdempotencyKey(
      `${deviceFingerprint}-${predictionId}-${option}`
    );

    const result = await placeBet(
      predictionId, deviceFingerprint, option, amount, idempotencyKey
    );

    if ('success' in result) {
      await refreshBalance();
      // 배당률 + 내 베팅 새로 조회
      const [oddsResult, betsResult] = await Promise.all([
        fetchOdds(predictionId),
        deviceFingerprint ? fetchMyBets(deviceFingerprint, predictionId) : Promise.resolve({ bets: [] }),
      ]);
      if ('odds' in oddsResult) {
        setYesOdds(oddsResult.odds['yes'] ?? yesOdds);
        setNoOdds(oddsResult.odds['no'] ?? noOdds);
      }
      if ('bets' in betsResult) setMyBets(betsResult.bets);
    }
    setBetting(false);
  }, [deviceFingerprint, predictionId, betting, refreshBalance, yesOdds, noOdds]);

  if (!prediction) {
    return (
      <div className="min-h-screen bg-void-black text-white flex items-center justify-center">
        <div className="text-ghost-grey font-mono text-sm animate-pulse">Loading...</div>
      </div>
    );
  }

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

        {/* My Bets */}
        {myBets.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="border border-ghost-grey/20 rounded-xl p-4 space-y-3"
          >
            <h3 className="font-mono text-sm text-ghost-grey uppercase tracking-wider">
              My Bets
            </h3>
            {myBets.map((bet: any) => {
              const isYes = bet.option_id === 'yes';
              return (
                <div key={bet.id} className="flex justify-between items-center py-2 border-b border-ghost-grey/10 last:border-0">
                  <div className="flex items-center gap-3">
                    <span className={`w-2 h-2 rounded-full ${isYes ? 'bg-signal-green' : 'bg-glitch-red'}`} />
                    <span className={`font-mono text-xs font-bold ${isYes ? 'text-signal-green' : 'text-glitch-red'}`}>
                      {bet.option_id.toUpperCase()}
                    </span>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="font-mono text-xs text-ghost-grey">
                      {bet.bet_amount} {t('points.bp')}
                    </span>
                    <span className="font-mono text-xs text-ghost-grey">
                      {Number(bet.odds_at_bet).toFixed(2)}x
                    </span>
                  </div>
                </div>
              );
            })}
          </motion.div>
        )}

        {/* 정산 완료 상태 */}
        {prediction.status === 'settled' && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center gap-3 p-4 border border-signal-green/30 rounded-xl bg-signal-green/5"
          >
            <CheckCircle className="w-5 h-5 text-signal-green shrink-0" />
            <div>
              <p className="font-mono text-sm font-bold text-signal-green uppercase">
                Settled — {prediction.correctAnswer?.toUpperCase()}
              </p>
              <Link
                href={`/vote/${prediction.id}/results`}
                className="font-mono text-xs text-ghost-grey hover:text-ink transition-colors underline"
              >
                View Results →
              </Link>
            </div>
          </motion.div>
        )}

        {/* 생성자 정산 UI (마감 후에만 표시) */}
        {canSettle && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.35 }}
            className="border border-orange-500/30 rounded-xl p-4 space-y-3 bg-orange-500/5"
          >
            <div className="flex items-center gap-2">
              <Gavel className="w-4 h-4 text-orange-400" />
              <h3 className="font-mono text-sm text-orange-400 font-bold uppercase">
                Settle Prediction
              </h3>
            </div>
            <p className="font-mono text-xs text-ghost-grey">
              You created this prediction. Select the correct answer to settle and distribute payouts.
            </p>
            <div className="grid grid-cols-2 gap-3">
              {prediction.options.map((option) => (
                <button
                  key={option}
                  disabled={settling}
                  onClick={() => setShowSettleConfirm(option)}
                  className={`py-3 rounded-lg font-mono font-bold text-sm uppercase tracking-wider border transition-all
                    ${option === 'yes'
                      ? 'border-signal-green/50 text-signal-green hover:bg-signal-green/10'
                      : 'border-glitch-red/50 text-glitch-red hover:bg-glitch-red/10'
                    }
                    ${settling ? 'opacity-50 cursor-not-allowed' : ''}`}
                >
                  {option.toUpperCase()} wins
                </button>
              ))}
            </div>
          </motion.div>
        )}

        {/* 정산 확인 모달 */}
        <AnimatePresence>
          {showSettleConfirm && (
            <motion.div
              className="fixed inset-0 z-50 flex items-center justify-center bg-void-black/80 backdrop-blur-sm p-4"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <motion.div
                className="bg-void-black border border-ghost-grey/20 rounded-2xl p-6 max-w-sm w-full space-y-4 text-center"
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.9, opacity: 0 }}
              >
                <Gavel className="w-10 h-10 text-orange-400 mx-auto" />
                <h3 className="font-mono text-lg font-bold text-ink">
                  Confirm Settlement
                </h3>
                <p className="font-mono text-sm text-ghost-grey">
                  The correct answer is{' '}
                  <span className={`font-bold ${showSettleConfirm === 'yes' ? 'text-signal-green' : 'text-glitch-red'}`}>
                    {showSettleConfirm.toUpperCase()}
                  </span>
                  ?
                </p>
                <p className="font-mono text-xs text-ghost-grey">
                  This action cannot be undone. Payouts will be distributed immediately.
                </p>
                <div className="grid grid-cols-2 gap-3 pt-2">
                  <button
                    onClick={() => setShowSettleConfirm(null)}
                    disabled={settling}
                    className="py-3 rounded-lg font-mono text-sm text-ghost-grey border border-ghost-grey/30 hover:bg-ghost-grey/10 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={() => handleSettle(showSettleConfirm)}
                    disabled={settling}
                    className="py-3 rounded-lg font-mono text-sm font-bold bg-orange-500 text-void-black hover:bg-orange-400 transition-colors disabled:opacity-50"
                  >
                    {settling ? 'Settling...' : 'Confirm'}
                  </button>
                </div>
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Discussion CTA — 예측 전용 그룹채팅 참여 */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
        >
          <button
            onClick={handleJoinDiscussion}
            disabled={joiningDiscussion}
            className="flex items-center justify-center gap-3 w-full py-4 border border-signal-green/30 hover:border-signal-green rounded-xl text-signal-green hover:bg-signal-green/5 transition-all font-mono text-sm font-bold uppercase tracking-wider disabled:opacity-50"
          >
            {joiningDiscussion ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              <MessageSquare className="w-4 h-4" />
            )}
            {t('discuss')}
          </button>
        </motion.div>
      </div>
    </div>
  );
}
