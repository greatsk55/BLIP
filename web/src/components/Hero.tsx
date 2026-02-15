"use client";

import { useTranslations } from "next-intl";
import { motion } from "framer-motion";
import { useEffect, useState } from "react";
import { useRouter } from "@/i18n/navigation";
import { ArrowRight, Trash2 } from "lucide-react";
import { createRoom } from "@/lib/room/actions";

export default function Hero() {
  const t = useTranslations("Hero");
  const router = useRouter();
  const [textVisible, setTextVisible] = useState(true);
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Text vanish effect loop
  useEffect(() => {
    const interval = setInterval(() => {
      setTextVisible((prev) => !prev);
    }, 4000);
    return () => clearInterval(interval);
  }, []);

  const handleCreateRoom = async () => {
    if (creating) return;
    setCreating(true);
    setError(null);
    const result = await createRoom();
    if ('error' in result) {
      setError(result.error === 'TOO_MANY_REQUESTS' ? t("rateLimited") : t("createFailed"));
      setCreating(false);
      return;
    }
    router.push(`/room/${result.roomId}#p=${encodeURIComponent(result.password)}`);
  };

  return (
    <section className="min-h-screen flex flex-col items-center justify-center text-center px-4 relative overflow-hidden">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--color-signal-green)_0%,_transparent_10%)] opacity-10 blur-3xl" />
      
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

      <div className="absolute bottom-10 left-1/2 -translate-x-1/2 animate-bounce opacity-20">
        <span className="text-xs font-mono text-zinc-500 dark:text-white">SCROLL_TO_DECRYPT</span>
      </div>
    </section>
  );
}
