'use client';

import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import CopyButton from '@/components/shared/CopyButton';

interface BoardCreatedViewProps {
  boardId: string;
  password: string;
  adminToken: string;
  onEnter: () => void;
}

export default function BoardCreatedView({
  boardId,
  password,
  adminToken,
  onEnter,
}: BoardCreatedViewProps) {
  const t = useTranslations('Board');
  const shareUrl =
    typeof window !== 'undefined'
      ? `${window.location.origin}/board/${boardId}`
      : '';

  return (
    <div className="h-dvh bg-void-black flex items-center justify-center px-6 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)] overflow-y-auto">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-md text-center py-8"
      >
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="font-mono text-xs sm:text-sm text-signal-green uppercase tracking-[0.3em] mb-8 sm:mb-10"
        >
          {t('create.title')}
        </motion.p>

        {/* 비밀번호 */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.4 }}
          className="mb-4"
        >
          <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-3">
            {t('create.password')}
          </p>
          <div className="inline-flex items-center gap-2 bg-ink/[0.03] border border-signal-green/20 px-4 sm:px-6 py-3 sm:py-4">
            <span className="font-mono text-lg sm:text-2xl text-ink tracking-[0.3em] sm:tracking-[0.5em]">
              {password}
            </span>
            <CopyButton text={password} />
          </div>
        </motion.div>

        {/* 관리자 토큰 */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.5 }}
          className="mb-4"
        >
          <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-3">
            {t('create.adminToken')}
          </p>
          <div className="inline-flex items-center gap-2 bg-ink/[0.03] border border-glitch-red/20 px-3 sm:px-4 py-3">
            <span className="font-mono text-[10px] sm:text-xs text-ghost-grey break-all">
              {adminToken}
            </span>
            <CopyButton text={adminToken} />
          </div>
          <p className="font-mono text-[9px] text-glitch-red/50 uppercase tracking-wider mt-2">
            {t('create.adminTokenWarning')}
          </p>
        </motion.div>

        {/* 공유 링크 */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="mb-8"
        >
          <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-3">
            {t('create.shareLink')}
          </p>
          <div className="flex items-center gap-2 bg-ink/[0.03] border border-ink/10 px-3 sm:px-4 py-3">
            <span className="font-mono text-[11px] sm:text-xs text-ghost-grey break-all flex-1 text-left leading-relaxed">
              {shareUrl}
            </span>
            <CopyButton text={shareUrl} />
          </div>
        </motion.div>

        {/* 입장 버튼 */}
        <motion.button
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8 }}
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={onEnter}
          className="w-full min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider"
        >
          {t('create.enter')}
        </motion.button>
      </motion.div>
    </div>
  );
}
