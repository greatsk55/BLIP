'use client';

import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { useRouter } from 'next/navigation';

interface RoomDestroyedOverlayProps {
  reason?: 'destroyed' | 'full';
}

export default function RoomDestroyedOverlay({ reason = 'destroyed' }: RoomDestroyedOverlayProps) {
  const t = useTranslations('Chat');
  const router = useRouter();

  const ns = reason === 'full' ? 'roomFull' : 'destroyed';
  const statusLabel = reason === 'full' ? 'CHANNEL_FULL' : 'CHANNEL_DESTROYED';

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.5 }}
      className="fixed inset-0 z-[90] bg-void-black flex flex-col items-center justify-center px-6 text-center pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]"
    >
      <motion.p
        initial={{ opacity: 0, filter: 'blur(10px)' }}
        animate={{ opacity: 1, filter: 'blur(0px)' }}
        transition={{ delay: 0.5, duration: 1 }}
        className="font-mono text-xs text-glitch-red tracking-[0.5em] uppercase mb-8"
      >
        {statusLabel}
      </motion.p>

      <motion.h1
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1, duration: 1 }}
        className="font-sans text-2xl md:text-4xl font-bold text-ink mb-4"
      >
        {t(`${ns}.title`)}
      </motion.h1>

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.5, duration: 1 }}
        className="font-mono text-sm text-ghost-grey mb-12"
      >
        {t(`${ns}.subtitle`)}
      </motion.p>

      <motion.button
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 2.5 }}
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        onClick={() => router.push('/')}
        className="min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider"
      >
        {t(`${ns}.newChat`)}
      </motion.button>
    </motion.div>
  );
}
