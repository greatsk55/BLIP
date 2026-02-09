'use client';

import { ShieldCheck, LogOut, Users } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { ThemeToggle } from '@/components/ThemeToggle';

interface ChatHeaderProps {
  roomId: string;
  peerConnected: boolean;
  onLeave: () => void;
}

export default function ChatHeader({
  roomId,
  peerConnected,
  onLeave,
}: ChatHeaderProps) {
  const t = useTranslations('Chat');
  const onlineCount = peerConnected ? 2 : 1;

  return (
    <header className="sticky top-0 z-50 h-14 flex items-center justify-between px-4 bg-void-black/80 backdrop-blur-md border-b border-ink/5 pt-[env(safe-area-inset-top)]">
      <div className="flex items-center gap-3">
        {/* E2EE 인디케이터 */}
        <div className="flex items-center gap-1.5">
          <ShieldCheck className="w-4 h-4 text-signal-green/60" />
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-signal-green opacity-40" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-signal-green" />
          </span>
        </div>

        {/* 방 ID */}
        <span className="font-mono text-xs text-ghost-grey tracking-widest">
          #{roomId.slice(0, 6)}
        </span>
      </div>

      <div className="flex items-center gap-2">
        {/* 접속자 수 */}
        <div className="flex items-center gap-1.5">
          <Users className="w-3.5 h-3.5 text-ink/40" />
          <span className="font-mono text-xs text-ink/60">{onlineCount}</span>
        </div>

        <ThemeToggle />

        {/* EXIT 버튼 - 최소 44px 터치 타겟 */}
        <button
          onClick={onLeave}
          className="flex items-center gap-1.5 text-glitch-red/70 hover:text-glitch-red active:text-glitch-red hover:bg-glitch-red/10 active:bg-glitch-red/10 min-w-[44px] min-h-[44px] justify-center px-3 -mr-3 transition-colors"
        >
          <LogOut className="w-4 h-4" />
          <span className="hidden md:inline font-mono text-xs uppercase tracking-wider">
            {t('header.exit')}
          </span>
        </button>
      </div>
    </header>
  );
}
