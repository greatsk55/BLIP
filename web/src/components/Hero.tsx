"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { useCallback, useEffect, useState } from "react";
import { useRouter } from "@/i18n/navigation";
import { ArrowRight, Trash2 } from "lucide-react";
import { createRoom } from "@/lib/room/actions";
import TermsModal from "@/components/chat/TermsModal";

export default function Hero() {
  const t = useTranslations("Hero");
  const tc = useTranslations("Chat");
  const router = useRouter();
  const [textVisible, setTextVisible] = useState(true);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [termsAgreed, setTermsAgreed] = useState(false);
  const [termsOpen, setTermsOpen] = useState(false);
  const [termsError, setTermsError] = useState(false);

  // Text vanish effect loop
  useEffect(() => {
    const interval = setInterval(() => {
      setTextVisible((prev) => !prev);
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  const handleCreateRoom = useCallback(async () => {
    if (creating) return;
    if (!termsAgreed) {
      setTermsError(true);
      return;
    }
    setCreating(true);
    setError(null);
    const result = await createRoom();
    if ('error' in result) {
      setError(result.error === 'TOO_MANY_REQUESTS' ? t("rateLimited") : t("createFailed"));
      setCreating(false);
      return;
    }
    router.push(`/room/${result.roomId}#p=${encodeURIComponent(result.password)}`);
  }, [creating, termsAgreed, router, t]);

  const handleTermsToggle = useCallback(() => {
    setTermsAgreed((prev) => !prev);
    setTermsError(false);
  }, []);

  return (
    <section className="min-h-screen flex flex-col items-center justify-center text-center px-4 relative overflow-hidden">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--color-signal-green)_0%,_transparent_10%)] opacity-10 blur-3xl pointer-events-none" />

      <motion.h1
        className="text-5xl md:text-8xl font-bold font-sans tracking-tighter mb-6 text-ink"
        initial={{ opacity: 0, filter: "blur(10px)" }}
        animate={{
          opacity: textVisible ? 1 : 0,
          filter: textVisible ? "blur(0px)" : "blur(20px)"
        }}
        transition={{ duration: 1.5, ease: "easeInOut" }}
      >
        {t("title")}
      </motion.h1>

      <motion.p
        className="text-lg md:text-2xl text-ghost-grey font-mono mb-12 max-w-2xl"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.5, duration: 1 }}
      >
        {t.rich("subtitle", { br: () => <br /> })}
      </motion.p>

      {/* 이용약관 동의 체크박스 */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.7, duration: 0.8 }}
        className="flex items-center gap-2 mb-6 select-none"
      >
        <input
          id="terms-agree"
          type="checkbox"
          checked={termsAgreed}
          onChange={handleTermsToggle}
          className="w-4 h-4 accent-signal-green cursor-pointer"
        />
        <label htmlFor="terms-agree" className="font-mono text-xs md:text-sm text-ghost-grey cursor-pointer">
          {tc.rich("terms.agree", {
            terms: (chunks) => (
              <button
                type="button"
                onClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  setTermsOpen(true);
                }}
                className="underline text-signal-green hover:text-signal-green/80 transition-colors"
              >
                {chunks}
              </button>
            ),
          })}
        </label>
      </motion.div>

      {termsError && (
        <motion.p
          initial={{ opacity: 0, y: -5 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-4 text-xs font-mono text-red-400"
        >
          {tc("terms.mustAgree")}
        </motion.p>
      )}

      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={handleCreateRoom}
        disabled={creating}
        className="group relative px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300 rounded-none overflow-hidden disabled:opacity-50"
      >
        <span className="relative z-10 flex items-center gap-2 font-mono text-sm md:text-base font-bold">
          {creating ? "CREATING..." : t("cta")}
          <Trash2 className="w-4 h-4 group-hover:hidden" />
          <ArrowRight className="w-4 h-4 hidden group-hover:block" />
        </span>
        <div className="absolute inset-0 bg-signal-green opacity-0 group-hover:opacity-10 transition-opacity duration-300 blur-md" />
      </motion.button>

      {error && (
        <motion.p
          initial={{ opacity: 0, y: -5 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-4 text-sm font-mono text-red-400"
        >
          {error}
        </motion.p>
      )}

      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 0.6 }}
        transition={{ delay: 1, duration: 1 }}
        className="mt-10 text-sm md:text-base text-ghost-grey font-sans font-light tracking-wide"
      >
        {t("linkShare")}
      </motion.p>

      <motion.a
        href="https://play.google.com/store/apps/details?id=com.bakkum.blip"
        target="_blank"
        rel="noopener noreferrer"
        initial={{ opacity: 0 }}
        animate={{ opacity: 0.7 }}
        whileHover={{ opacity: 1, scale: 1.05 }}
        transition={{ delay: 1.3, duration: 0.8 }}
        className="mt-6"
      >
        <img
          src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
          alt="Get it on Google Play"
          className="h-14 md:h-16"
        />
      </motion.a>

      <div className="absolute bottom-10 left-1/2 -translate-x-1/2 animate-bounce opacity-20">
        <span className="text-xs font-mono text-zinc-500 dark:text-white">SCROLL_TO_DECRYPT</span>
      </div>

      <TermsModal isOpen={termsOpen} onClose={() => setTermsOpen(false)} />
    </section>
  );
}
