"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { Quote } from "lucide-react";
import Footer from "@/components/Footer";

export default function AboutPage() {
  const t = useTranslations("About");

  return (
    <>
    <div className="min-h-screen pt-40 pb-32 px-6 md:px-12 max-w-7xl mx-auto flex flex-col items-center justify-center">

      {/* Hero Section */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="max-w-4xl text-center mb-32"
      >
        <span className="text-signal-green font-mono text-sm md:text-md tracking-[0.3em] uppercase mb-8 block">
          {t("subtitle")}
        </span>
        <h1 className="text-5xl md:text-7xl lg:text-8xl font-black leading-[1.1] tracking-tight mb-8">
          {t.rich("title", { br: () => <br /> })}
        </h1>
        <div className="w-24 h-1 bg-signal-green mx-auto mt-12 rounded-full" />
      </motion.div>

      {/* Content Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-16 md:gap-32 w-full max-w-6xl">
        
        {/* Section 1 */}
        <motion.section
          initial={{ opacity: 0, x: -50 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6 }}
        >
          <div className="flex items-center gap-4 mb-6">
            <span className="font-mono text-signal-green text-xl">01</span>
            <h2 className="text-3xl md:text-4xl font-bold">
              {t("section1.title")}
            </h2>
          </div>
          <p className="text-lg md:text-xl text-zinc-700 dark:text-zinc-400 leading-relaxed font-light">
            {t("section1.description")}
          </p>
        </motion.section>

        {/* Section 2 */}
        <motion.section
          initial={{ opacity: 0, x: 50 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          <div className="flex items-center gap-4 mb-6">
            <span className="font-mono text-signal-green text-xl">02</span>
            <h2 className="text-3xl md:text-4xl font-bold">
              {t("section2.title")}
            </h2>
          </div>
          <p className="text-lg md:text-xl text-zinc-700 dark:text-zinc-400 leading-relaxed font-light">
            {t("section2.description")}
          </p>
        </motion.section>
      </div>

      {/* Closing Statement */}
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        whileInView={{ opacity: 1, scale: 1 }}
        viewport={{ once: true }}
        transition={{ duration: 0.8 }}
        className="mt-40 text-center max-w-2xl relative"
      >
        <Quote className="absolute -top-12 -left-12 w-24 h-24 text-black/5 dark:text-white/5 -z-10" />
        <p className="text-3xl md:text-5xl font-serif italic text-zinc-800 dark:text-zinc-200 leading-tight">
          "{t("closing")}"
        </p>
      </motion.div>
    </div>
    <Footer />
    </>
  );
}
