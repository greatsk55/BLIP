'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { Shield, KeyRound } from 'lucide-react';
import { ThemeToggle } from '@/components/ThemeToggle';
import { useTranslations } from 'next-intl';

interface BoardHeaderProps {
  boardName: string;
  onAdmin: () => void;
  hasAdminToken: boolean;
  isPasswordSaved: boolean;
  onForgetPassword: () => void;
  onSaveAdminToken: (token: string) => void;
}

export default function BoardHeader({
  boardName,
  onAdmin,
  hasAdminToken,
  isPasswordSaved,
  onForgetPassword,
  onSaveAdminToken,
}: BoardHeaderProps) {
  const t = useTranslations('Board');
  const router = useRouter();
  const [showForgetConfirm, setShowForgetConfirm] = useState(false);
  const [showTokenInput, setShowTokenInput] = useState(false);
  const [tokenValue, setTokenValue] = useState('');

  return (
    <>
      <header className="flex-shrink-0 flex items-center justify-between px-4 py-3 border-b border-ink/10 bg-void-black/80 backdrop-blur-sm pt-[env(safe-area-inset-top)]">
        <div className="flex items-center gap-3 min-w-0">
          <button
            onClick={() => router.push('/')}
            className="font-mono text-xs text-ghost-grey/70 hover:text-ghost-grey transition-colors"
            aria-label="Back to home"
          >
            ←
          </button>
          <div className="min-w-0">
            <h1 className="font-mono text-sm text-ink uppercase tracking-wider truncate">
              {boardName}
            </h1>
            <p className="font-mono text-[9px] text-signal-green/60 uppercase tracking-wider">
              {t('header.encrypted')}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <ThemeToggle />

          {isPasswordSaved && (
            <button
              onClick={() => setShowForgetConfirm(true)}
              className="p-2 text-ghost-grey/70 hover:text-glitch-red transition-colors"
              aria-label={t('header.forgetPassword')}
              title={t('header.forgetPassword')}
            >
              <KeyRound className="w-4 h-4" />
            </button>
          )}

          {hasAdminToken ? (
            <button
              onClick={onAdmin}
              className="p-2 text-ghost-grey/70 hover:text-signal-green transition-colors"
              aria-label={t('header.admin')}
              title={t('header.admin')}
            >
              <Shield className="w-4 h-4" />
            </button>
          ) : (
            <button
              onClick={() => setShowTokenInput(true)}
              className="p-2 text-ghost-grey/40 hover:text-ghost-grey/70 transition-colors"
              aria-label={t('header.registerAdmin')}
              title={t('header.registerAdmin')}
            >
              <Shield className="w-4 h-4" />
            </button>
          )}
        </div>
      </header>

      {/* 비밀번호 삭제 확인 모달 */}
      <AnimatePresence>
        {showForgetConfirm && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-void-black/80 backdrop-blur-sm px-4 pb-[env(safe-area-inset-bottom)]"
            onClick={() => setShowForgetConfirm(false)}
          >
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="border border-ink/10 bg-void-black max-w-sm w-full p-6 sm:p-8 text-center mb-4 sm:mb-0"
            >
              <KeyRound className="w-8 h-8 text-glitch-red mx-auto mb-4" />

              <p className="font-mono text-xs text-ghost-grey/80 leading-relaxed mb-6">
                {t('header.forgetPasswordConfirm')}
              </p>

              <div className="flex gap-3">
                <button
                  onClick={() => setShowForgetConfirm(false)}
                  className="flex-1 min-h-[48px] px-4 py-3 border border-ink/10 text-ghost-grey font-mono text-sm uppercase tracking-wider hover:border-ink/20 transition-colors"
                >
                  {t('header.cancel')}
                </button>
                <button
                  onClick={() => {
                    onForgetPassword();
                    setShowForgetConfirm(false);
                  }}
                  className="flex-1 min-h-[48px] px-4 py-3 border border-glitch-red text-glitch-red font-mono text-sm uppercase tracking-wider hover:bg-glitch-red hover:text-white transition-all"
                >
                  {t('header.confirmForget')}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* 관리자 토큰 등록 모달 */}
      <AnimatePresence>
        {showTokenInput && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center bg-void-black/80 backdrop-blur-sm px-4 pb-[env(safe-area-inset-bottom)]"
            onClick={() => setShowTokenInput(false)}
          >
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="border border-ink/10 bg-void-black max-w-sm w-full p-6 sm:p-8 mb-4 sm:mb-0"
            >
              <h3 className="font-mono text-xs text-ink uppercase tracking-wider mb-4">
                {t('header.registerAdmin')}
              </h3>

              <input
                type="text"
                value={tokenValue}
                onChange={(e) => setTokenValue(e.target.value)}
                placeholder={t('header.adminTokenPlaceholder')}
                className="w-full px-4 py-3 bg-transparent border border-ink/10 text-ink font-mono text-xs placeholder:text-ghost-grey/30 focus:border-signal-green/50 focus:outline-none mb-4"
                autoFocus
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && tokenValue.trim()) {
                    onSaveAdminToken(tokenValue.trim());
                    setTokenValue('');
                    setShowTokenInput(false);
                  }
                }}
              />

              <div className="flex gap-3">
                <button
                  onClick={() => {
                    setTokenValue('');
                    setShowTokenInput(false);
                  }}
                  className="flex-1 min-h-[44px] px-4 py-2 border border-ink/10 text-ghost-grey font-mono text-xs uppercase tracking-wider"
                >
                  {t('header.cancel')}
                </button>
                <button
                  onClick={() => {
                    if (tokenValue.trim()) {
                      onSaveAdminToken(tokenValue.trim());
                      setTokenValue('');
                      setShowTokenInput(false);
                    }
                  }}
                  disabled={!tokenValue.trim()}
                  className="flex-1 min-h-[44px] px-4 py-2 border border-signal-green text-signal-green font-mono text-xs uppercase tracking-wider hover:bg-signal-green hover:text-void-black transition-all disabled:opacity-30"
                >
                  {t('header.confirmRegister')}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
