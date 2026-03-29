'use client';

import { useState, useEffect, useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, X, ArrowLeft, History, User, Globe } from 'lucide-react';
import { Link } from '@/i18n/navigation';
import BettingCard from '@/components/prediction/BettingCard';
import PointsDisplay from '@/components/prediction/PointsDisplay';
import CreatePredictionForm from '@/components/prediction/CreatePredictionForm';
import { usePoints } from '@/hooks/usePoints';
import {
  fetchPredictions, fetchOdds, createPrediction,
  fetchMyBets, fetchMyPredictions,
} from '@/lib/prediction/actions';
import type { Prediction } from '@/types/prediction';

const CATEGORY_KEYS = [
  'all', 'politics', 'sports', 'tech', 'economy',
  'entertainment', 'society', 'gaming', 'other',
] as const;

type Tab = 'all' | 'myBets' | 'myPredictions';

interface VoteClientProps {
  locale: string;
}

function mapPrediction(p: any): Prediction {
  return {
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
}

export default function VoteClient({ locale }: VoteClientProps) {
  const t = useTranslations('Vote');
  const { balance, deviceFingerprint, refreshBalance } = usePoints();
  const [activeTab, setActiveTab] = useState<Tab>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [showCreateForm, setShowCreateForm] = useState(false);

  // All predictions
  const [predictions, setPredictions] = useState<Prediction[]>([]);
  const [oddsMap, setOddsMap] = useState<Record<string, Record<string, number>>>({});
  const [loadingPredictions, setLoadingPredictions] = useState(true);

  // My bets
  const [myBets, setMyBets] = useState<any[]>([]);
  const [loadingBets, setLoadingBets] = useState(false);

  // My predictions
  const [myPredictions, setMyPredictions] = useState<Prediction[]>([]);
  const [loadingMyPreds, setLoadingMyPreds] = useState(false);

  // ─── Load: All Predictions ───
  const loadPredictions = useCallback(async () => {
    setLoadingPredictions(true);
    const result = await fetchPredictions(
      locale,
      selectedCategory === 'all' ? undefined : selectedCategory
    );
    if ('predictions' in result) {
      const mapped = result.predictions.map(mapPrediction);
      setPredictions(mapped);

      const odds: Record<string, Record<string, number>> = {};
      await Promise.all(
        mapped.filter(p => p.status === 'active').map(async (pred) => {
          const oddsResult = await fetchOdds(pred.id);
          if ('odds' in oddsResult) odds[pred.id] = oddsResult.odds;
        })
      );
      setOddsMap(odds);
    }
    setLoadingPredictions(false);
  }, [selectedCategory, locale]);

  // ─── Load: My Bets ───
  const loadMyBets = useCallback(async () => {
    if (!deviceFingerprint) return;
    setLoadingBets(true);
    const result = await fetchMyBets(deviceFingerprint);
    if ('bets' in result) setMyBets(result.bets);
    setLoadingBets(false);
  }, [deviceFingerprint]);

  // ─── Load: My Predictions ───
  const loadMyPredictions = useCallback(async () => {
    if (!deviceFingerprint) return;
    setLoadingMyPreds(true);
    const result = await fetchMyPredictions(deviceFingerprint);
    if ('predictions' in result) {
      setMyPredictions(result.predictions.map(mapPrediction));
    }
    setLoadingMyPreds(false);
  }, [deviceFingerprint]);

  // 탭 변경 시 데이터 로드
  useEffect(() => {
    if (activeTab === 'all') loadPredictions();
    else if (activeTab === 'myBets') loadMyBets();
    else if (activeTab === 'myPredictions') loadMyPredictions();
  }, [activeTab, loadPredictions, loadMyBets, loadMyPredictions]);

  const handleBet = () => {};

  const handleCreate = async (data: { question: string; category: string; closesAt: string }) => {
    if (!deviceFingerprint) return;
    const closesDate = new Date(data.closesAt);
    const revealsDate = new Date(closesDate.getTime() + 86400000);

    const result = await createPrediction(
      deviceFingerprint, data.question, data.category,
      ['yes', 'no'], closesDate.toISOString(), revealsDate.toISOString(), locale,
    );

    if ('success' in result) {
      setShowCreateForm(false);
      await refreshBalance();
      await loadPredictions();
    }
  };

  // ─── Status badge ───
  const StatusBadge = ({ status, answer }: { status: string; answer?: string | null }) => {
    if (status === 'settled') {
      return (
        <span className="px-2 py-0.5 rounded-full text-xs font-mono font-bold bg-signal-green/10 text-signal-green">
          {answer?.toUpperCase() ?? 'SETTLED'}
        </span>
      );
    }
    if (status === 'closed') {
      return (
        <span className="px-2 py-0.5 rounded-full text-xs font-mono font-bold bg-orange-500/10 text-orange-400">
          CLOSED
        </span>
      );
    }
    return null;
  };

  return (
    <div className="min-h-screen bg-void-black text-white">
      {/* Header */}
      <div className="sticky top-0 z-40 bg-void-black/80 backdrop-blur-md border-b border-ghost-grey/10">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link href="/" className="text-ghost-grey hover:text-ink transition-colors">
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <h1 className="font-mono text-lg font-bold text-ink uppercase tracking-wider">
              {t('title')}
            </h1>
          </div>
          <PointsDisplay balance={balance} />
        </div>
      </div>

      <div className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {/* Tabs */}
        <div className="flex gap-1 bg-ghost-grey/5 rounded-lg p-1">
          {([
            { key: 'all' as Tab, icon: Globe, label: 'All' },
            { key: 'myBets' as Tab, icon: History, label: 'My Votes' },
            { key: 'myPredictions' as Tab, icon: User, label: 'Created' },
          ]).map(({ key, icon: Icon, label }) => (
            <button
              key={key}
              onClick={() => setActiveTab(key)}
              className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-md font-mono text-xs uppercase tracking-wider transition-colors
                ${activeTab === key
                  ? 'bg-signal-green/10 text-signal-green border border-signal-green/30'
                  : 'text-ghost-grey hover:text-ink'
                }`}
            >
              <Icon className="w-3.5 h-3.5" />
              {label}
            </button>
          ))}
        </div>

        {/* ─── Tab: All Predictions ─── */}
        {activeTab === 'all' && (
          <>
            {/* Category Filter */}
            <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-hide">
              {CATEGORY_KEYS.map((cat) => (
                <button
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className={`shrink-0 px-4 py-2 rounded-full font-mono text-xs uppercase tracking-wider border transition-colors
                    ${selectedCategory === cat
                      ? 'border-signal-green bg-signal-green/10 text-signal-green'
                      : 'border-ghost-grey/20 text-ghost-grey hover:border-ghost-grey/40'
                    }`}
                >
                  {t(`categories.${cat}`)}
                </button>
              ))}
            </div>

            <div className="space-y-4">
              {loadingPredictions && predictions.length === 0 && (
                <div className="text-center py-20 text-ghost-grey font-mono text-sm animate-pulse">
                  Loading...
                </div>
              )}

              {predictions.map((prediction) => {
                const odds = oddsMap[prediction.id];
                const yesOdds = odds?.['yes'] ?? 1.85;
                const noOdds = odds?.['no'] ?? 2.10;
                return (
                  <Link key={prediction.id} href={
                    prediction.status === 'settled'
                      ? `/vote/${prediction.id}/results`
                      : `/vote/${prediction.id}`
                  }>
                    <div className="relative">
                      <BettingCard
                        prediction={prediction}
                        yesOdds={yesOdds}
                        noOdds={noOdds}
                        balance={balance}
                        onBet={handleBet}
                      />
                      {prediction.status !== 'active' && (
                        <div className="absolute top-3 right-3">
                          <StatusBadge status={prediction.status} answer={prediction.correctAnswer} />
                        </div>
                      )}
                    </div>
                  </Link>
                );
              })}

              {!loadingPredictions && predictions.length === 0 && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="text-center py-20 text-ghost-grey font-mono text-sm"
                >
                  No predictions in this category yet.
                </motion.div>
              )}
            </div>
          </>
        )}

        {/* ─── Tab: My Bets ─── */}
        {activeTab === 'myBets' && (
          <div className="space-y-3">
            {loadingBets && (
              <div className="text-center py-20 text-ghost-grey font-mono text-sm animate-pulse">
                Loading...
              </div>
            )}

            {!loadingBets && myBets.length === 0 && (
              <div className="text-center py-20 text-ghost-grey font-mono text-sm">
                No bets yet. Start betting!
              </div>
            )}

            {myBets.map((bet) => {
              const pred = bet.predictions;
              const isWon = bet.status === 'won';
              const isLost = bet.status === 'lost';
              const isPending = bet.status === 'pending';

              return (
                <Link key={bet.id} href={
                  isWon || isLost
                    ? `/vote/${bet.prediction_id}/results`
                    : `/vote/${bet.prediction_id}`
                }>
                  <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="p-4 border border-ghost-grey/20 rounded-xl space-y-2 hover:border-ghost-grey/40 transition-colors"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <p className="font-sans text-sm text-ink flex-1">
                        {pred?.question ?? 'Unknown prediction'}
                      </p>
                      <span className={`shrink-0 px-2 py-0.5 rounded-full text-xs font-mono font-bold
                        ${isWon ? 'bg-signal-green/10 text-signal-green' : ''}
                        ${isLost ? 'bg-glitch-red/10 text-glitch-red' : ''}
                        ${isPending ? 'bg-ghost-grey/10 text-ghost-grey' : ''}
                        ${bet.status === 'refunded' ? 'bg-blue-500/10 text-blue-400' : ''}
                      `}>
                        {bet.status.toUpperCase()}
                      </span>
                    </div>

                    <div className="flex items-center gap-4 font-mono text-xs text-ghost-grey">
                      <span className={bet.option_id === 'yes' ? 'text-signal-green font-bold' : 'text-glitch-red font-bold'}>
                        {bet.option_id.toUpperCase()}
                      </span>
                      <span>{bet.bet_amount} BP</span>
                      <span>{Number(bet.odds_at_bet).toFixed(2)}x</span>
                      {bet.payout != null && (
                        <span className={isWon ? 'text-signal-green' : 'text-glitch-red'}>
                          {isWon ? '+' : ''}{bet.payout - bet.bet_amount} BP
                        </span>
                      )}
                    </div>
                  </motion.div>
                </Link>
              );
            })}
          </div>
        )}

        {/* ─── Tab: My Predictions ─── */}
        {activeTab === 'myPredictions' && (
          <div className="space-y-3">
            {loadingMyPreds && (
              <div className="text-center py-20 text-ghost-grey font-mono text-sm animate-pulse">
                Loading...
              </div>
            )}

            {!loadingMyPreds && myPredictions.length === 0 && (
              <div className="text-center py-20 text-ghost-grey font-mono text-sm">
                No predictions created yet.
              </div>
            )}

            {myPredictions.map((pred) => (
              <Link key={pred.id} href={
                pred.status === 'settled'
                  ? `/vote/${pred.id}/results`
                  : `/vote/${pred.id}`
              }>
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="p-4 border border-ghost-grey/20 rounded-xl space-y-2 hover:border-ghost-grey/40 transition-colors"
                >
                  <div className="flex items-start justify-between gap-3">
                    <p className="font-sans text-sm text-ink flex-1">{pred.question}</p>
                    <StatusBadge status={pred.status} answer={pred.correctAnswer} />
                  </div>

                  <div className="flex items-center gap-4 font-mono text-xs text-ghost-grey">
                    <span className="bg-ghost-grey/10 px-2 py-0.5 rounded">{pred.category}</span>
                    <span>{pred.totalPool.toLocaleString()} BP pool</span>
                    {pred.status === 'active' && (
                      <span>{Math.ceil((new Date(pred.closesAt).getTime() - Date.now()) / 86400000)}d left</span>
                    )}
                    {pred.status === 'closed' && (
                      <span className="text-orange-400 font-bold">Needs settlement</span>
                    )}
                  </div>
                </motion.div>
              </Link>
            ))}
          </div>
        )}

        {/* Create CTA */}
        <motion.button
          onClick={() => setShowCreateForm(true)}
          className="fixed bottom-6 right-6 z-40 w-14 h-14 rounded-full bg-signal-green text-void-black flex items-center justify-center shadow-lg hover:bg-signal-green/90 transition-colors"
          whileHover={{ scale: 1.1 }}
          whileTap={{ scale: 0.95 }}
        >
          <Plus className="w-6 h-6" />
        </motion.button>

        {/* Create Form Modal */}
        <AnimatePresence>
          {showCreateForm && (
            <motion.div
              className="fixed inset-0 z-50 flex items-center justify-center bg-void-black/80 backdrop-blur-sm p-4"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
            >
              <motion.div
                className="w-full max-w-md relative"
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                exit={{ scale: 0.9, opacity: 0 }}
              >
                <button
                  onClick={() => setShowCreateForm(false)}
                  className="absolute -top-12 right-0 text-ghost-grey hover:text-ink transition-colors"
                >
                  <X className="w-6 h-6" />
                </button>
                <CreatePredictionForm
                  balance={balance}
                  onSubmit={handleCreate}
                />
              </motion.div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
}
