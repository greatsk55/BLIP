'use client';

import { useState, useCallback, type KeyboardEvent } from 'react';
import { motion } from 'framer-motion';
import { Lock } from 'lucide-react';
import { useTranslations } from 'next-intl';

interface PasswordEntryProps {
  onSubmit: (password: string) => void;
  error?: string | null;
  loading?: boolean;
}

export default function PasswordEntry({ onSubmit, error, loading }: PasswordEntryProps) {
  const t = useTranslations('Chat');
  const [password, setPassword] = useState('');

  const handleSubmit = useCallback(() => {
    if (password.trim() && !loading) {
      onSubmit(password.trim().toUpperCase());
    }
  }, [password, onSubmit, loading]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLInputElement>) => {
      if (e.key === 'Enter') {
        handleSubmit();
      }
    },
    [handleSubmit]
  );

  return (
    <div className="h-dvh bg-void-black flex items-center justify-center px-6 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-sm text-center"
      >
        <Lock className="w-8 h-8 text-signal-green/40 mx-auto mb-6" />

        <h1 className="font-mono text-sm text-ghost-grey uppercase tracking-[0.3em] mb-8">
          {t('join.title')}
        </h1>

        <input
          type="text"
          value={password}
          onChange={(e) => {
            const raw = e.target.value.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
            const formatted = raw.length > 4
              ? `${raw.slice(0, 4)}-${raw.slice(4, 8)}`
              : raw;
            setPassword(formatted);
          }}
          onKeyDown={handleKeyDown}
          placeholder="XXXX-XXXX"
          maxLength={9}
          autoFocus
          autoComplete="off"
          autoCorrect="off"
          autoCapitalize="characters"
          spellCheck={false}
          inputMode="text"
          className="w-full bg-transparent border-b-2 border-ink/10 focus:border-signal-green text-ink font-mono text-xl sm:text-2xl text-center tracking-[0.3em] py-4 outline-none transition-colors placeholder:text-ink/10"
        />

        {error && (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="mt-4 font-mono text-xs text-glitch-red uppercase tracking-wider"
          >
            {error}
          </motion.p>
        )}

        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={handleSubmit}
          disabled={!password.trim() || loading}
          className="mt-10 w-full min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider disabled:opacity-20 disabled:hover:bg-transparent disabled:hover:text-signal-green"
        >
          {loading ? '...' : t('join.connect')}
        </motion.button>
      </motion.div>
    </div>
  );
}
