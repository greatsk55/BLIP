'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { X, Trash2, AlertTriangle } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { destroyBoard } from '@/lib/board/actions';

interface AdminPanelProps {
  boardId: string;
  adminToken: string;
  onClose: () => void;
  onPostDeleted: (postId: string) => void;
  onBoardDestroyed: () => void;
}

export default function AdminPanel({
  boardId,
  adminToken,
  onClose,
  onPostDeleted,
  onBoardDestroyed,
}: AdminPanelProps) {
  const t = useTranslations('Board');
  const [showDestroyConfirm, setShowDestroyConfirm] = useState(false);
  const [destroying, setDestroying] = useState(false);

  const handleDestroy = async () => {
    setDestroying(true);
    const result = await destroyBoard(boardId, adminToken);
    setDestroying(false);

    if (result.success) {
      onBoardDestroyed();
    }
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-void-black/80 backdrop-blur-sm px-4 pb-[env(safe-area-inset-bottom)]"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        onClick={(e) => e.stopPropagation()}
        className="border border-ink/10 bg-void-black max-w-sm w-full p-6 sm:p-8 mb-4 sm:mb-0"
      >
        <div className="flex items-center justify-between mb-6">
          <h2 className="font-mono text-sm text-ink uppercase tracking-wider">
            {t('admin.title')}
          </h2>
          <button
            onClick={onClose}
            className="p-1 text-ghost-grey/40 hover:text-ghost-grey transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {!showDestroyConfirm ? (
          <div className="space-y-3">
            {/* 게시판 파쇄 */}
            <button
              onClick={() => setShowDestroyConfirm(true)}
              className="w-full flex items-center gap-3 px-4 py-3 border border-glitch-red/20 text-glitch-red hover:bg-glitch-red/5 transition-colors"
            >
              <Trash2 className="w-4 h-4" />
              <span className="font-mono text-xs uppercase tracking-wider">
                {t('admin.destroy')}
              </span>
            </button>
          </div>
        ) : (
          <div className="text-center">
            <AlertTriangle className="w-8 h-8 text-glitch-red mx-auto mb-4" />
            <p className="font-mono text-xs text-glitch-red uppercase tracking-wider mb-6">
              {t('admin.destroyWarning')}
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDestroyConfirm(false)}
                className="flex-1 min-h-[48px] px-4 py-3 border border-ink/10 text-ghost-grey font-mono text-sm uppercase tracking-wider"
              >
                {t('admin.cancel')}
              </button>
              <button
                onClick={handleDestroy}
                disabled={destroying}
                className="flex-1 min-h-[48px] px-4 py-3 border border-glitch-red text-glitch-red font-mono text-sm uppercase tracking-wider hover:bg-glitch-red hover:text-white transition-all disabled:opacity-50"
              >
                {destroying ? '...' : t('admin.confirmDestroy')}
              </button>
            </div>
          </div>
        )}
      </motion.div>
    </motion.div>
  );
}
