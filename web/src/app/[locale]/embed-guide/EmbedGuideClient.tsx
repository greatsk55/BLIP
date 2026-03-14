"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { Shield, Ban, UserX, Flame, Copy, Check } from "lucide-react";
import { useState, useCallback } from "react";
import Footer from "@/components/Footer";

const EMBED_URL = "https://blip-blip.vercel.app/embed";

const SNIPPET_BASIC = `<iframe
  src="${EMBED_URL}"
  width="400"
  height="600"
  style="border: none;"
  allow="clipboard-write"
></iframe>`;

const SNIPPET_CUSTOM = `<iframe
  src="${EMBED_URL}"
  width="100%"
  height="500"
  style="border: none; border-radius: 12px;"
  allow="clipboard-write"
></iframe>`;

const SNIPPET_EVENTS = `window.addEventListener('message', (e) => {
  if (e.origin !== '${EMBED_URL.replace('/embed', '')}') return;

  switch (e.data.type) {
    case 'blip:ready':
      // Widget loaded
      break;
    case 'blip:room-created':
      console.log('Room:', e.data.roomId);
      console.log('Share:', e.data.shareUrl);
      break;
    case 'blip:room-joined':
      console.log('Joined:', e.data.roomId);
      break;
    case 'blip:room-destroyed':
      console.log('Destroyed:', e.data.roomId);
      break;
  }
});`;

function CodeBlock({ code, language = "html" }: { code: string; language?: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = useCallback(async () => {
    await navigator.clipboard.writeText(code);
    setCopied(true);
    if (navigator.vibrate) navigator.vibrate(50);
    setTimeout(() => setCopied(false), 1500);
  }, [code]);

  return (
    <div className="relative group">
      <button
        onClick={handleCopy}
        className="absolute top-3 right-3 p-2 rounded bg-white/5 hover:bg-white/10 transition-colors z-10"
        aria-label="Copy code"
      >
        {copied ? (
          <Check className="w-4 h-4 text-signal-green" />
        ) : (
          <Copy className="w-4 h-4 text-ghost-grey" />
        )}
      </button>
      <pre className="bg-zinc-950 border border-white/10 rounded-lg p-5 pr-14 overflow-x-auto">
        <code className="font-mono text-sm text-zinc-300 leading-relaxed whitespace-pre">
          {code}
        </code>
      </pre>
      <span className="absolute bottom-2 right-3 font-mono text-[10px] text-ghost-grey/30 uppercase">
        {language}
      </span>
    </div>
  );
}

export default function EmbedGuideClient() {
  const t = useTranslations("EmbedGuide");

  const features = [
    { key: "E2E", icon: <Shield className="w-6 h-6" /> },
    { key: "NoAds", icon: <Ban className="w-6 h-6" /> },
    { key: "NoAccount", icon: <UserX className="w-6 h-6" /> },
    { key: "AutoDestroy", icon: <Flame className="w-6 h-6" /> },
  ];

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
            {t.rich("title", { br: () => <br /> })}
          </h1>
          <p className="text-zinc-500 dark:text-zinc-400 max-w-2xl mx-auto text-lg">
            {t("description")}
          </p>
        </motion.div>

        {/* Quick Start */}
        <motion.section
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-20"
        >
          <h2 className="text-2xl md:text-3xl font-bold mb-3">
            {t("quickStart")}
          </h2>
          <p className="text-ghost-grey mb-6">{t("quickStartDesc")}</p>
          <CodeBlock code={SNIPPET_BASIC} />
        </motion.section>

        {/* Customization */}
        <motion.section
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-20"
        >
          <h2 className="text-2xl md:text-3xl font-bold mb-6">
            {t("customize")}
          </h2>

          <div className="space-y-8">
            <div>
              <h3 className="font-mono text-sm text-signal-green uppercase tracking-wider mb-2">
                {t("customizeWidth")}
              </h3>
              <p className="text-ghost-grey text-sm mb-4">{t("customizeWidthDesc")}</p>
              <CodeBlock code={SNIPPET_CUSTOM} />
            </div>

            <div className="border border-white/10 rounded-lg p-6 bg-white/[0.02]">
              <h3 className="font-mono text-sm text-signal-green uppercase tracking-wider mb-2">
                {t("customizeDark")}
              </h3>
              <p className="text-ghost-grey text-sm">{t("customizeDarkDesc")}</p>
            </div>
          </div>
        </motion.section>

        {/* Events API */}
        <motion.section
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-20"
        >
          <h2 className="text-2xl md:text-3xl font-bold mb-3">
            {t("events")}
          </h2>
          <p className="text-ghost-grey mb-6">{t("eventsDesc")}</p>
          <CodeBlock code={SNIPPET_EVENTS} language="js" />

          <div className="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-3">
            {(["Ready", "Created", "Joined", "Destroyed"] as const).map((event) => (
              <div
                key={event}
                className="flex items-start gap-3 border border-white/10 rounded-lg p-4 bg-white/[0.02]"
              >
                <span className="font-mono text-xs text-signal-green whitespace-nowrap mt-0.5">
                  blip:{event.toLowerCase()}
                </span>
                <span className="text-ghost-grey text-sm">
                  {t(`event${event}`)}
                </span>
              </div>
            ))}
          </div>
        </motion.section>

        {/* Features */}
        <motion.section
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-20"
        >
          <h2 className="text-2xl md:text-3xl font-bold mb-8">
            {t("features")}
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
            {features.map((feature) => (
              <div
                key={feature.key}
                className="border border-white/10 rounded-lg p-6 bg-white/[0.02] hover:border-signal-green/30 transition-colors"
              >
                <div className="text-signal-green mb-4">{feature.icon}</div>
                <h3 className="font-bold text-lg mb-2">
                  {t(`feature${feature.key}`)}
                </h3>
                <p className="text-ghost-grey text-sm leading-relaxed">
                  {t(`feature${feature.key}Desc`)}
                </p>
              </div>
            ))}
          </div>
        </motion.section>

        {/* Live Demo */}
        <motion.section
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-10"
        >
          <h2 className="text-2xl md:text-3xl font-bold mb-3">
            {t("tryIt")}
          </h2>
          <p className="text-ghost-grey mb-8">{t("tryItDesc")}</p>
          <div className="flex justify-center">
            <div className="border border-white/10 rounded-lg overflow-hidden shadow-2xl">
              <iframe
                src="/embed"
                width="380"
                height="560"
                style={{ border: "none" }}
                allow="clipboard-write"
              />
            </div>
          </div>
        </motion.section>
      </div>
      <Footer />
    </>
  );
}
