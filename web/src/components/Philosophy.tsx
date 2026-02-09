"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";

export default function Philosophy() {
  const t = useTranslations("Philosophy");

  return (
    <section className="py-40 px-4 bg-void-black text-center flex flex-col items-center justify-center">
      <motion.p
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ duration: 1 }}
        className="text-2xl md:text-4xl font-bold text-ink mb-4 font-sans"
      >
        "{t("text1")}"
      </motion.p>
      <motion.p
        initial={{ opacity: 0 }}
        whileInView={{ opacity: 1 }}
        viewport={{ once: true }}
        transition={{ delay: 0.5, duration: 1 }}
        className="text-lg md:text-2xl text-ghost-grey font-mono"
      >
        {t("text2")}
      </motion.p>
    </section>
  );
}
