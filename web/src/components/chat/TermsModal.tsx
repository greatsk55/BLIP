'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { X } from 'lucide-react';
import { useTranslations } from 'next-intl';

interface TermsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const TERMS_SECTION_COUNT = 11;

export default function TermsModal({ isOpen, onClose }: TermsModalProps) {
  const t = useTranslations('Terms');

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-void-black/80 backdrop-blur-sm px-4 pb-[env(safe-area-inset-bottom)]"
          onClick={onClose}
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            onClick={(e) => e.stopPropagation()}
            className="border border-ink/10 bg-void-black max-w-lg w-full max-h-[80vh] flex flex-col mb-4 sm:mb-0"
          >
            {/* Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-ink/10 shrink-0">
              <h2 className="font-sans text-lg font-bold text-ink uppercase tracking-wider">
                {t('title')}
              </h2>
              <button
                onClick={onClose}
                className="min-w-[44px] min-h-[44px] flex items-center justify-center text-ghost-grey hover:text-ink transition-colors -mr-2"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Scrollable Content */}
            <div className="overflow-y-auto flex-1 px-6 py-4 space-y-6">
              <p className="font-mono text-xs text-ghost-grey/60 uppercase tracking-wider">
                {t('lastUpdated')}
              </p>
              <p className="font-mono text-sm text-ghost-grey leading-relaxed">
                {t('intro')}
              </p>

              {Array.from({ length: TERMS_SECTION_COUNT }, (_, i) => {
                const key = String(i + 1);
                return (
                  <div key={key}>
                    <h3 className="font-sans text-sm font-bold text-ink uppercase tracking-wider mb-2">
                      {t(`sections.${key}.title`)}
                    </h3>
                    <p className="font-mono text-xs text-ghost-grey leading-relaxed">
                      {t(`sections.${key}.content`)}
                    </p>
                  </div>
                );
              })}
            </div>

            {/* Footer */}
            <div className="px-6 py-4 border-t border-ink/10 shrink-0">
              <button
                onClick={onClose}
                className="w-full min-h-[48px] px-4 py-3 border border-ink/10 text-ghost-grey font-mono text-sm uppercase tracking-wider hover:border-ink/20 active:border-ink/20 transition-colors"
              >
                {t('close')}
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
