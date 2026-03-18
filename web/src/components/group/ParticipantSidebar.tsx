'use client';

import { motion, AnimatePresence } from 'framer-motion';
import { X, Crown, UserX, Ban } from 'lucide-react';
import { useTranslations } from 'next-intl';
import type { GroupPresenceUser } from '@/hooks/useGroupChat';

interface ParticipantSidebarProps {
  isOpen: boolean;
  participants: GroupPresenceUser[];
  myId: string;
  isAdmin: boolean;
  onClose: () => void;
  onKick: (userId: string) => void;
  onBan: (userId: string) => void;
}

export default function ParticipantSidebar({
  isOpen,
  participants,
  myId,
  isAdmin,
  onClose,
  onKick,
  onBan,
}: ParticipantSidebarProps) {
  const t = useTranslations('Group');

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* 오버레이 */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-void-black/50 z-40 md:hidden"
          />

          {/* 사이드바 */}
          <motion.div
            initial={{ x: '100%' }}
            animate={{ x: 0 }}
            exit={{ x: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 200 }}
            className="absolute right-0 top-0 bottom-0 w-64 bg-void-black border-l border-ink/10 z-50 flex flex-col"
          >
            <div className="flex items-center justify-between px-4 h-14 border-b border-ink/5">
              <span className="font-mono text-xs text-ghost-grey uppercase tracking-widest">
                {t('sidebar.title')} ({participants.length})
              </span>
              <button
                onClick={onClose}
                className="min-w-[44px] min-h-[44px] flex items-center justify-center text-ink/40 hover:text-ink/70 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto py-2">
              {participants.map((user) => (
                <div
                  key={user.userId}
                  className="flex items-center justify-between px-4 py-3 hover:bg-ink/[0.03] transition-colors"
                >
                  <div className="flex items-center gap-2">
                    <span className="relative flex h-2 w-2">
                      <span className="relative inline-flex rounded-full h-2 w-2 bg-signal-green" />
                    </span>
                    <span className="font-mono text-xs text-ink">
                      {user.username}
                      {user.userId === myId && (
                        <span className="text-ghost-grey/50 ml-1">(you)</span>
                      )}
                    </span>
                    {user.isAdmin && (
                      <Crown className="w-3 h-3 text-yellow-500/70" />
                    )}
                  </div>

                  {/* 관리자 전용: 강퇴/밴 */}
                  {isAdmin && user.userId !== myId && (
                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => onKick(user.userId)}
                        title={t('sidebar.kick')}
                        className="min-w-[32px] min-h-[32px] flex items-center justify-center text-ink/30 hover:text-glitch-red transition-colors"
                      >
                        <UserX className="w-3.5 h-3.5" />
                      </button>
                      <button
                        onClick={() => {
                          if (confirm(t('sidebar.banConfirm', { name: user.username }))) {
                            onBan(user.userId);
                          }
                        }}
                        title={t('sidebar.ban')}
                        className="min-w-[32px] min-h-[32px] flex items-center justify-center text-ink/30 hover:text-glitch-red transition-colors"
                      >
                        <Ban className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
