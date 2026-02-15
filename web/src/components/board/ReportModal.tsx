'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle } from 'lucide-react';
import { useTranslations } from 'next-intl';
import type { ReportReason } from '@/types/board';

interface ReportModalProps {
  isOpen: boolean;
  onConfirm: (reason: ReportReason) => void;
  onCancel: () => void;
}

const REASONS: ReportReason[] = ['spam', 'abuse', 'illegal', 'other'];

export default function ReportModal({ isOpen, onConfirm, onCancel }: ReportModalProps) {
  const t = useTranslations('Board');
  const [selected, setSelected] = useState<ReportReason | null>(null);

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-void-black/80 backdrop-blur-sm px-4 pb-[env(safe-area-inset-bottom)]"
          onClick={onCancel}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.95 }}
            onClick={(e) => e.stopPropagation()}
            className="border border-ink/10 bg-void-black max-w-sm w-full p-6 sm:p-8 text-center mb-4 sm:mb-0"
          >
            <AlertTriangle className="w-8 h-8 text-glitch-red mx-auto mb-4" />

            <h2 className="font-sans text-xl font-bold text-ink uppercase tracking-wider mb-6">
              {t('report.title')}
            </h2>

            {/* 사유 선택 */}
            <div className="space-y-2 mb-6">
              {REASONS.map((reason) => (
                <button
                  key={reason}
                  onClick={() => setSelected(reason)}
                  className={`w-full px-4 py-3 border font-mono text-xs uppercase tracking-wider transition-all ${
                    selected === reason
                      ? 'border-glitch-red text-glitch-red bg-glitch-red/5'
                      : 'border-ink/10 text-ghost-grey/60 hover:border-ink/20'
                  }`}
                >
                  {t(`report.${reason}`)}
                </button>
              ))}
            </div>

            <div className="flex gap-3">
              <button
                onClick={onCancel}
                className="flex-1 min-h-[48px] px-4 py-3 border border-ink/10 text-ghost-grey font-mono text-sm uppercase tracking-wider hover:border-ink/20 transition-colors"
              >
                {t('report.cancel')}
              </button>
              <button
                onClick={() => selected && onConfirm(selected)}
                disabled={!selected}
                className="flex-1 min-h-[48px] px-4 py-3 border border-glitch-red text-glitch-red font-mono text-sm uppercase tracking-wider hover:bg-glitch-red hover:text-white transition-all disabled:opacity-20"
              >
                {t('report.submit')}
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
