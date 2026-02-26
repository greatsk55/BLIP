"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { Smartphone, Zap, Bell, Rocket } from "lucide-react";
import Footer from "@/components/Footer";

const VERSION_ICONS = [
  <Smartphone key="smartphone" className="w-5 h-5" />,
  <Zap key="zap" className="w-5 h-5" />,
  <Bell key="bell" className="w-5 h-5" />,
  <Rocket key="rocket" className="w-5 h-5" />,
];

const VERSION_COUNT = 4;

export default function UpdatesPage() {
  const t = useTranslations("Changelog");

  return (
    <>
      <div className="min-h-screen pt-32 pb-20 px-4 md:px-8 max-w-4xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8 }}
          className="text-center mb-20"
        >
          <span className="text-signal-green font-mono text-sm tracking-widest uppercase mb-6 block">
            {t("subtitle")}
          </span>
          <h1 className="text-4xl md:text-7xl font-bold leading-tight mb-6">
            {t("title")}
          </h1>
          <p className="text-zinc-500 dark:text-zinc-400 max-w-xl mx-auto text-lg">
            {t("description")}
          </p>
        </motion.div>

        {/* Timeline */}
        <div className="relative">
          {/* Vertical line */}
          <div className="absolute left-6 md:left-8 top-0 bottom-0 w-px bg-zinc-200 dark:bg-white/10" />

          <div className="space-y-16">
            {Array.from({ length: VERSION_COUNT }, (_, i) => {
              const key = String(i + 1);
              const changeKeys = Object.keys(
                t.raw(`versions.${key}.changes`) as Record<string, string>
              );

              return (
                <motion.div
                  key={key}
                  initial={{ opacity: 0, x: -30 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, margin: "-50px" }}
                  transition={{ duration: 0.5, delay: i * 0.1 }}
                  className="relative pl-16 md:pl-20"
                >
                  {/* Timeline dot */}
                  <div className={`absolute left-0 w-12 md:w-16 h-12 md:h-16 rounded-full flex items-center justify-center border transition-colors ${
                    i === 0
                      ? "bg-signal-green/10 border-signal-green/30 text-signal-green"
                      : "bg-white dark:bg-void-black border-zinc-200 dark:border-white/10 text-zinc-400 dark:text-zinc-500"
                  }`}>
                    {VERSION_ICONS[i]}
                  </div>

                  {/* Version badge */}
                  <div className="flex items-center gap-3 mb-3">
                    <span className={`font-mono text-sm font-bold tracking-wider ${
                      i === 0 ? "text-signal-green" : "text-zinc-500 dark:text-zinc-400"
                    }`}>
                      {t(`versions.${key}.version`)}
                    </span>
                    {i === 0 && (
                      <span className="text-[10px] font-mono tracking-widest uppercase px-2 py-0.5 bg-signal-green/10 text-signal-green border border-signal-green/20 rounded-sm">
                        Latest
                      </span>
                    )}
                  </div>

                  {/* Date */}
                  <p className="font-mono text-xs text-zinc-400 dark:text-zinc-600 mb-4 tracking-wider">
                    {t(`versions.${key}.date`)}
                  </p>

                  {/* Card */}
                  <div className={`border rounded-lg p-6 md:p-8 transition-all duration-300 ${
                    i === 0
                      ? "border-signal-green/20 bg-signal-green/[0.03]"
                      : "border-zinc-200 dark:border-white/10 bg-white dark:bg-white/[0.02]"
                  }`}>
                    <h3 className="text-xl md:text-2xl font-bold mb-5">
                      {t(`versions.${key}.title`)}
                    </h3>

                    <ul className="space-y-3">
                      {changeKeys.map((changeKey) => (
                        <li
                          key={changeKey}
                          className="flex items-start gap-3 text-zinc-600 dark:text-zinc-400"
                        >
                          <span className="text-signal-green mt-1.5 text-xs shrink-0">&#9656;</span>
                          <span className="text-sm md:text-base leading-relaxed">
                            {t(`versions.${key}.changes.${changeKey}`)}
                          </span>
                        </li>
                      ))}
                    </ul>
                  </div>
                </motion.div>
              );
            })}
          </div>
        </div>

        {/* Footer CTA */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          className="mt-24 text-center"
        >
          <a
            href="https://github.com/greatsk55/BLIP"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-3 px-8 py-4 border border-zinc-800 dark:border-white/20 hover:bg-zinc-100 dark:hover:bg-white/10 transition-all rounded-full font-mono text-sm tracking-wider"
          >
            View on GitHub &rarr;
          </a>
        </motion.div>
      </div>
      <Footer />
    </>
  );
}
