'use client';

import { motion } from 'framer-motion';

interface SystemMessageProps {
  content: string;
}

export default function SystemMessage({ content }: SystemMessageProps) {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3 }}
      className="flex items-center justify-center py-3"
    >
      <span className="font-mono text-[10px] text-ghost-grey/50 uppercase tracking-[0.3em]">
        --- {content} ---
      </span>
    </motion.div>
  );
}
