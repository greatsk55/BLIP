'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { CREATION_COST, CREATION_COST_DISCOUNT } from '@/lib/prediction/constants';
import { getRank } from '@/lib/prediction/rank';

interface CreatePredictionFormProps {
  balance: number;
  onSubmit: (data: { question: string; category: string; closesAt: string }) => void;
}

const CATEGORIES = ['crypto', 'tech', 'sports', 'politics', 'entertainment', 'other'];

export default function CreatePredictionForm({ balance, onSubmit }: CreatePredictionFormProps) {
  const [question, setQuestion] = useState('');
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [closesAt, setClosesAt] = useState('');

  const rank = getRank(balance);
  const discount = CREATION_COST_DISCOUNT[rank.name] ?? 1;
  const cost = Math.floor(CREATION_COST * discount);
  const canAfford = balance >= cost;
  const isValid = question.trim().length > 0 && closesAt.length > 0 && canAfford;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValid) return;
    onSubmit({ question: question.trim(), category, closesAt });
  };

  return (
    <motion.form
      onSubmit={handleSubmit}
      className="space-y-4 p-4 rounded-xl border border-ghost-grey/20 bg-void-black"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
    >
      {/* Question */}
      <div className="space-y-1">
        <label htmlFor="prediction-question" className="text-sm font-mono text-ghost-grey">
          QUESTION
        </label>
        <input
          id="prediction-question"
          type="text"
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          placeholder="Will BTC hit $100k?"
          className="w-full px-3 py-2 rounded-lg bg-void-black border border-ghost-grey/30 text-ink font-sans focus:border-signal-green outline-none"
          maxLength={200}
        />
      </div>

      {/* Category */}
      <div className="space-y-1">
        <label htmlFor="prediction-category" className="text-sm font-mono text-ghost-grey">
          CATEGORY
        </label>
        <select
          id="prediction-category"
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="w-full px-3 py-2 rounded-lg bg-void-black border border-ghost-grey/30 text-ink font-mono focus:border-signal-green outline-none"
        >
          {CATEGORIES.map((cat) => (
            <option key={cat} value={cat}>
              {cat}
            </option>
          ))}
        </select>
      </div>

      {/* Closes At */}
      <div className="space-y-1">
        <label htmlFor="prediction-closes" className="text-sm font-mono text-ghost-grey">
          CLOSES AT
        </label>
        <input
          id="prediction-closes"
          type="datetime-local"
          value={closesAt}
          onChange={(e) => setClosesAt(e.target.value)}
          className="w-full px-3 py-2 rounded-lg bg-void-black border border-ghost-grey/30 text-ink font-mono focus:border-signal-green outline-none"
        />
      </div>

      {/* Cost */}
      <div className="flex justify-between items-center text-sm font-mono">
        <span className="text-ghost-grey">COST</span>
        <span className={canAfford ? 'text-signal-green' : 'text-glitch-red'}>
          {cost} BP
          {discount < 1 && (
            <span className="ml-1 text-ghost-grey line-through">{CREATION_COST} BP</span>
          )}
        </span>
      </div>

      {/* Submit */}
      <motion.button
        type="submit"
        disabled={!isValid}
        className={`w-full py-3 rounded-lg font-mono font-bold transition-colors
          ${isValid
            ? 'bg-signal-green text-void-black hover:bg-signal-green/90'
            : 'bg-ghost-grey/20 text-ghost-grey cursor-not-allowed'
          }`}
      >
        CREATE PREDICTION
      </motion.button>
    </motion.form>
  );
}
