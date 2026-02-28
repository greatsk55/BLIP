'use client';

import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';
import Script from 'next/script';

const POPUNDER_COOLDOWN_MS = 60 * 60 * 1000; // 1시간
const POPUNDER_KEY = 'monetag_popunder_last';

function usePopunderAllowed() {
  const [allowed, setAllowed] = useState(false);

  useEffect(() => {
    try {
      const last = localStorage.getItem(POPUNDER_KEY);
      const now = Date.now();
      if (!last || now - Number(last) >= POPUNDER_COOLDOWN_MS) {
        setAllowed(true);
        localStorage.setItem(POPUNDER_KEY, String(now));
      }
    } catch {
      // localStorage 접근 불가 시 그냥 허용
      setAllowed(true);
    }
  }, []);

  return allowed;
}

export default function MonetagAds() {
  const pathname = usePathname();
  const isChatRoom = pathname.includes('/room/');
  const popunderAllowed = usePopunderAllowed();

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

      {/* Banner (Vignette) — 전체 페이지 */}
      <Script
        id="monetag-banner"
        strategy="afterInteractive"
        dangerouslySetInnerHTML={{
          __html: `(function(s){s.dataset.zone='10661025',s.src='https://gizokraijaw.net/vignette.min.js'})([document.documentElement, document.body].filter(Boolean).pop().appendChild(document.createElement('script')))`,
        }}
      />
    </>
  );
}
