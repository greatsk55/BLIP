"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { Package, Truck, Database } from "lucide-react";
import Footer from "@/components/Footer";

export default function HowItWorksPage() {
  const t = useTranslations("HowItWorks");

  const steps = [
    { key: "1", icon: <Package className="w-8 h-8" /> },
    { key: "2", icon: <Truck className="w-8 h-8" /> },
    { key: "3", icon: <Database className="w-8 h-8" /> },
  ];

  return (
    <>
    <div className="min-h-screen pt-32 pb-20 px-4 md:px-8 max-w-7xl mx-auto flex flex-col items-center">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="mb-32 text-center"
      >
        <span className="text-signal-green font-mono text-sm tracking-widest uppercase mb-6 block">
          {t("subtitle")}
        </span>
        <h1 className="text-4xl md:text-7xl font-bold leading-tight mb-8">
          {t.rich("title", { br: () => <br /> })}
        </h1>
        <p className="text-zinc-500 dark:text-zinc-400 max-w-2xl mx-auto text-lg md:text-xl">
          {t("description")}
        </p>
      </motion.div>

      <div className="w-full max-w-5xl relative">
        {/* Timeline Line (Desktop) */}
        <div className="absolute top-1/2 left-0 w-full h-[1px] bg-zinc-200 dark:bg-white/10 hidden md:block -z-10 transform -translate-y-1/2" />

        <div className="grid grid-cols-1 md:grid-cols-3 gap-16 md:gap-8">
          {steps.map((step, index) => (
            <motion.div
              key={step.key}
              initial={{ opacity: 0, y: 50 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: index * 0.2 }}
              className="relative group bg-white dark:bg-void-black border border-zinc-300 dark:border-white/10 p-8 pt-12 rounded-lg hover:border-signal-green/50 dark:hover:border-signal-green/50 transition-all duration-300 shadow-sm hover:shadow-md"
            >
              {/* Icon Badge */}
              <div className="absolute -top-10 left-1/2 md:left-8 transform -translate-x-1/2 md:translate-x-0 w-20 h-20 bg-white dark:bg-void-black border border-zinc-200 dark:border-white/10 rounded-full flex items-center justify-center text-signal-green group-hover:scale-110 transition-transform duration-300 shadow-sm">
                {step.icon}
              </div>

              <span className="font-mono text-6xl font-bold text-zinc-100 dark:text-white/5 absolute top-4 right-4 group-hover:text-signal-green/10 transition-colors">
                {step.key}
              </span>

              <h3 className="text-2xl font-bold mb-4 mt-6 text-center md:text-left text-black dark:text-white">
                {t(`steps.${step.key}.title`)}
              </h3>
              <p className="text-zinc-700 dark:text-zinc-400 leading-relaxed text-center md:text-left">
                {t(`steps.${step.key}.description`)}
              </p>
            </motion.div>
          ))}
        </div>
      </div>

      <motion.div
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        className="mt-32 text-center"
      >
        <a
          href="https://github.com/greatsk55/BLIP"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-3 px-8 py-4 border border-zinc-800 dark:border-white/20 hover:bg-zinc-100 dark:hover:bg-white/10 transition-all rounded-full font-mono text-sm tracking-wider"
        >
          {t("opensource")} &rarr;
        </a>
      </motion.div>
    </div>
    <Footer />
    </>
  );
}
