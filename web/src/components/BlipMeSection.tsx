"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { Link2, Zap, MessageSquare, ArrowRight } from "lucide-react";
import { Link } from "@/i18n/navigation";

export default function BlipMeSection() {
  const t = useTranslations("BlipMeSection");

  const steps = [
    {
      key: "create",
      icon: <Link2 className="w-6 h-6 text-signal-green" />,
      number: "01",
    },
    {
      key: "share",
      icon: <Zap className="w-6 h-6 text-signal-green" />,
      number: "02",
    },
    {
      key: "connect",
      icon: <MessageSquare className="w-6 h-6 text-signal-green" />,
      number: "03",
    },
  ];

  return (
    <section className="py-32 px-4 bg-void-black relative overflow-hidden">
      {/* 배경 그레디언트 */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_var(--color-signal-green)_0%,_transparent_50%)] opacity-[0.03]" />

      <div className="max-w-4xl mx-auto relative">
        {/* 라벨 */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="flex justify-center mb-8"
        >
          <span className="font-mono text-[10px] text-signal-green/60 uppercase tracking-[0.4em] border border-signal-green/10 px-4 py-1.5">
            {t("label")}
          </span>
        </motion.div>

        {/* 헤드라인 */}
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.8 }}
          className="text-3xl md:text-5xl font-bold font-sans text-ink text-center mb-6 tracking-tight"
        >
          {t("title")}
        </motion.h2>

        {/* 서브카피 */}
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2, duration: 0.8 }}
          className="text-center text-ghost-grey font-mono text-sm md:text-base max-w-2xl mx-auto mb-16 leading-relaxed"
        >
          {t.rich("subtitle", { br: () => <br /> })}
        </motion.p>

        {/* 3단계 카드 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          {steps.map((step, index) => (
            <motion.div
              key={step.key}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.3 + index * 0.15, duration: 0.6 }}
              className="relative p-6 border border-[var(--border-color)] hover:border-signal-green/20 bg-white [.dark_&]:bg-white/[0.02] transition-all duration-300"
            >
              {/* 단계 번호 */}
              <span className="absolute top-4 right-4 font-mono text-[10px] text-signal-green/30 tracking-widest">
                {step.number}
              </span>
              <div className="mb-4 p-3 rounded-full bg-zinc-50 [.dark_&]:bg-white/5 border border-zinc-100 [.dark_&]:border-white/5 w-fit">
                {step.icon}
              </div>
              <h3 className="text-sm font-bold text-ink mb-2 font-sans uppercase tracking-wider">
                {t(`steps.${step.key}.title`)}
              </h3>
              <p className="text-ghost-grey font-mono text-xs leading-relaxed">
                {t(`steps.${step.key}.description`)}
              </p>
            </motion.div>
          ))}
        </div>

        {/* 연결선 시각 (모바일 숨김) */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.6, duration: 0.8 }}
          className="hidden md:flex justify-center items-center gap-2 mb-12"
        >
          <span className="font-mono text-[10px] text-ghost-grey/40 tracking-widest uppercase">
            {t("flow")}
          </span>
        </motion.div>

        {/* 하이라이트 */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5, duration: 0.8 }}
          className="border border-signal-green/10 bg-white [.dark_&]:bg-signal-green/[0.02] p-6 md:p-8 mb-16 text-center"
        >
          <p className="text-ghost-grey font-mono text-xs md:text-sm leading-relaxed">
            {t.rich("highlight", { br: () => <br />, strong: (chunks) => <span className="text-signal-green font-bold">{chunks}</span> })}
          </p>
        </motion.div>

        {/* CTA */}
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.6, duration: 0.8 }}
          className="flex justify-center"
        >
          <Link
            href="/blipme"
            className="group inline-flex items-center gap-3 px-8 py-4 border border-signal-green/30 hover:border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300"
          >
            <Zap className="w-4 h-4" />
            <span className="font-mono text-sm font-bold uppercase tracking-wider">
              {t("cta")}
            </span>
            <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
          </Link>
        </motion.div>
      </div>
    </section>
  );
}
