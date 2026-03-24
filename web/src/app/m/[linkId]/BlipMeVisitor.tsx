'use client';

import { useEffect, useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import { Zap, AlertCircle, Loader2 } from 'lucide-react';
import { connectViaBlipMe, checkBlipMeLink } from '@/lib/blipme/actions';
import { saveRoom, saveRoomPassword } from '@/lib/room/storage';

interface BlipMeVisitorProps {
  linkId: string;
}

type PageState = 'checking' | 'ready' | 'connecting' | 'redirecting' | 'error';

export default function BlipMeVisitor({ linkId }: BlipMeVisitorProps) {
  const [state, setState] = useState<PageState>('checking');
  const [errorCode, setErrorCode] = useState<string | null>(null);

  // 링크 유효성 확인
  useEffect(() => {
    async function check() {
      const result = await checkBlipMeLink(linkId);
      if (!result.exists || !result.active) {
        setState('error');
        setErrorCode(result.exists ? 'LINK_DISABLED' : 'LINK_NOT_FOUND');
        return;
      }
      setState('ready');
    }
    check();
  }, [linkId]);

  const handleConnect = useCallback(async () => {
    setState('connecting');
    const result = await connectViaBlipMe(linkId);

    if ('error' in result) {
      setState('error');
      setErrorCode(result.error);
      return;
    }

    // 방 정보 로컬 저장
    saveRoom({
      roomId: result.roomId,
      roomType: 'chat',
      isCreator: false,
      isAdmin: false,
      createdAt: Date.now(),
      lastAccessedAt: Date.now(),
      status: 'active',
    });
    saveRoomPassword(result.roomId, result.password);

    setState('redirecting');

    // 브라우저 기본 locale 감지 후 리다이렉트
    const locale = navigator.language.startsWith('ko') ? 'ko'
      : navigator.language.startsWith('ja') ? 'ja'
      : navigator.language.startsWith('zh') ? 'zh'
      : navigator.language.startsWith('es') ? 'es'
      : navigator.language.startsWith('fr') ? 'fr'
      : navigator.language.startsWith('de') ? 'de'
      : 'en';

    window.location.href = `/${locale}/room/${result.roomId}#p=${encodeURIComponent(result.password)}`;
  }, [linkId]);

  const errorMessages: Record<string, string> = {
    LINK_NOT_FOUND: 'This link does not exist.',
    LINK_DISABLED: 'This link has been deactivated.',
    TOO_MANY_REQUESTS: 'Too many attempts. Please try again later.',
    ROOM_CREATE_FAILED: 'Failed to create room. Please try again.',
  };

  return (
    <div className="min-h-screen bg-void-black flex flex-col items-center justify-center px-4">
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--color-signal-green)_0%,_transparent_10%)] opacity-10 blur-3xl pointer-events-none" />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative z-10 text-center max-w-md w-full"
      >
        {/* BLIP 로고 */}
        <h1 className="text-4xl md:text-6xl font-bold font-sans tracking-tighter mb-2 text-ink">
          BLIP
        </h1>
        <p className="text-sm font-mono text-ghost-grey mb-8 uppercase tracking-widest">
          someone wants to talk
        </p>

        {/* 상태별 UI */}
        {state === 'checking' && (
          <div className="flex items-center justify-center gap-2 text-ghost-grey">
            <Loader2 className="w-5 h-5 animate-spin" />
            <span className="font-mono text-sm">Verifying link...</span>
          </div>
        )}

        {state === 'ready' && (
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={handleConnect}
            className="group relative px-10 py-5 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300 rounded-none overflow-hidden w-full"
          >
            <span className="relative z-10 flex items-center justify-center gap-3 font-mono text-base font-bold">
              <Zap className="w-5 h-5" />
              CONNECT
            </span>
            <div className="absolute inset-0 bg-signal-green opacity-0 group-hover:opacity-10 transition-opacity duration-300 blur-md" />
          </motion.button>
        )}

        {state === 'connecting' && (
          <div className="flex flex-col items-center gap-3 text-signal-green">
            <Loader2 className="w-8 h-8 animate-spin" />
            <span className="font-mono text-sm">Creating secure room...</span>
          </div>
        )}

        {state === 'redirecting' && (
          <div className="flex flex-col items-center gap-3 text-signal-green">
            <Loader2 className="w-8 h-8 animate-spin" />
            <span className="font-mono text-sm">Entering room...</span>
          </div>
        )}

        {state === 'error' && (
          <div className="flex flex-col items-center gap-3 text-red-400">
            <AlertCircle className="w-8 h-8" />
            <span className="font-mono text-sm">
              {errorCode ? errorMessages[errorCode] ?? 'Something went wrong.' : 'Something went wrong.'}
            </span>
            <a
              href="/"
              className="mt-4 font-mono text-xs text-ghost-grey hover:text-signal-green transition-colors underline"
            >
              Go to BLIP
            </a>
          </div>
        )}

        {/* 하단 안내 */}
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.4 }}
          transition={{ delay: 1 }}
          className="mt-12 text-xs font-mono text-ghost-grey"
        >
          End-to-end encrypted · No accounts · No traces
        </motion.p>
      </motion.div>
    </div>
  );
}
