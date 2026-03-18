'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import CopyButton from '@/components/shared/CopyButton';

interface GroupCreatedViewProps {
  roomId: string;
  password: string;
  adminToken: string;
  title: string;
  onEnter: () => void;
}

export default function GroupCreatedView({
  roomId,
  password,
  adminToken,
  title,
  onEnter,
}: GroupCreatedViewProps) {
  const t = useTranslations('Group');
  const [includeKey, setIncludeKey] = useState(true);

  const baseUrl = typeof window !== 'undefined'
    ? `${window.location.origin}${window.location.pathname}`
    : '';
  const shareUrl = includeKey
    ? `${baseUrl}#k=${encodeURIComponent(password)}`
    : baseUrl;

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
          className="font-mono text-xs sm:text-sm text-signal-green uppercase tracking-[0.3em] mb-4"
        >
          {t('created.title')}
        </motion.p>

        {title && (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.3 }}
            className="font-mono text-lg text-ink mb-8"
          >
            {title}
          </motion.p>
        )}

        {/* 비밀번호 */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.4 }}
          className="mb-4"
        >
          <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-3">
            {t('created.password')}
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
            {t('created.adminToken')}
          </p>
          <div className="inline-flex items-center gap-2 bg-ink/[0.03] border border-glitch-red/20 px-4 sm:px-6 py-3 sm:py-4">
            <span className="font-mono text-sm sm:text-base text-glitch-red tracking-[0.2em]">
              {adminToken}
            </span>
            <CopyButton text={adminToken} />
          </div>
        </motion.div>

        {/* 공유 링크 */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="mb-4"
        >
          <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-3">
            {t('created.shareLink')}
          </p>
          <div className="flex items-center gap-2 bg-ink/[0.03] border border-ink/10 px-3 sm:px-4 py-3">
            <span className="font-mono text-[11px] sm:text-xs text-ghost-grey break-all flex-1 text-left leading-relaxed">
              {shareUrl}
            </span>
            <CopyButton text={shareUrl} />
          </div>
        </motion.div>

        {/* 비밀번호 포함 토글 */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.65 }}
          className="mb-6"
        >
          <label className="inline-flex items-center gap-3 cursor-pointer select-none">
            <button
              type="button"
              role="switch"
              aria-checked={includeKey}
              onClick={() => setIncludeKey(!includeKey)}
              className={`relative w-9 h-5 rounded-full transition-colors duration-200 ${
                includeKey ? 'bg-signal-green/80' : 'bg-ink/20'
              }`}
            >
              <span
                className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-void-black transition-transform duration-200 ${
                  includeKey ? 'translate-x-4' : 'translate-x-0'
                }`}
              />
            </button>
            <span className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-wider">
              {t('created.includeKeyInLink')}
            </span>
          </label>
        </motion.div>

        {/* 경고 */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
          className="font-mono text-[10px] text-glitch-red/60 uppercase tracking-wider mb-4"
        >
          {t('created.warning')}
        </motion.p>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.75 }}
          className="font-mono text-[10px] text-glitch-red/60 uppercase tracking-wider mb-8"
        >
          {t('created.adminWarning')}
        </motion.p>

        {/* 입장 버튼 */}
        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={onEnter}
          className="w-full min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider"
        >
          {t('created.enter')}
        </motion.button>
      </motion.div>
    </div>
  );
}
