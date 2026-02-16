"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { Zap, EyeOff, Bomb, Code, Timer, ShieldAlert } from "lucide-react";

export default function Solution() {
  const t = useTranslations("Solution");

  const features = [
    {
      key: "friction",
      icon: <Zap className="w-8 h-8 text-signal-green" />,
    },
    {
      key: "anonymity",
      icon: <EyeOff className="w-8 h-8 text-signal-green" />,
    },
    {
      key: "destruction",
      icon: <Bomb className="w-8 h-8 text-glitch-red" />,
    },
    {
      key: "autoshred",
      icon: <Timer className="w-8 h-8 text-signal-green" />,
    },
    {
      key: "captureGuard",
      icon: <ShieldAlert className="w-8 h-8 text-glitch-red" />,
    },
    {
      key: "opensource",
      icon: <Code className="w-8 h-8 text-zinc-800 [.dark_&]:text-white" />,
    },
  ];

  return (
    <section className="py-32 px-4 bg-void-black relative transition-colors duration-300">
      <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-12">
        {features.map((feature, index) => (
          <motion.div
            key={feature.key}
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: index * 0.2, duration: 0.8 }}
            className="flex flex-col items-center text-center p-8 border border-[var(--border-color)] hover:border-zinc-300 [.dark_&]:hover:border-white/10 transition-all duration-300 bg-white [.dark_&]:bg-white/[0.02] rounded-lg shadow-sm hover:shadow-md"
          >
            <div className="mb-6 p-4 rounded-full bg-zinc-50 [.dark_&]:bg-white/5 border border-zinc-100 [.dark_&]:border-white/5">
              {feature.icon}
            </div>
            <h3 className="text-xl font-bold text-ink mb-4 font-sans uppercase tracking-wider">
              {t(`${feature.key}.title`)}
            </h3>
            <p className="text-ghost-grey font-mono text-sm leading-relaxed">
              {t(`${feature.key}.description`)}
            </p>
          </motion.div>
        ))}
      </div>
    </section>
  );
}
