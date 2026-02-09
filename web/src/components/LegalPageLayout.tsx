"use client";

import { motion } from "framer-motion";
import Footer from "@/components/Footer";

interface LegalSection {
  title: string;
  content: string;
}

interface LegalPageLayoutProps {
  subtitle: string;
  title: string;
  lastUpdated: string;
  intro: string;
  sections: LegalSection[];
}

export default function LegalPageLayout({
  subtitle,
  title,
  lastUpdated,
  intro,
  sections,
}: LegalPageLayoutProps) {
  return (
    <>
    <div className="min-h-screen pt-40 pb-32 px-6 md:px-12 max-w-4xl mx-auto">
      {/* Hero */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.8 }}
        className="text-center mb-20"
      >
        <span className="text-signal-green font-mono text-sm md:text-md tracking-[0.3em] uppercase mb-8 block">
          {subtitle}
        </span>
        <h1 className="text-4xl md:text-6xl font-black leading-[1.1] tracking-tight mb-6">
          {title}
        </h1>
        <p className="font-mono text-xs text-ghost-grey tracking-wider">
          {lastUpdated}
        </p>
        <div className="w-24 h-1 bg-signal-green mx-auto mt-8 rounded-full" />
      </motion.div>

      {/* Intro */}
      <motion.p
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="text-lg md:text-xl text-zinc-500 dark:text-zinc-400 leading-relaxed font-light mb-16 text-center max-w-2xl mx-auto"
      >
        {intro}
      </motion.p>

      {/* Sections */}
      <div className="space-y-12">
        {sections.map((section, index) => (
          <motion.section
            key={index}
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true, margin: "-50px" }}
            transition={{ duration: 0.5, delay: index * 0.05 }}
            className="border-b border-white/5 pb-12 last:border-b-0"
          >
            <div className="flex items-start gap-4 mb-4">
              <span className="font-mono text-signal-green text-sm mt-1.5 shrink-0">
                {String(index + 1).padStart(2, "0")}
              </span>
              <h2 className="text-xl md:text-2xl font-bold">
                {section.title}
              </h2>
            </div>
            <p className="text-base md:text-lg text-zinc-500 dark:text-zinc-400 leading-relaxed font-light pl-10 md:pl-12">
              {section.content}
            </p>
          </motion.section>
        ))}
      </div>
    </div>
    <Footer />
    </>
  );
}
