'use client';

import { useEffect, useRef, useCallback, useImperativeHandle, forwardRef } from 'react';
import type { DecryptedMessage } from '@/types/chat';
import MessageBubble from './MessageBubble';
import SystemMessage from './SystemMessage';

interface ChatMessageAreaProps {
  messages: DecryptedMessage[];
  onImageClick?: (src: string) => void;
  /** 캡처 감지 상태 — true이면 메시지를 블러 처리 */
  screenCaptured?: boolean;
}

export interface ChatMessageAreaHandle {
  scrollToBottom: () => void;
}

const ChatMessageArea = forwardRef<ChatMessageAreaHandle, ChatMessageAreaProps>(
  function ChatMessageArea({ messages, onImageClick, screenCaptured }, ref) {
    const bottomRef = useRef<HTMLDivElement>(null);
    const containerRef = useRef<HTMLDivElement>(null);

    const scrollToBottom = useCallback((instant?: boolean) => {
      bottomRef.current?.scrollIntoView({
        behavior: instant ? 'instant' : 'smooth',
      });
    }, []);

    useImperativeHandle(ref, () => ({ scrollToBottom }), [scrollToBottom]);

    // 새 메시지 도착 시 스크롤
    useEffect(() => {
      scrollToBottom();
    }, [messages, scrollToBottom]);

    // 모바일 키보드 열림/닫힘 감지 → 현재 보던 위치 유지
    // 컨테이너가 줄어든(늘어난) 만큼 scrollTop을 보정하여 보던 메시지 유지
    useEffect(() => {
      const viewport = window.visualViewport;
      const container = containerRef.current;
      if (!viewport || !container) return;

      let prevHeight = viewport.height;

      const handleResize = () => {
        const curHeight = viewport.height;
        const diff = prevHeight - curHeight;
        prevHeight = curHeight;

        if (Math.abs(diff) < 10) return; // 미세 변화 무시

        // --app-height 반영 후 scrollTop 보정
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            if (diff > 0) {
              // 키보드 올라옴 → 줄어든 만큼 스크롤 내려서 보던 위치 유지
              container.scrollTop += diff;
            }
            // 키보드 내려감 → 별도 보정 불필요 (자연스러움)
          });
        });
      };

      viewport.addEventListener('resize', handleResize);
      return () => viewport.removeEventListener('resize', handleResize);
    }, []);

    return (
      <div
        ref={containerRef}
        className="relative flex-1 overflow-y-auto px-3 sm:px-4 py-4 overscroll-none touch-pan-y select-none"
        style={{ WebkitOverflowScrolling: 'touch' }}
        role="log"
        aria-live="polite"
      >
        {messages.length === 0 && (
          <div className="flex items-center justify-center h-full">
            <span className="font-mono text-2xl sm:text-3xl font-bold text-ink/[0.03] tracking-widest select-none">
              BLIP
            </span>
          </div>
        )}

        {/* 캡처 감지 시 메시지 영역 블러 */}
        <div className={screenCaptured ? 'blur-xl transition-[filter] duration-100' : 'transition-[filter] duration-300'}>
          {messages.map((msg) =>
            msg.senderId === 'system' ? (
              <SystemMessage key={msg.id} content={msg.content} />
            ) : (
              <MessageBubble key={msg.id} message={msg} onImageClick={onImageClick} />
            )
          )}
        </div>

        {/* 캡처 감지 경고 오버레이 */}
        {screenCaptured && (
          <div className="absolute inset-0 flex items-center justify-center z-10">
            <div className="font-mono text-xs sm:text-sm text-signal-red/80 tracking-[0.3em] uppercase animate-pulse">
              ⚠ CAPTURE DETECTED ⚠
            </div>
          </div>
        )}

        <div ref={bottomRef} />
      </div>
    );
  }
);

export default ChatMessageArea;
