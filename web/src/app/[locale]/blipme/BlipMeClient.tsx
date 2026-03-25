'use client';

import { useTranslations } from 'next-intl';
import { motion, AnimatePresence } from 'framer-motion';
import { useRouter } from '@/i18n/navigation';
import { Link } from '@/i18n/navigation';
import {
  Zap,
  Trash2,
  RefreshCw,
  Copy,
  Check,
  Radio,
  WifiOff,
  ArrowLeft,
  ExternalLink,
  Bell,
  Loader2,
} from 'lucide-react';
import { useState, useCallback } from 'react';
import { useBlipMe } from '@/hooks/useBlipMe';
import { saveRoom, saveRoomPassword } from '@/lib/room/storage';

export default function BlipMeClient() {
  const t = useTranslations('BlipMe');
  const router = useRouter();
  const {
    linkId,
    loading,
    error,
    useCount,
    createLink,
    deleteLink,
    regenerateLink,
    incomingConnection,
    clearIncoming,
    listening,
    webPushEnabled,
  } = useBlipMe();

  const [copied, setCopied] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const blipMeUrl = linkId
    ? `${typeof window !== 'undefined' ? window.location.origin : ''}/m/${linkId}`
    : '';

  const handleCopy = useCallback(async () => {
    if (!blipMeUrl) return;
    await navigator.clipboard.writeText(blipMeUrl);
    if (navigator.vibrate) navigator.vibrate(50);
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }, [blipMeUrl]);

  const handleDelete = useCallback(async () => {
    if (!confirmDelete) {
      setConfirmDelete(true);
      setTimeout(() => setConfirmDelete(false), 3000);
      return;
    }
    await deleteLink();
    setConfirmDelete(false);
  }, [confirmDelete, deleteLink]);

  const handleJoinRoom = useCallback(() => {
    if (!incomingConnection) return;
    const { roomId, password } = incomingConnection;

    saveRoom({
      roomId,
      roomType: 'chat',
      isCreator: false,
      isAdmin: false,
      createdAt: Date.now(),
      lastAccessedAt: Date.now(),
      status: 'active',
    });
    saveRoomPassword(roomId, password);

    clearIncoming();
    router.push(`/room/${roomId}#k=${encodeURIComponent(password)}`);
  }, [incomingConnection, clearIncoming, router]);

  return (
    <div className="min-h-screen bg-void-black flex flex-col">
      {/* 헤더 */}
      <header className="p-4 flex items-center gap-3">
        <Link
          href="/"
          className="p-2 text-ghost-grey hover:text-ink transition-colors"
        >
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-mono text-sm text-ink uppercase tracking-wider">
          BLIP me
        </h1>
        {linkId && (
          <span className="ml-auto flex items-center gap-3 font-mono text-xs">
            {webPushEnabled && (
              <span className="flex items-center gap-1 text-signal-green" title="Web push enabled">
                <Bell className="w-3 h-3" />
              </span>
            )}
            {listening ? (
              <span className="flex items-center gap-1.5">
                <Radio className="w-3 h-3 text-signal-green animate-pulse" />
                <span className="text-signal-green">{t('listening')}</span>
              </span>
            ) : (
              <span className="flex items-center gap-1.5">
                <WifiOff className="w-3 h-3 text-ghost-grey" />
                <span className="text-ghost-grey">{t('offline')}</span>
              </span>
            )}
          </span>
        )}
      </header>

      {/* 메인 */}
      <main className="flex-1 flex flex-col items-center justify-center px-4 pb-20">
        <div className="w-full max-w-md">
          {/* 로딩 */}
          {loading && (
            <div className="flex items-center justify-center py-20">
              <Loader2 className="w-6 h-6 text-ghost-grey animate-spin" />
            </div>
          )}

          {/* 링크 미생성 상태 */}
          {!loading && !linkId && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-center"
            >
              <Zap className="w-12 h-12 text-signal-green mx-auto mb-6" />
              <h2 className="text-2xl md:text-3xl font-bold text-ink mb-3">
                {t('createTitle')}
              </h2>
              <p className="text-sm text-ghost-grey font-mono mb-8 leading-relaxed">
                {t('createDescription')}
              </p>

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={createLink}
                className="w-full px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300 font-mono text-sm font-bold"
              >
                {t('createButton')}
              </motion.button>
            </motion.div>
          )}

          {/* 링크 활성 상태 */}
          {!loading && linkId && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="space-y-6"
            >
              {/* URL 표시 + 복사 */}
              <div className="border border-ink/20 p-4">
                <label className="block text-xs font-mono text-ghost-grey mb-2 uppercase tracking-wider">
                  {t('yourLink')}
                </label>
                <div className="flex items-center gap-2">
                  <code className="flex-1 text-sm font-mono text-signal-green break-all select-all">
                    {blipMeUrl}
                  </code>
                  <button
                    onClick={handleCopy}
                    className={`p-2 transition-colors ${
                      copied ? 'text-signal-green' : 'text-ghost-grey hover:text-ink'
                    }`}
                  >
                    {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                  </button>
                </div>
              </div>

              {/* 통계 */}
              <div className="flex items-center justify-between text-xs font-mono text-ghost-grey border border-ink/10 p-3">
                <span>{t('totalConnections')}</span>
                <span className="text-ink font-bold">{useCount}</span>
              </div>

              {/* 안내 */}
              <p className="text-xs font-mono text-ghost-grey leading-relaxed">
                {t('howItWorks')}
              </p>

              {/* 액션 버튼 */}
              <div className="flex gap-3">
                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={regenerateLink}
                  className="flex-1 flex items-center justify-center gap-2 px-4 py-3 border border-ink/20 text-ghost-grey hover:border-signal-green hover:text-signal-green transition-all font-mono text-xs"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  {t('regenerate')}
                </motion.button>

                <motion.button
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  onClick={handleDelete}
                  className={`flex-1 flex items-center justify-center gap-2 px-4 py-3 border transition-all font-mono text-xs ${
                    confirmDelete
                      ? 'border-red-500 text-red-400 hover:bg-red-500/10'
                      : 'border-ink/20 text-ghost-grey hover:border-red-500 hover:text-red-400'
                  }`}
                >
                  <Trash2 className="w-3.5 h-3.5" />
                  {confirmDelete ? t('confirmDelete') : t('delete')}
                </motion.button>
              </div>
            </motion.div>
          )}

          {/* 에러 */}
          <AnimatePresence>
            {error && (
              <motion.p
                initial={{ opacity: 0, y: -5 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0 }}
                className="mt-4 text-xs font-mono text-red-400 text-center"
              >
                {error === 'TOO_MANY_REQUESTS' ? t('rateLimited') : t('error')}
              </motion.p>
            )}
          </AnimatePresence>

          {/* 수신 알림 팝업 */}
          <AnimatePresence>
            {incomingConnection && (
              <motion.div
                initial={{ opacity: 0, y: 50, scale: 0.9 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 50, scale: 0.9 }}
                className="fixed bottom-6 left-4 right-4 max-w-md mx-auto z-50"
              >
                <div className="border border-signal-green bg-void-black/95 backdrop-blur-sm p-4 shadow-lg shadow-signal-green/10">
                  <div className="flex items-center gap-3 mb-3">
                    <Bell className="w-5 h-5 text-signal-green animate-bounce" />
                    <span className="font-mono text-sm text-ink font-bold">
                      {t('incomingTitle')}
                    </span>
                  </div>
                  <p className="text-xs font-mono text-ghost-grey mb-4">
                    {t('incomingDescription')}
                  </p>
                  <div className="flex gap-3">
                    <motion.button
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      onClick={handleJoinRoom}
                      className="flex-1 flex items-center justify-center gap-2 px-4 py-3 bg-signal-green text-void-black font-mono text-sm font-bold transition-all hover:bg-signal-green/90"
                    >
                      <ExternalLink className="w-4 h-4" />
                      {t('joinRoom')}
                    </motion.button>
                    <button
                      onClick={clearIncoming}
                      className="px-4 py-3 border border-ink/20 text-ghost-grey font-mono text-xs hover:text-ink transition-colors"
                    >
                      {t('dismiss')}
                    </button>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </main>
    </div>
  );
}
