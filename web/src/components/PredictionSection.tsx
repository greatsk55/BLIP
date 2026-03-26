'use client';

import { useTranslations } from 'next-intl';
import { motion } from 'framer-motion';
import { BarChart3, MessageSquare, ShieldCheck, ArrowRight, TrendingUp } from 'lucide-react';
import { Link } from '@/i18n/navigation';

export default function PredictionSection() {
  const t = useTranslations('Vote.landing');

  const features = [
    {
      key: 'feature1',
      icon: <BarChart3 className="w-6 h-6 text-signal-green" />,
      number: '01',
    },
    {
      key: 'feature2',
      icon: <MessageSquare className="w-6 h-6 text-signal-green" />,
      number: '02',
    },
    {
      key: 'feature3',
      icon: <ShieldCheck className="w-6 h-6 text-signal-green" />,
      number: '03',
    },
  ];

  // 정적 미리보기 카드 데이터
  const hotPredictions = [
    { question: 'BTC > $100k?', yesOdds: 1.85, noOdds: 2.10, pool: 2400 },
    { question: 'AI passes Turing?', yesOdds: 2.40, noOdds: 1.55, pool: 3200 },
    { question: 'Mars mission 2028?', yesOdds: 3.10, noOdds: 1.30, pool: 1800 },
  ];

  return (
    <section className="py-32 px-4 bg-void-black relative overflow-hidden">
      {/* 배경 그레디언트 */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom,_var(--color-signal-green)_0%,_transparent_50%)] opacity-[0.03]" />

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
            PREDICTION
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
          {t('title')}
        </motion.h2>

        {/* 서브카피 */}
        <motion.p
          initial={{ opacity: 0, y: 10 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2, duration: 0.8 }}
          className="text-center text-ghost-grey font-mono text-sm md:text-base max-w-2xl mx-auto mb-16 leading-relaxed"
        >
          {t('subtitle')}
        </motion.p>

        {/* 3가지 특징 카드 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          {features.map((feature, index) => (
            <motion.div
              key={feature.key}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.3 + index * 0.15, duration: 0.6 }}
              className="relative p-6 border border-[var(--border-color)] hover:border-signal-green/20 bg-white [.dark_&]:bg-white/[0.02] transition-all duration-300"
            >
              <span className="absolute top-4 right-4 font-mono text-[10px] text-signal-green/30 tracking-widest">
                {feature.number}
              </span>
              <div className="mb-4 p-3 rounded-full bg-zinc-50 [.dark_&]:bg-white/5 border border-zinc-100 [.dark_&]:border-white/5 w-fit">
                {feature.icon}
              </div>
              <h3 className="text-sm font-bold text-ink mb-2 font-sans uppercase tracking-wider">
                {t(`${feature.key}Title`)}
              </h3>
              <p className="text-ghost-grey font-mono text-xs leading-relaxed">
                {t(`${feature.key}Desc`)}
              </p>
            </motion.div>
          ))}
        </div>

        {/* 오늘의 핫 예측 미니 카드 */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.5, duration: 0.8 }}
          className="border border-signal-green/10 bg-white [.dark_&]:bg-signal-green/[0.02] p-6 md:p-8 mb-16"
        >
          <div className="flex items-center gap-2 mb-6">
            <TrendingUp className="w-4 h-4 text-signal-green" />
            <span className="font-mono text-xs text-signal-green uppercase tracking-wider font-bold">
              HOT PREDICTIONS
            </span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {hotPredictions.map((pred, index) => (
              <div
                key={index}
                className="p-4 border border-ghost-grey/10 rounded-lg hover:border-signal-green/20 transition-colors"
              >
                <p className="font-sans text-sm text-ink font-semibold mb-3">
                  {pred.question}
                </p>
                <div className="flex justify-between font-mono text-xs">
                  <span className="text-signal-green">{pred.yesOdds.toFixed(2)}x</span>
                  <span className="text-ghost-grey">{pred.pool.toLocaleString()} BP</span>
                  <span className="text-glitch-red">{pred.noOdds.toFixed(2)}x</span>
                </div>
              </div>
            ))}
          </div>
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
            href="/vote"
            className="group inline-flex items-center gap-3 px-8 py-4 border border-signal-green/30 hover:border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300"
          >
            <BarChart3 className="w-4 h-4" />
            <span className="font-mono text-sm font-bold uppercase tracking-wider">
              {t('cta')}
            </span>
            <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
          </Link>
        </motion.div>
      </div>
    </section>
  );
}
