"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";

export default function Problem() {
  const t = useTranslations("Problem");

  return (
    <section className="py-24 px-4 bg-void-black border-t border-[var(--border-color)] transition-colors duration-300">
      <div className="max-w-4xl mx-auto text-center">
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="text-3xl md:text-5xl font-bold mb-8 text-ink font-sans"
        >
          {t("title")}
        </motion.h2>
        <motion.p
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2, duration: 0.8 }}
          className="text-lg md:text-xl text-ghost-grey font-mono leading-relaxed"
        >
          {t.rich("description", { br: () => <br /> })}
        </motion.p>
        
        {/* Visual Noise / Glitch placeholder */}
        <div className="mt-16 h-32 w-full max-w-lg mx-auto bg-zinc-100 [.dark_&]:bg-white/5 relative overflow-hidden flex items-center justify-center rounded-sm">
          <div className="absolute inset-0 bg-gradient-to-r from-transparent via-black/5 [.dark_&]:via-white/10 to-transparent w-1/2 animate-[shimmer_2s_infinite]" />
          <span className="font-mono text-xs text-glitch-red tracking-[0.5em] opacity-70">ERROR: DATA_PERSISTENCE_DETECTED</span>
        </div>
      </div>
    </section>
  );
}
