'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { Link } from '@/i18n/navigation';
import { useRouter } from '@/i18n/navigation';
import { ThemeToggle } from '@/components/ThemeToggle';
import { Trash2, ArrowRight, Users, MessageCircle, Shield, Plus, ArrowLeft } from 'lucide-react';
import { getSavedRooms, removeSavedRoom, getRoomPassword, getAdminToken, type SavedRoom } from '@/lib/room/storage';

export default function MyRoomsClient() {
  const t = useTranslations('MyRooms');
  const router = useRouter();
  const [rooms, setRooms] = useState<SavedRoom[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [confirmTarget, setConfirmTarget] = useState<SavedRoom | null>(null);

  useEffect(() => {
    setRooms(getSavedRooms());
    setLoaded(true);
  }, []);

  const handleRemove = useCallback(() => {
    if (!confirmTarget) return;
    removeSavedRoom(confirmTarget.roomId);
    setRooms((prev) => prev.filter((r) => r.roomId !== confirmTarget.roomId));
    setConfirmTarget(null);
  }, [confirmTarget]);

  const handleOpenRoom = useCallback((room: SavedRoom) => {
    if (room.status !== 'active') return;
    const basePath = room.roomType === 'group' ? `/group/${room.roomId}` : `/room/${room.roomId}`;
    const password = getRoomPassword(room.roomId);

    // 비밀번호가 있으면 #k= fragment로 자동 입장
    const parts: string[] = [];
    if (password) parts.push(`k=${encodeURIComponent(password)}`);
    if (room.isAdmin && room.roomType === 'group') {
      const token = getAdminToken(room.roomId);
      if (token) parts.push(`a=${encodeURIComponent(token)}`);
    }

    if (parts.length > 0) {
      window.location.href = `${basePath}#${parts.join('&')}`;
    } else {
      router.push(basePath);
    }
  }, [router]);

  const getStatusColor = (status: string) => {
    if (status === 'active') return 'bg-signal-green';
    if (status === 'destroyed') return 'bg-glitch-red';
    return 'bg-ghost-grey/40';
  };

  return (
    <div className="min-h-dvh bg-void-black px-4 py-8 pb-[env(safe-area-inset-bottom)] pt-[calc(env(safe-area-inset-top)+2rem)]">
      <div className="fixed top-4 right-4 z-50 pt-[env(safe-area-inset-top)]">
        <ThemeToggle />
      </div>

      <div className="max-w-md mx-auto">
        {/* 헤더 */}
        <div className="flex items-center justify-between mb-8">
          <Link
            href="/"
            className="flex items-center gap-1 font-mono text-xs text-ghost-grey/60 hover:text-ink transition-colors uppercase tracking-wider"
          >
            <ArrowLeft className="w-3 h-3" />
            {t('backHome')}
          </Link>
          <h1 className="font-mono text-xs text-ghost-grey/60 uppercase tracking-[0.3em]">
            {t('title')}
          </h1>
        </div>

        {/* 로딩 */}
        {!loaded && (
          <div className="flex justify-center py-20">
            <div className="w-6 h-6 border-2 border-signal-green/30 border-t-signal-green rounded-full animate-spin" />
          </div>
        )}

        {/* 빈 상태 */}
        {loaded && rooms.length === 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center py-20"
          >
            <MessageCircle className="w-12 h-12 text-ghost-grey/20 mx-auto mb-4" />
            <p className="font-mono text-sm text-ghost-grey/60 mb-6">
              {t('empty')}
            </p>
            <button
              onClick={() => router.push('/')}
              className="px-6 py-3 border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300 font-mono text-xs uppercase tracking-wider"
            >
              <span className="flex items-center gap-2">
                <Plus className="w-3 h-3" />
                {t('createNew')}
              </span>
            </button>
          </motion.div>
        )}

        {/* 방 목록 */}
        {loaded && rooms.length > 0 && (
          <div className="space-y-2">
            <AnimatePresence mode="popLayout">
              {rooms.map((room) => (
                <motion.div
                  key={room.roomId}
                  layout
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  className="group flex items-center gap-3 p-4 border border-ink/5 hover:border-signal-green/20 transition-colors"
                >
                  <button
                    onClick={() => handleOpenRoom(room)}
                    disabled={room.status !== 'active'}
                    className="flex-1 min-w-0 flex items-center gap-3 text-left disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {/* 타입 아이콘 + 상태 */}
                    <div className="relative flex-shrink-0">
                      {room.roomType === 'group' ? (
                        <Users className="w-5 h-5 text-ghost-grey/60" />
                      ) : (
                        <MessageCircle className="w-5 h-5 text-ghost-grey/60" />
                      )}
                      <span
                        className={`absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full border-2 border-void-black ${getStatusColor(room.status)}`}
                      />
                    </div>

                    {/* 정보 */}
                    <div className="min-w-0 flex-1">
                      <span className="font-mono text-sm text-ink truncate block">
                        {room.roomType === 'group'
                          ? (room.title || `Group ${room.roomId.slice(0, 8)}`)
                          : (room.peerUsername || `Room ${room.roomId.slice(0, 8)}`)}
                      </span>
                      <span className="font-mono text-[10px] text-ghost-grey/50 block">
                        {room.roomType === 'group' ? t('typeGroup') : t('typeChat')}
                        {' · '}
                        {room.status === 'active' ? t('statusActive') : room.status === 'destroyed' ? t('statusDestroyed') : t('statusExpired')}
                        {' · '}
                        {formatTimeAgo(room.lastAccessedAt)}
                      </span>
                    </div>

                    {/* 관리자 뱃지 */}
                    {room.isAdmin && (
                      <Shield className="w-3 h-3 text-signal-green/60 shrink-0" />
                    )}
                    <ArrowRight className="w-3 h-3 text-ghost-grey/30 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity" />
                  </button>

                  <button
                    onClick={() => setConfirmTarget(room)}
                    className="p-1.5 text-ghost-grey/30 hover:text-glitch-red transition-colors flex-shrink-0"
                    aria-label={t('remove')}
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>

      {/* 삭제 확인 모달 */}
      <AnimatePresence>
        {confirmTarget && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 px-6"
            onClick={() => setConfirmTarget(null)}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-xs bg-void-black border border-ink/10 p-6"
            >
              <p className="font-mono text-sm text-ink mb-2">
                {t('removeConfirm')}
              </p>
              <p className="font-mono text-xs text-ghost-grey/60 mb-6">
                {confirmTarget.roomType === 'group'
                  ? (confirmTarget.title || confirmTarget.roomId.slice(0, 8))
                  : (confirmTarget.peerUsername || confirmTarget.roomId.slice(0, 8))}
              </p>
              <div className="flex gap-3">
                <button
                  onClick={() => setConfirmTarget(null)}
                  className="flex-1 min-h-[40px] px-4 py-2 border border-ink/10 text-ghost-grey font-mono text-xs uppercase tracking-wider hover:border-ink/30 transition-colors"
                >
                  {t('cancel')}
                </button>
                <button
                  onClick={handleRemove}
                  className="flex-1 min-h-[40px] px-4 py-2 border border-glitch-red/30 text-glitch-red font-mono text-xs uppercase tracking-wider hover:bg-glitch-red hover:text-void-black transition-all"
                >
                  {t('confirmRemove')}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function formatTimeAgo(timestampMs: number): string {
  const diff = Date.now() - timestampMs;
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'now';
  if (minutes < 60) return `${minutes}m`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  return `${days}d`;
}
