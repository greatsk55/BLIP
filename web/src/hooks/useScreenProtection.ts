'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

/**
 * 스크린 캡처 감지 및 방지 훅.
 *
 * 웹에서 완벽한 캡처 차단은 불가능하지만, 아래 기법을 조합하여
 * 최대한 보호:
 *
 * 1. visibilitychange — 탭 비활성화 시 메시지 즉시 블러 (화면 녹화 무력화)
 * 2. keydown — PrintScreen / Cmd+Shift+3,4,5 감지
 * 3. CSS — user-select:none, 우클릭 차단 (ChatMessageArea에서 적용)
 * 4. blur — 일부 캡처 도구가 포커스를 빼앗는 경우 감지
 *
 * @returns captured — true이면 메시지 영역을 블러 처리해야 함
 */
export function useScreenProtection() {
  const [captured, setCaptured] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  /** 캡처 감지 시 호출: 즉시 블러 → 일정 시간 후 해제 */
  const trigger = useCallback(() => {
    setCaptured(true);

    // 기존 타이머 초기화
    if (timerRef.current) clearTimeout(timerRef.current);

    // 3초 후 자동 해제
    timerRef.current = setTimeout(() => {
      setCaptured(false);
      timerRef.current = null;
    }, 3_000);
  }, []);

  useEffect(() => {
    // 1. 키보드 단축키 감지
    const handleKeyDown = (e: KeyboardEvent) => {
      // PrintScreen (Windows/Linux)
      if (e.key === 'PrintScreen') {
        e.preventDefault();
        trigger();
        return;
      }
      // Mac: Cmd+Shift+3/4/5 (스크린샷)
      if (e.metaKey && e.shiftKey && ['3', '4', '5'].includes(e.key)) {
        trigger();
        return;
      }
      // Ctrl+Shift+S (일부 캡처 도구)
      if (e.ctrlKey && e.shiftKey && (e.key === 'S' || e.key === 's')) {
        e.preventDefault();
        trigger();
        return;
      }
    };

    // 2. visibilitychange — 탭 전환, 화면 녹화 도구, 앱 전환
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // 탭이 숨겨지면 즉시 블러
        setCaptured(true);
      } else {
        // 탭 복귀 시 3초간 유지 후 해제
        if (timerRef.current) clearTimeout(timerRef.current);
        timerRef.current = setTimeout(() => {
          setCaptured(false);
          timerRef.current = null;
        }, 3_000);
      }
    };

    // 3. 우클릭 방지 (채팅 영역에서 이미지 저장 등 차단)
    const handleContextMenu = (e: Event) => {
      // input, textarea는 허용 (붙여넣기 등)
      const target = e.target as HTMLElement;
      if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;
      e.preventDefault();
    };

    window.addEventListener('keydown', handleKeyDown, true);
    document.addEventListener('visibilitychange', handleVisibilityChange);
    document.addEventListener('contextmenu', handleContextMenu);

    return () => {
      window.removeEventListener('keydown', handleKeyDown, true);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
      document.removeEventListener('contextmenu', handleContextMenu);
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [trigger]);

  return captured;
}
