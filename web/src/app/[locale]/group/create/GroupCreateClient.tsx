'use client';

import { useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { useRouter } from '@/i18n/navigation';
import { Users, ArrowRight } from 'lucide-react';
import { createGroupRoom } from '@/lib/group/actions';
import { ThemeToggle } from '@/components/ThemeToggle';
import TermsModal from '@/components/chat/TermsModal';

export default function GroupCreateClient() {
  const t = useTranslations('Group');
  const tc = useTranslations('Chat');
  const router = useRouter();
  const [title, setTitle] = useState('');
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [termsAgreed, setTermsAgreed] = useState(false);
  const [termsError, setTermsError] = useState(false);
  const [termsOpen, setTermsOpen] = useState(false);

  const handleCreate = useCallback(async () => {
    if (creating) return;
    if (!termsAgreed) {
      setTermsError(true);
      return;
    }
    setCreating(true);
    setError(null);

    const result = await createGroupRoom(title.trim() || 'Untitled Group');

    if ('error' in result) {
      setError(result.error === 'TOO_MANY_REQUESTS' ? t('create.rateLimited') : t('create.failed'));
      setCreating(false);
      return;
    }

    // URL fragment로 비밀번호+관리자토큰 전달
    router.push(
      `/group/${result.roomId}#p=${encodeURIComponent(result.password)}&a=${encodeURIComponent(result.adminToken)}`
    );
  }, [creating, termsAgreed, title, router, t]);

  return (
    <div className="min-h-dvh bg-void-black flex items-center justify-center px-6 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <div className="fixed top-4 right-4 z-50">
        <ThemeToggle />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-md text-center"
      >
        <Users className="w-10 h-10 text-signal-green/40 mx-auto mb-6" />

        <h1 className="font-mono text-sm text-ghost-grey uppercase tracking-[0.3em] mb-8">
          {t('create.title')}
        </h1>

        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder={t('create.titlePlaceholder')}
          maxLength={50}
          autoFocus
          className="w-full bg-transparent border-b-2 border-ink/10 focus:border-signal-green text-ink font-mono text-lg text-center tracking-wider py-4 outline-none transition-colors placeholder:text-ink/20 mb-10"
        />

        {/* 이용약관 */}
        <div className="flex items-center justify-center gap-2 mb-6 select-none">
          <input
            id="terms-agree"
            type="checkbox"
            checked={termsAgreed}
            onChange={() => { setTermsAgreed(!termsAgreed); setTermsError(false); }}
            className="w-4 h-4 accent-signal-green cursor-pointer"
          />
          <label htmlFor="terms-agree" className="font-mono text-xs text-ghost-grey cursor-pointer">
            {tc.rich('terms.agree', {
              terms: (chunks) => (
                <button
                  type="button"
                  onClick={(e) => { e.preventDefault(); e.stopPropagation(); setTermsOpen(true); }}
                  className="underline text-signal-green hover:text-signal-green/80 transition-colors"
                >
                  {chunks}
                </button>
              ),
            })}
          </label>
        </div>

        {termsError && (
          <motion.p
            initial={{ opacity: 0, y: -5 }}
            animate={{ opacity: 1, y: 0 }}
            className="mb-4 text-xs font-mono text-red-400"
          >
            {tc('terms.mustAgree')}
          </motion.p>
        )}

        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={handleCreate}
          disabled={creating}
          className="group w-full min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider disabled:opacity-50"
        >
          <span className="flex items-center justify-center gap-2">
            {creating ? 'CREATING...' : t('create.cta')}
            <ArrowRight className="w-4 h-4" />
          </span>
        </motion.button>

        {error && (
          <motion.p
            initial={{ opacity: 0, y: -5 }}
            animate={{ opacity: 1, y: 0 }}
            className="mt-4 text-sm font-mono text-red-400"
          >
            {error}
          </motion.p>
        )}

        <motion.a
          href="/"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.5 }}
          transition={{ delay: 0.5 }}
          className="inline-block mt-8 font-mono text-xs text-ghost-grey hover:text-ink transition-colors uppercase tracking-wider"
        >
          ← {t('create.backHome')}
        </motion.a>
      </motion.div>

      <TermsModal isOpen={termsOpen} onClose={() => setTermsOpen(false)} />
    </div>
  );
}
