'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { AlertTriangle } from 'lucide-react';
import { useTranslations } from 'next-intl';

interface LeaveConfirmModalProps {
  isOpen: boolean;
  isLastPerson: boolean;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function LeaveConfirmModal({
  isOpen,
  isLastPerson,
  onConfirm,
  onCancel,
}: LeaveConfirmModalProps) {
  const t = useTranslations('Chat');

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

            <h2 className="font-sans text-xl font-bold text-ink uppercase tracking-wider mb-4">
              {t('leave.title')}
            </h2>

            <p className="font-mono text-sm text-ghost-grey mb-2">
              {t('leave.description')}
            </p>

            {isLastPerson && (
              <p className="font-mono text-xs text-glitch-red mt-2 mb-6 uppercase tracking-wider">
                {t('leave.lastPersonWarning')}
              </p>
            )}

            <div className="flex gap-3 mt-6">
              <button
                onClick={onCancel}
                className="flex-1 min-h-[48px] px-4 py-3 border border-ink/10 text-ghost-grey font-mono text-sm uppercase tracking-wider hover:border-ink/20 active:border-ink/20 transition-colors"
              >
                {t('leave.cancel')}
              </button>
              <button
                onClick={onConfirm}
                className="flex-1 min-h-[48px] px-4 py-3 border border-glitch-red text-glitch-red font-mono text-sm uppercase tracking-wider hover:bg-glitch-red hover:text-white active:bg-glitch-red active:text-white transition-all"
              >
                {t('leave.confirm')}
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
