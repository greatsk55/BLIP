/**
 * BLIP me 전용 Service Worker — 웹 푸시 수신
 * 스코프: BLIP me 페이지에서만 등록
 */

self.addEventListener('push', (event) => {
  if (!event.data) return;

  try {
    const data = event.data.json();
    const title = data.title || 'BLIP me';
    const options = {
      body: data.body || 'Someone wants to talk!',
      icon: '/favicon-96x96.png',
      badge: '/favicon-96x96.png',
      tag: 'blipme-' + (data.roomId || Date.now()),
      data: {
        roomId: data.roomId,
        password: data.password,
        url: data.url,
      },
      vibrate: [100, 50, 100],
      requireInteraction: true,
    };

    event.waitUntil(self.registration.showNotification(title, options));
  } catch {
    // 파싱 실패 시 기본 알림
    event.waitUntil(
      self.registration.showNotification('BLIP me', {
        body: 'Someone wants to talk!',
        icon: '/favicon-96x96.png',
      })
    );
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data;
  let url = '/blipme';

  if (data && data.roomId && data.password) {
    // 브라우저 언어 감지
    const lang = (self.navigator && self.navigator.language) || 'en';
    const locale = lang.startsWith('ko') ? 'ko'
      : lang.startsWith('ja') ? 'ja'
      : lang.startsWith('zh') ? 'zh'
      : lang.startsWith('es') ? 'es'
      : lang.startsWith('fr') ? 'fr'
      : lang.startsWith('de') ? 'de'
      : 'en';
    url = '/' + locale + '/room/' + data.roomId + '#k=' + encodeURIComponent(data.password);
  } else if (data && data.url) {
    url = data.url;
  }

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clients) => {
      // 이미 열린 BLIP 탭이 있으면 포커스 + 이동
      for (const client of clients) {
        if (client.url.includes(self.location.origin)) {
          client.navigate(url);
          return client.focus();
        }
      }
      // 없으면 새 탭
      return self.clients.openWindow(url);
    })
  );
});
