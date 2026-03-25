/**
 * Web Push 서버 발송 (web-push 패키지)
 *
 * 환경변수:
 * - NEXT_PUBLIC_VAPID_PUBLIC_KEY
 * - VAPID_PRIVATE_KEY
 * - VAPID_SUBJECT (mailto: 형태)
 */

import webPush from 'web-push';

function getVapidKeys() {
  const publicKey = process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY;
  const privateKey = process.env.VAPID_PRIVATE_KEY;
  const subject = process.env.VAPID_SUBJECT || 'mailto:noreply@blip-blip.vercel.app';

  if (!publicKey || !privateKey) return null;
  return { publicKey, privateKey, subject };
}

/**
 * Web Push 알림 발송
 * @param subscription PushSubscription JSON (endpoint, keys.p256dh, keys.auth)
 * @returns true: 성공, false: 실패 또는 미설정
 */
export async function sendWebPushNotification({
  subscription,
  title,
  body,
  data,
}: {
  subscription: string; // JSON string of PushSubscription
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<boolean> {
  try {
    const vapid = getVapidKeys();
    if (!vapid) return false;

    webPush.setVapidDetails(vapid.subject, vapid.publicKey, vapid.privateKey);

    const sub = JSON.parse(subscription);
    await webPush.sendNotification(
      sub,
      JSON.stringify({ title, body, ...data }),
    );
    return true;
  } catch (e: unknown) {
    const statusCode = (e as { statusCode?: number })?.statusCode;
    // 410 Gone = 구독 만료 → 정리 필요
    if (statusCode === 410 || statusCode === 404) {
      console.warn('[WebPush] Subscription expired');
    } else {
      console.error('[WebPush] Send failed:', e);
    }
    return false;
  }
}
