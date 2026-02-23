'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { X, Trash2, AlertTriangle, Type } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { destroyBoard } from '@/lib/board/actions';

interface AdminPanelProps {
  boardId: string;
  adminToken: string;
  currentSubtitle?: string | null;
  onUpdateSubtitle: (subtitle: string) => Promise<{ error?: string }>;
  onClose: () => void;
  onPostDeleted: (postId: string) => void;
  onBoardDestroyed: () => void;
}

export default function AdminPanel({
  boardId,
  adminToken,
  currentSubtitle,
  onUpdateSubtitle,
  onClose,
  onPostDeleted,
  onBoardDestroyed,
}: AdminPanelProps) {
  const t = useTranslations('Board');
  const [showDestroyConfirm, setShowDestroyConfirm] = useState(false);
  const [destroying, setDestroying] = useState(false);
  const [showSubtitleEdit, setShowSubtitleEdit] = useState(false);
  const [subtitleValue, setSubtitleValue] = useState(currentSubtitle ?? '');
  const [subtitleSaving, setSubtitleSaving] = useState(false);

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
            className="p-1 text-ghost-grey/70 hover:text-ghost-grey transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {!showDestroyConfirm ? (
          <div className="space-y-3">
            {/* 부제목 편집 */}
            {!showSubtitleEdit ? (
              <button
                onClick={() => setShowSubtitleEdit(true)}
                className="w-full flex items-center gap-3 px-4 py-3 border border-ink/10 text-ink hover:border-signal-green/30 transition-colors"
              >
                <Type className="w-4 h-4" />
                <span className="font-mono text-xs uppercase tracking-wider">
                  {t('admin.editSubtitle')}
                </span>
                {currentSubtitle && (
                  <span className="ml-auto font-mono text-[10px] text-ghost-grey/50 truncate max-w-[120px]">
                    {currentSubtitle}
                  </span>
                )}
              </button>
            ) : (
              <div className="border border-ink/10 p-4">
                <label className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-wider mb-2 block">
                  {t('admin.subtitleLabel')}
                </label>
                <input
                  type="text"
                  value={subtitleValue}
                  onChange={(e) => setSubtitleValue(e.target.value)}
                  placeholder={t('admin.subtitlePlaceholder')}
                  maxLength={100}
                  className="w-full px-3 py-2 bg-transparent border border-ink/10 text-ink font-mono text-xs placeholder:text-ghost-grey/30 focus:border-signal-green/50 focus:outline-none mb-3"
                  autoFocus
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      void (async () => {
                        setSubtitleSaving(true);
                        await onUpdateSubtitle(subtitleValue);
                        setSubtitleSaving(false);
                        setShowSubtitleEdit(false);
                      })();
                    }
                  }}
                />
                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      setSubtitleValue(currentSubtitle ?? '');
                      setShowSubtitleEdit(false);
                    }}
                    className="flex-1 min-h-[36px] px-3 py-2 border border-ink/10 text-ghost-grey font-mono text-[10px] uppercase tracking-wider"
                  >
                    {t('admin.cancel')}
                  </button>
                  <button
                    onClick={async () => {
                      setSubtitleSaving(true);
                      await onUpdateSubtitle(subtitleValue);
                      setSubtitleSaving(false);
                      setShowSubtitleEdit(false);
                    }}
                    disabled={subtitleSaving}
                    className="flex-1 min-h-[36px] px-3 py-2 border border-signal-green text-signal-green font-mono text-[10px] uppercase tracking-wider hover:bg-signal-green hover:text-void-black transition-all disabled:opacity-50"
                  >
                    {subtitleSaving ? '...' : t('admin.subtitleSave')}
                  </button>
                </div>
              </div>
            )}

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
