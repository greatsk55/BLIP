'use client';

import { useCallback, useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { createRoom } from '@/lib/room/actions';
import { postToParent } from '@/lib/embed/postMessage';
import TermsModal from '@/components/chat/TermsModal';

export default function EmbedPage() {
  const t = useTranslations('Hero');
  const tc = useTranslations('Chat');
  const router = useRouter();
  const [creating, setCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [termsAgreed, setTermsAgreed] = useState(false);
  const [termsOpen, setTermsOpen] = useState(false);
  const [termsError, setTermsError] = useState(false);

  useEffect(() => {
    postToParent({ type: 'blip:ready' });
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
      setError(result.error === 'TOO_MANY_REQUESTS' ? t('rateLimited') : t('createFailed'));
      setCreating(false);
      return;
    }

    const shareUrl = `${window.location.origin}/embed/room/${result.roomId}#k=${encodeURIComponent(result.password)}`;
    postToParent({
      type: 'blip:room-created',
      roomId: result.roomId,
      shareUrl,
    });

    router.push(`/embed/room/${result.roomId}#p=${encodeURIComponent(result.password)}`);
  }, [creating, termsAgreed, router, t]);

  return (
    <div className="h-dvh bg-void-black flex flex-col items-center justify-center px-4 text-center">
      {/* 로고 */}
      <h1 className="font-mono text-2xl font-bold text-ink tracking-[0.3em] mb-2">
        BLIP
      </h1>
      <p className="font-mono text-xs text-ghost-grey mb-8 max-w-xs">
        {t.rich('subtitle', { br: () => <br /> })}
      </p>

      {/* 이용약관 동의 */}
      <div className="flex items-center gap-2 mb-4 select-none">
        <input
          id="embed-terms"
          type="checkbox"
          checked={termsAgreed}
          onChange={() => { setTermsAgreed(v => !v); setTermsError(false); }}
          className="w-4 h-4 accent-signal-green cursor-pointer"
        />
        <label htmlFor="embed-terms" className="font-mono text-[10px] text-ghost-grey cursor-pointer">
          {tc.rich('terms.agree', {
            terms: (chunks) => (
              <button
                type="button"
                onClick={(e) => { e.preventDefault(); e.stopPropagation(); setTermsOpen(true); }}
                className="underline text-signal-green hover:text-signal-green/80 transition-colors"
              >
                {chunks}
              </button>
            ),
          })}
        </label>
      </div>

      {termsError && (
        <p className="mb-3 text-[10px] font-mono text-red-400">
          {tc('terms.mustAgree')}
        </p>
      )}

      {/* 방 생성 버튼 */}
      <button
        onClick={handleCreateRoom}
        disabled={creating}
        className="px-6 py-3 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-300 font-mono text-sm uppercase tracking-wider disabled:opacity-50"
      >
        {creating ? 'CREATING...' : t('cta')}
      </button>

      {error && (
        <p className="mt-3 text-xs font-mono text-red-400">{error}</p>
      )}

      <p className="mt-6 font-mono text-[10px] text-ghost-grey/40 uppercase tracking-wider">
        E2E ENCRYPTED
      </p>

      <TermsModal isOpen={termsOpen} onClose={() => setTermsOpen(false)} />
    </div>
  );
}
