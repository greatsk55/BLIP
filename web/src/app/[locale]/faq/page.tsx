"use client";

import { useTranslations } from "next-intl";
import { motion, AnimatePresence } from "framer-motion";
import { useState } from "react";
import { Plus, Minus } from "lucide-react";
import Footer from "@/components/Footer";

export default function FAQPage() {
  const t = useTranslations("FAQ");
  const [openIndex, setOpenIndex] = useState<number | null>(0); // Open first item by default

  const items = [1, 2, 3];

  return (
    <>
    <div className="min-h-screen pt-32 pb-20 px-4 md:px-8 max-w-4xl mx-auto">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.6 }}
        className="text-center mb-20"
      >
        <span className="text-signal-green font-mono text-sm tracking-widest uppercase mb-6 block">
          {t("subtitle")}
        </span>
        <h1 className="text-4xl md:text-6xl font-bold mb-6">
          {t("title")}
        </h1>
      </motion.div>

      <div className="space-y-6">
        {items.map((index) => (
          <motion.div 
            key={index}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: index * 0.1 }}
            className={`border rounded-lg overflow-hidden transition-all duration-300 ${
              openIndex === index 
                ? "border-signal-green/30 bg-signal-green/5 dark:bg-signal-green/5 shadow-lg" 
                : "border-zinc-300 dark:border-white/10 bg-white dark:bg-white/5 hover:border-zinc-400 dark:hover:border-white/20"
            }`}
          >
            <button
              onClick={() => setOpenIndex(openIndex === index ? null : index)}
              className="w-full px-8 py-6 flex items-center justify-between text-left"
            >
              <span className={`text-lg md:text-xl font-medium pr-8 transition-colors ${
                openIndex === index ? "text-signal-green" : "text-black dark:text-white"
              }`}>
                {t(`items.${index}.question`)}
              </span>
              <div className={`p-2 rounded-full transition-colors ${
                openIndex === index ? "bg-signal-green/10" : "bg-zinc-100 dark:bg-white/10"
              }`}>
                {openIndex === index ? (
                  <Minus className="w-5 h-5 text-signal-green" />
                ) : (
                  <Plus className="w-5 h-5 text-zinc-500 dark:text-zinc-400" />
                )}
              </div>
            </button>
            
            <AnimatePresence>
              {openIndex === index && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.3 }}
                >
                  <div className="px-8 pb-8 pt-2">
                    <p className="text-zinc-700 dark:text-zinc-400 leading-relaxed text-lg border-t border-zinc-200 dark:border-white/10 pt-6">
                      {t(`items.${index}.answer`)}
                    </p>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        ))}
      </div>
    </div>
    <Footer />
    </>
  );
}
