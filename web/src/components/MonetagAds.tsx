'use client';

import { usePathname } from 'next/navigation';
import Script from 'next/script';

export default function MonetagAds() {
  const pathname = usePathname();
  const isChatRoom = pathname.includes('/room/');

  return (
    <>
      {/* Push Notification — 전체 페이지 */}
      <Script
        id="monetag-push"
        src="https://quge5.com/88/tag.min.js"
        data-zone="214867"
        strategy="afterInteractive"
      />

      {/* PopUnder — 채팅방 제외 (클릭 잦아서 UX 저하) */}
      {!isChatRoom && (
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
