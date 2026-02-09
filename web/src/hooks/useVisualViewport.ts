'use client';

import { useEffect, useCallback, useRef } from 'react';

/**
 * 모바일 키보드 대응: visualViewport를 추적하여
 * --app-height CSS 변수를 동적으로 업데이트.
 * 키보드가 올라오면 컨테이너 높이가 줄어들어 입력창이 보임.
 */
export function useVisualViewport() {
  const rafRef = useRef<number>(0);

  const updateHeight = useCallback(() => {
    cancelAnimationFrame(rafRef.current);
    rafRef.current = requestAnimationFrame(() => {
      const vh = window.visualViewport?.height ?? window.innerHeight;
      const offsetTop = window.visualViewport?.offsetTop ?? 0;
      document.documentElement.style.setProperty(
        '--app-height',
        `${vh + offsetTop}px`
      );
    });
  }, []);

  useEffect(() => {
    updateHeight();

    const vv = window.visualViewport;
    if (vv) {
      vv.addEventListener('resize', updateHeight);
      vv.addEventListener('scroll', updateHeight);
    }
    // fallback
    window.addEventListener('resize', updateHeight);

    return () => {
      cancelAnimationFrame(rafRef.current);
      if (vv) {
        vv.removeEventListener('resize', updateHeight);
        vv.removeEventListener('scroll', updateHeight);
      }
      window.removeEventListener('resize', updateHeight);
    };
  }, [updateHeight]);
}
