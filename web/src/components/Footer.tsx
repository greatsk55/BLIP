"use client";

import { useTranslations } from "next-intl";
import { useState } from "react";
import { Coffee } from "lucide-react";
import { Link } from "@/i18n/navigation";
import { ThemeToggle } from "@/components/ThemeToggle";

export default function Footer() {
  const t = useTranslations("Footer");
  const [hovered, setHovered] = useState(false);

  return (
    <footer className="py-12 px-4 border-t border-[var(--border-color)] text-center bg-void-black transition-colors duration-300">
      <div 
        className="inline-block cursor-help"
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
      >
        <span 
          className={`font-mono text-xs transition-colors duration-500 ${hovered ? 'text-transparent blur-sm' : 'text-zinc-500 [.dark_&]:text-zinc-400'}`}
        >
          {t("easterEgg")}
        </span>
      </div>
      <div className="mb-4 flex justify-center flex-wrap gap-x-8 gap-y-3 text-sm font-light text-zinc-600 [.dark_&]:text-ghost-grey">
        <Link href="/" className="hover:text-signal-green transition-colors font-mono font-bold tracking-wider">
          BLIP
        </Link>
        <Link href="/about" className="hover:text-ink transition-colors">
          {t("links.about")}
        </Link>
        <Link href="/how-it-works" className="hover:text-ink transition-colors">
          {t("links.howItWorks")}
        </Link>
        <Link href="/faq" className="hover:text-ink transition-colors">
          {t("links.faq")}
        </Link>
      </div>
      <div className="mb-8 flex justify-center gap-6 text-xs font-mono text-zinc-500 [.dark_&]:text-zinc-600 tracking-wider">
        <Link href="/privacy" className="hover:text-ink transition-colors">
          {t("links.privacy")}
        </Link>
        <span className="text-zinc-300 [.dark_&]:text-zinc-800">|</span>
        <Link href="/terms" className="hover:text-ink transition-colors">
          {t("links.terms")}
        </Link>
        <span className="text-zinc-300 [.dark_&]:text-zinc-800">|</span>
        <Link href="/updates" className="hover:text-signal-green transition-colors">
          {t("links.updates")}
        </Link>
      </div>
      <div className="mt-12 mb-8">
        <a 
          href="https://buymeacoffee.com/ryokai" 
          target="_blank" 
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 group px-4 py-2 border border-zinc-300 [.dark_&]:border-white/10 hover:border-signal-green/50 bg-white [.dark_&]:bg-white/5 hover:bg-signal-green/5 transition-all duration-300 rounded-sm"
        >
          <Coffee className="w-4 h-4 text-zinc-600 [.dark_&]:text-zinc-500 group-hover:text-signal-green transition-colors duration-300" />
          <span className="text-[10px] text-zinc-600 [.dark_&]:text-zinc-500 group-hover:text-signal-green uppercase font-mono tracking-widest transition-colors duration-300">
            {t("supportProtocol")}
          </span>
        </a>
      </div>
      <div className="mt-4 flex flex-col items-center gap-4">
        <ThemeToggle />
        <div className="flex justify-center gap-4 text-[10px] text-zinc-500 [.dark_&]:text-zinc-600 uppercase font-mono tracking-widest">
          <span>© 2026 BLIP PROTOCOL</span>
          <span>NO RIGHTS RESERVED</span>
        </div>
      </div>
    </footer>
  );
}
