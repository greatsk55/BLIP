'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Trash2, Shield, ArrowRight } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Link } from '@/i18n/navigation';
import { getSavedBoards, removeSavedBoard, type SavedBoard } from '@/hooks/useBoard';
import { destroyBoard } from '@/lib/board/actions';

export default function SavedBoardsList() {
  const t = useTranslations('Board.dashboard');
  const [boards, setBoards] = useState<SavedBoard[]>([]);
  const [confirmTarget, setConfirmTarget] = useState<SavedBoard | null>(null);
  const [destroying, setDestroying] = useState(false);

  useEffect(() => {
    setBoards(getSavedBoards());
  }, []);

  const handleRemove = useCallback(async () => {
    if (!confirmTarget) return;
    const { boardId, hasAdminToken } = confirmTarget;

    if (hasAdminToken) {
      setDestroying(true);
      const adminToken = localStorage.getItem(`blip-board-admin-${boardId}`);
      if (adminToken) {
        await destroyBoard(boardId, adminToken);
      }
      setDestroying(false);
    }

    removeSavedBoard(boardId);
    setBoards((prev) => prev.filter((b) => b.boardId !== boardId));
    setConfirmTarget(null);
  }, [confirmTarget]);

  if (boards.length === 0) return null;

  return (
    <div className="w-full max-w-sm mx-auto mb-12">
      <h2 className="font-mono text-xs text-ghost-grey/60 uppercase tracking-[0.3em] mb-4 text-center">
        {t('title')}
      </h2>

      <div className="space-y-2">
        {boards.map((board) => (
          <motion.div
            key={board.boardId}
            layout
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="group flex items-center gap-3 p-3 border border-ink/5 hover:border-signal-green/20 transition-colors"
          >
            <Link
              href={`/board/${board.boardId}`}
              className="flex-1 min-w-0 flex items-center gap-2"
            >
              <span className="font-mono text-sm text-ink truncate">
                {board.name || board.boardId.slice(0, 8)}
              </span>
              {board.hasAdminToken && (
                <Shield className="w-3 h-3 text-signal-green/60 flex-shrink-0" />
              )}
              <ArrowRight className="w-3 h-3 text-ghost-grey/30 ml-auto flex-shrink-0 opacity-0 group-hover:opacity-100 transition-opacity" />
            </Link>

            <button
              onClick={() => setConfirmTarget(board)}
              className="p-1.5 text-ghost-grey/30 hover:text-glitch-red transition-colors flex-shrink-0"
              aria-label={t('remove')}
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          </motion.div>
        ))}
      </div>

      {/* 삭제 확인 모달 */}
      <AnimatePresence>
        {confirmTarget && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 px-6"
            onClick={() => !destroying && setConfirmTarget(null)}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-xs bg-void-black border border-ink/10 p-6"
            >
              <p className="font-mono text-sm text-ink mb-2">
                {t('removeConfirm')}
              </p>
              <p className="font-mono text-xs text-ghost-grey/60 mb-1">
                {confirmTarget.name || confirmTarget.boardId.slice(0, 8)}
              </p>
              <p className="font-mono text-xs text-ghost-grey/40 mb-6">
                {confirmTarget.hasAdminToken
                  ? t('removeAdminWarning')
                  : t('removeLocalOnly')}
              </p>

              <div className="flex gap-3">
                <button
                  onClick={() => setConfirmTarget(null)}
                  disabled={destroying}
                  className="flex-1 min-h-[40px] px-4 py-2 border border-ink/10 text-ghost-grey font-mono text-xs uppercase tracking-wider hover:border-ink/30 transition-colors disabled:opacity-50"
                >
                  {t('cancel')}
                </button>
                <button
                  onClick={handleRemove}
                  disabled={destroying}
                  className="flex-1 min-h-[40px] px-4 py-2 border border-glitch-red/30 text-glitch-red font-mono text-xs uppercase tracking-wider hover:bg-glitch-red hover:text-void-black transition-all disabled:opacity-50"
                >
                  {destroying ? t('destroying') : t('confirmRemove')}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
