'use client';

import { useRef, useCallback, useEffect } from 'react';

interface UseNotificationReturn {
  /** 메시지 수신 시 알림 (사운드 + 진동 + 브라우저 알림 + 탭 타이틀) */
  notifyMessage: (senderName: string) => void;
  /** 브라우저 Notification 권한 요청 */
  requestPermission: () => Promise<void>;
}

/**
 * 채팅 알림 훅
 * - 탭 활성: 사운드만
 * - 탭 비활성: 사운드 + 진동 + 브라우저 알림 + 탭 타이틀 깜빡임
 * - 흔적 없음: Service Worker / Push 미사용
 */
export function useNotification(): UseNotificationReturn {
  const audioContextRef = useRef<AudioContext | null>(null);
  const isTabFocusedRef = useRef(true);
  const originalTitleRef = useRef('');
  const titleIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // 탭 포커스 추적
  useEffect(() => {
    originalTitleRef.current = document.title;

    const handleFocus = () => {
      isTabFocusedRef.current = true;
      // 타이틀 복원
      if (titleIntervalRef.current) {
        clearInterval(titleIntervalRef.current);
        titleIntervalRef.current = null;
      }
      document.title = originalTitleRef.current;
    };

    const handleBlur = () => {
      isTabFocusedRef.current = false;
    };

    window.addEventListener('focus', handleFocus);
    window.addEventListener('blur', handleBlur);

    return () => {
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('blur', handleBlur);
      if (titleIntervalRef.current) {
        clearInterval(titleIntervalRef.current);
      }
      // AudioContext 리소스 해제
      if (audioContextRef.current) {
        audioContextRef.current.close().catch(() => {});
        audioContextRef.current = null;
      }
    };
  }, []);

  // Web Audio API로 짧은 알림음 재생
  const playSound = useCallback(() => {
    try {
      if (!audioContextRef.current) {
        audioContextRef.current = new AudioContext();
      }
      const ctx = audioContextRef.current;

      // suspended 상태면 resume (브라우저 autoplay 정책)
      if (ctx.state === 'suspended') {
        ctx.resume();
      }

      const oscillator = ctx.createOscillator();
      const gainNode = ctx.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(ctx.destination);

      // 짧고 깔끔한 2톤 비프 (BLIP 스타일)
      oscillator.type = 'sine';
      oscillator.frequency.setValueAtTime(880, ctx.currentTime);
      oscillator.frequency.setValueAtTime(660, ctx.currentTime + 0.08);

      gainNode.gain.setValueAtTime(0.15, ctx.currentTime);
      gainNode.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.15);

      oscillator.start(ctx.currentTime);
      oscillator.stop(ctx.currentTime + 0.15);
    } catch {
      // Audio API 미지원 환경
    }
  }, []);

  // 모바일 진동
  const vibrate = useCallback(() => {
    if (navigator.vibrate) {
      navigator.vibrate([80, 40, 80]);
    }
  }, []);

  // 탭 타이틀 깜빡임 (비활성 탭에서만)
  const flashTitle = useCallback((senderName: string) => {
    if (isTabFocusedRef.current || titleIntervalRef.current) return;

    const alertTitle = `[${senderName}] BLIP`;
    let showAlert = true;

    titleIntervalRef.current = setInterval(() => {
      document.title = showAlert ? alertTitle : originalTitleRef.current;
      showAlert = !showAlert;
    }, 1000);
  }, []);

  // 브라우저 Notification API (비활성 탭에서만)
  const showBrowserNotification = useCallback((senderName: string) => {
    if (isTabFocusedRef.current) return;
    if (typeof Notification === 'undefined') return;
    if (Notification.permission !== 'granted') return;

    const notification = new Notification('BLIP', {
      body: senderName,
      icon: '/icon-192x192.png',
      tag: 'blip-message', // 이전 알림 교체
      silent: true, // 사운드는 직접 처리
    });

    notification.onclick = () => {
      window.focus();
      notification.close();
    };

    // 4초 후 자동 닫기
    setTimeout(() => notification.close(), 4000);
  }, []);

  // 브라우저 Notification 권한 요청
  const requestPermission = useCallback(async () => {
    if (typeof Notification === 'undefined') return;
    if (Notification.permission === 'default') {
      await Notification.requestPermission();
    }
  }, []);

  // 메인 알림 함수
  const notifyMessage = useCallback(
    (senderName: string) => {
      playSound();

      // 탭 비활성 시 추가 알림
      if (!isTabFocusedRef.current) {
        vibrate();
        flashTitle(senderName);
        showBrowserNotification(senderName);
      }
    },
    [playSound, vibrate, flashTitle, showBrowserNotification]
  );

  return { notifyMessage, requestPermission };
}
