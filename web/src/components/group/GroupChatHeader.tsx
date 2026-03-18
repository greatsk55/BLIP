'use client';

import { useState } from 'react';
import { ShieldCheck, LogOut, Users, FileText, Lock, Unlock, Bomb, Menu } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { ThemeToggle } from '@/components/ThemeToggle';
import TermsModal from '@/components/chat/TermsModal';

interface GroupChatHeaderProps {
  roomId: string;
  title: string;
  participantCount: number;
  isAdmin: boolean;
  onLeave: () => void;
  onToggleSidebar: () => void;
  onLock: () => void;
  onUnlock: () => void;
  onDestroy: () => void;
}

export default function GroupChatHeader({
  roomId,
  title,
  participantCount,
  isAdmin,
  onLeave,
  onToggleSidebar,
  onLock,
  onUnlock,
  onDestroy,
}: GroupChatHeaderProps) {
  const t = useTranslations('Group');
  const tc = useTranslations('Chat');
  const [termsOpen, setTermsOpen] = useState(false);
  const [showAdminMenu, setShowAdminMenu] = useState(false);

  return (
    <>
      <header className="sticky top-0 z-50 h-14 flex items-center justify-between px-4 bg-void-black/80 backdrop-blur-md border-b border-ink/5 pt-[env(safe-area-inset-top)]">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-1.5">
            <ShieldCheck className="w-4 h-4 text-signal-green/60" />
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-signal-green opacity-40" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-signal-green" />
            </span>
          </div>

          <div className="flex flex-col">
            <span className="font-mono text-xs text-ink truncate max-w-[120px] sm:max-w-[200px]">
              {title || `#${roomId.slice(0, 6)}`}
            </span>
            <span className="font-mono text-[10px] text-ghost-grey/50">
              #{roomId.slice(0, 6)}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-1">
          {/* 참여자 수 + 사이드바 토글 */}
          <button
            onClick={onToggleSidebar}
            className="flex items-center gap-1.5 min-w-[44px] min-h-[44px] justify-center text-ink/40 hover:text-ink/70 transition-colors"
          >
            <Users className="w-3.5 h-3.5" />
            <span className="font-mono text-xs">{participantCount}</span>
          </button>

          {/* 관리자 메뉴 */}
          {isAdmin && (
            <div className="relative">
              <button
                onClick={() => setShowAdminMenu(!showAdminMenu)}
                className="flex items-center min-w-[44px] min-h-[44px] justify-center text-glitch-red/50 hover:text-glitch-red transition-colors"
              >
                <Menu className="w-4 h-4" />
              </button>

              {showAdminMenu && (
                <div className="absolute right-0 top-full mt-1 bg-void-black border border-ink/10 py-1 min-w-[160px] z-50">
                  <button
                    onClick={() => { onLock(); setShowAdminMenu(false); }}
                    className="w-full flex items-center gap-2 px-4 py-2.5 font-mono text-xs text-ink/70 hover:bg-ink/5 transition-colors"
                  >
                    <Lock className="w-3.5 h-3.5" />
                    {t('admin.lock')}
                  </button>
                  <button
                    onClick={() => { onUnlock(); setShowAdminMenu(false); }}
                    className="w-full flex items-center gap-2 px-4 py-2.5 font-mono text-xs text-ink/70 hover:bg-ink/5 transition-colors"
                  >
                    <Unlock className="w-3.5 h-3.5" />
                    {t('admin.unlock')}
                  </button>
                  <div className="border-t border-ink/5 my-1" />
                  <button
                    onClick={() => {
                      if (confirm(t('admin.destroyConfirm'))) {
                        onDestroy();
                      }
                      setShowAdminMenu(false);
                    }}
                    className="w-full flex items-center gap-2 px-4 py-2.5 font-mono text-xs text-glitch-red hover:bg-glitch-red/10 transition-colors"
                  >
                    <Bomb className="w-3.5 h-3.5" />
                    {t('admin.destroy')}
                  </button>
                </div>
              )}
            </div>
          )}

          <button
            onClick={() => setTermsOpen(true)}
            className="flex items-center min-w-[44px] min-h-[44px] justify-center text-ink/40 hover:text-ink/70 transition-colors"
          >
            <FileText className="w-3.5 h-3.5" />
          </button>

          <ThemeToggle />

          <button
            onClick={onLeave}
            className="flex items-center gap-1.5 text-glitch-red/70 hover:text-glitch-red hover:bg-glitch-red/10 min-w-[44px] min-h-[44px] justify-center px-3 -mr-3 transition-colors"
          >
            <LogOut className="w-4 h-4" />
            <span className="hidden md:inline font-mono text-xs uppercase tracking-wider">
              {tc('header.exit')}
            </span>
          </button>
        </div>
      </header>

      <TermsModal isOpen={termsOpen} onClose={() => setTermsOpen(false)} />
    </>
  );
}
