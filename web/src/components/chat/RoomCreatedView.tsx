'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import CopyButton from '@/components/shared/CopyButton';

interface RoomCreatedViewProps {
  roomId: string;
  password: string;
  onEnter: () => void;
  peerConnected: boolean;
}

export default function RoomCreatedView({
  roomId,
  password,
  onEnter,
  peerConnected,
}: RoomCreatedViewProps) {
  const t = useTranslations('Chat');
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
          className="font-mono text-xs sm:text-sm text-signal-green uppercase tracking-[0.3em] mb-8 sm:mb-10"
        >
          {t('create.title')}
        </motion.p>

        {/* 비밀번호 표시 */}
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

        {/* 공유 링크 */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="mb-4"
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

        {/* 비밀번호 포함 토글 */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
          className="mb-2"
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
              {t('create.includeKeyInLink')}
            </span>
          </label>
        </motion.div>

        {/* 비밀번호 포함 시 주의사항 */}
        {includeKey && (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="font-mono text-[10px] text-ghost-grey/40 uppercase tracking-wider mb-6"
          >
            {t('create.includeKeyWarning')}
          </motion.p>
        )}

        {!includeKey && <div className="mb-6" />}

        {/* 경고 */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8 }}
          className="font-mono text-[10px] text-glitch-red/60 uppercase tracking-wider mb-8 sm:mb-10"
        >
          {t('create.warning')}
        </motion.p>

        {/* 상대방 대기 상태 */}
        {peerConnected ? (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="mb-6"
          >
            <span className="font-mono text-xs text-signal-green uppercase tracking-wider">
              PEER CONNECTED
            </span>
          </motion.div>
        ) : (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 0.5 }}
            transition={{ delay: 1 }}
            className="mb-6"
          >
            <span className="font-mono text-xs text-ghost-grey/40 uppercase tracking-wider animate-pulse">
              WAITING FOR PEER...
            </span>
          </motion.div>
        )}

        {/* 입장 버튼 */}
        <motion.button
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
