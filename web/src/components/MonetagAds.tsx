'use client';

import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import Script from 'next/script';

const POPUNDER_COOLDOWN_MS = 60 * 60 * 1000; // 1시간
const VIGNETTE_COOLDOWN_MS = 60 * 60 * 1000; // 1시간

/** localStorage 기반 쿨다운 훅 */
function useAdCooldown(key: string, cooldownMs: number) {
  const [allowed, setAllowed] = useState(false);

  useEffect(() => {
    try {
      const last = localStorage.getItem(key);
      const now = Date.now();
      if (!last || now - Number(last) >= cooldownMs) {
        setAllowed(true);
        localStorage.setItem(key, String(now));
      }
    } catch {
      setAllowed(true);
    }
  }, [key, cooldownMs]);

  return allowed;
}

export default function MonetagAds() {
  const pathname = usePathname();
  const isChatRoom = pathname.includes('/room/');
  const popunderAllowed = useAdCooldown('monetag_popunder_last', POPUNDER_COOLDOWN_MS);
  const vignetteAllowed = useAdCooldown('monetag_vignette_last', VIGNETTE_COOLDOWN_MS);

  return (
    <>
      {/* PopUnder — 채팅방 제외 + 1시간 쿨다운 */}
      {!isChatRoom && popunderAllowed && (
        <Script
          id="monetag-popunder"
          strategy="afterInteractive"
          dangerouslySetInnerHTML={{
            __html: `(function(s){s.dataset.zone='10661019',s.src='https://al5sm.com/tag.min.js'})([document.documentElement, document.body].filter(Boolean).pop().appendChild(document.createElement('script')))`,
          }}
        />
      )}

      {/* Vignette — 1시간 쿨다운 */}
      {vignetteAllowed && (
        <Script
          id="monetag-banner"
          strategy="afterInteractive"
          dangerouslySetInnerHTML={{
            __html: `(function(s){s.dataset.zone='10661025',s.src='https://gizokraijaw.net/vignette.min.js'})([document.documentElement, document.body].filter(Boolean).pop().appendChild(document.createElement('script')))`,
          }}
        />
      )}
    </>
  );
}
