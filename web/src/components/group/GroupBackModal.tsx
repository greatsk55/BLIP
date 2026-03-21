'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { ArrowLeft, LogOut } from 'lucide-react';
import { useTranslations } from 'next-intl';

interface GroupBackModalProps {
  isOpen: boolean;
  isLastPerson: boolean;
  onGoBack: () => void;
  onLeaveChat: () => void;
  onCancel: () => void;
}

export default function GroupBackModal({
  isOpen,
  isLastPerson,
  onGoBack,
  onLeaveChat,
  onCancel,
}: GroupBackModalProps) {
  const t = useTranslations('Group.backModal');

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
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            onClick={(e) => e.stopPropagation()}
            className="border border-ink/10 bg-void-black max-w-sm w-full p-6 sm:p-8 mb-4 sm:mb-0"
          >
            <h2 className="font-sans text-lg font-bold text-ink uppercase tracking-wider mb-2 text-center">
              {t('title')}
            </h2>
            <p className="font-mono text-xs text-ghost-grey/60 text-center mb-6">
              {t('description')}
            </p>

            <div className="flex flex-col gap-3">
              {/* 페이지만 나가기 (재접속 가능) */}
              <button
                onClick={onGoBack}
                className="flex items-center justify-center gap-2 w-full min-h-[48px] px-4 py-3 border border-ink/20 text-ink font-mono text-sm uppercase tracking-wider hover:bg-ink/5 active:bg-ink/5 transition-colors"
              >
                <ArrowLeft className="w-4 h-4" />
                {t('goBack')}
              </button>

              {/* 채팅에서 나가기 (완전 퇴장) */}
              <button
                onClick={onLeaveChat}
                className="flex items-center justify-center gap-2 w-full min-h-[48px] px-4 py-3 border border-glitch-red/50 text-glitch-red font-mono text-sm uppercase tracking-wider hover:bg-glitch-red hover:text-white active:bg-glitch-red active:text-white transition-all"
              >
                <LogOut className="w-4 h-4" />
                {t('leaveChat')}
              </button>

              {isLastPerson && (
                <p className="font-mono text-[10px] text-glitch-red/70 text-center uppercase tracking-wider">
                  {t('lastPersonWarning')}
                </p>
              )}

              {/* 취소 */}
              <button
                onClick={onCancel}
                className="w-full min-h-[44px] px-4 py-2.5 text-ghost-grey/50 font-mono text-xs uppercase tracking-wider hover:text-ghost-grey transition-colors"
              >
                {t('cancel')}
              </button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
