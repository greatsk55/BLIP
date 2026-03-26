'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { motion, AnimatePresence } from 'framer-motion';
import { Plus, X, ArrowLeft } from 'lucide-react';
import { Link } from '@/i18n/navigation';
import BettingCard from '@/components/prediction/BettingCard';
import PointsDisplay from '@/components/prediction/PointsDisplay';
import CreatePredictionForm from '@/components/prediction/CreatePredictionForm';
import { usePoints } from '@/hooks/usePoints';
import type { Prediction } from '@/types/prediction';

const CATEGORY_KEYS = [
  'all', 'politics', 'sports', 'tech', 'economy',
  'entertainment', 'society', 'gaming', 'other',
] as const;

// 데모용 정적 데이터 (실제 구현 시 Supabase 연동)
const DEMO_PREDICTIONS: Prediction[] = [
  {
    id: 'demo-1',
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
  },
  {
    id: 'demo-2',
    creatorFingerprint: 'demo',
    question: 'Next World Cup winner from Europe?',
    category: 'sports',
    type: 'yes_no',
    options: ['YES', 'NO'],
    correctAnswer: null,
    status: 'active',
    totalPool: 1800,
    createdAt: new Date().toISOString(),
    closesAt: new Date(Date.now() + 86400000 * 7).toISOString(),
    revealsAt: new Date(Date.now() + 86400000 * 8).toISOString(),
    settledAt: null,
  },
  {
    id: 'demo-3',
    creatorFingerprint: 'demo',
    question: 'Will AI pass the Turing test by 2028?',
    category: 'tech',
    type: 'yes_no',
    options: ['YES', 'NO'],
    correctAnswer: null,
    status: 'active',
    totalPool: 3200,
    createdAt: new Date().toISOString(),
    closesAt: new Date(Date.now() + 86400000 * 14).toISOString(),
    revealsAt: new Date(Date.now() + 86400000 * 15).toISOString(),
    settledAt: null,
  },
];

export default function VoteClient() {
  const t = useTranslations('Vote');
  const { balance } = usePoints();
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [showCreateForm, setShowCreateForm] = useState(false);

  const filteredPredictions = selectedCategory === 'all'
    ? DEMO_PREDICTIONS
    : DEMO_PREDICTIONS.filter((p) => p.category === selectedCategory);

  const handleBet = (option: string, amount: number) => {
    // TODO: placeBet server action 연동
    console.log('Bet placed:', option, amount);
  };

  const handleCreate = (data: { question: string; category: string; closesAt: string }) => {
    // TODO: createPrediction server action 연동
    console.log('Create prediction:', data);
    setShowCreateForm(false);
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

        {/* Predictions List */}
        <div className="space-y-4">
          {filteredPredictions.map((prediction) => (
            <Link key={prediction.id} href={`/vote/${prediction.id}`}>
              <BettingCard
                prediction={prediction}
                yesOdds={1.85}
                noOdds={2.10}
                balance={balance}
                onBet={handleBet}
              />
            </Link>
          ))}

          {filteredPredictions.length === 0 && (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-center py-20 text-ghost-grey font-mono text-sm"
            >
              No predictions in this category yet.
            </motion.div>
          )}
        </div>

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
