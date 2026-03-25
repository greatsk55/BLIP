/**
 * Firebase Cloud Messaging 서버 발송 (firebase-admin)
 *
 * 환경변수:
 * - FIREBASE_PROJECT_ID
 * - FIREBASE_CLIENT_EMAIL
 * - FIREBASE_PRIVATE_KEY (PEM, \n 이스케이프)
 */

import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

function getFirebaseAdmin() {
  if (getApps().length > 0) return getApps()[0];

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

  if (!projectId || !clientEmail || !privateKey) {
    return null;
  }

  return initializeApp({
    credential: cert({ projectId, clientEmail, privateKey }),
  });
}

/**
 * FCM 푸시 알림 발송
 * @returns true: 성공, false: 실패 또는 미설정
 */
export async function sendFcmNotification({
  fcmToken,
  title,
  body,
  data,
}: {
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}): Promise<boolean> {
  try {
    const app = getFirebaseAdmin();
    if (!app) return false;

    const messaging = getMessaging(app);
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      data,
      android: {
        priority: 'high',
        notification: {
          channelId: 'blipme',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: 'default',
            badge: 1,
          },
        },
      },
    });
    return true;
  } catch (e) {
    console.error('[FCM] Send failed:', e);
    return false;
  }
}
