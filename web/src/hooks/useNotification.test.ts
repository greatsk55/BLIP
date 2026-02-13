import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useNotification } from './useNotification';

// AudioContext mock
const mockOscillator = {
  connect: vi.fn(),
  frequency: { setValueAtTime: vi.fn() },
  type: 'sine',
  start: vi.fn(),
  stop: vi.fn(),
};

const mockGain = {
  connect: vi.fn(),
  gain: { setValueAtTime: vi.fn(), exponentialRampToValueAtTime: vi.fn() },
};

const MockAudioContext = vi.fn(() => ({
  state: 'running',
  resume: vi.fn(),
  destination: {},
  createOscillator: vi.fn(() => mockOscillator),
  createGain: vi.fn(() => mockGain),
  currentTime: 0,
}));

// Notification mock
const mockNotificationInstance = {
  close: vi.fn(),
  onclick: null as (() => void) | null,
};

const MockNotification = vi.fn(() => mockNotificationInstance) as unknown as typeof Notification;
Object.defineProperty(MockNotification, 'permission', {
  value: 'default',
  writable: true,
  configurable: true,
});
MockNotification.requestPermission = vi.fn().mockResolvedValue('granted');

beforeEach(() => {
  vi.useFakeTimers();
  globalThis.AudioContext = MockAudioContext as unknown as typeof AudioContext;
  globalThis.Notification = MockNotification as unknown as typeof Notification;
  navigator.vibrate = vi.fn(() => true);
  document.title = 'BLIP';
});

afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

describe('useNotification', () => {
  describe('notifyMessage - 탭 활성 시', () => {
    it('사운드만 재생한다 (진동/브라우저 알림 없음)', () => {
      const { result } = renderHook(() => useNotification());

      // 탭 활성 상태 (기본)
      act(() => {
        result.current.notifyMessage('GHOST_7x2k');
      });

      // AudioContext가 생성되고 oscillator가 시작됨
      expect(MockAudioContext).toHaveBeenCalled();
      expect(mockOscillator.start).toHaveBeenCalled();

      // 탭 활성 시 진동/Notification은 호출 안 됨
      expect(navigator.vibrate).not.toHaveBeenCalled();
      expect(MockNotification).not.toHaveBeenCalled();
    });
  });

  describe('notifyMessage - 탭 비활성 시', () => {
    it('사운드 + 진동 + 브라우저 알림 모두 호출', () => {
      const { result } = renderHook(() => useNotification());

      // 탭 비활성 시뮬레이션
      act(() => {
        window.dispatchEvent(new Event('blur'));
      });

      act(() => {
        result.current.notifyMessage('SHADOW_abc2');
      });

      expect(mockOscillator.start).toHaveBeenCalled();
      expect(navigator.vibrate).toHaveBeenCalledWith([80, 40, 80]);
    });

    it('탭 비활성 시 타이틀이 깜빡인다', () => {
      const { result } = renderHook(() => useNotification());

      act(() => {
        window.dispatchEvent(new Event('blur'));
      });

      act(() => {
        result.current.notifyMessage('CIPHER_xyz9');
      });

      // 1초 후 타이틀 변경
      act(() => {
        vi.advanceTimersByTime(1000);
      });

      expect(document.title).toBe('[CIPHER_xyz9] BLIP');

      // 2초 후 원래 타이틀
      act(() => {
        vi.advanceTimersByTime(1000);
      });

      expect(document.title).toBe('BLIP');
    });

    it('탭 포커스 복원 시 타이틀이 원래대로', () => {
      const { result } = renderHook(() => useNotification());

      act(() => {
        window.dispatchEvent(new Event('blur'));
      });

      act(() => {
        result.current.notifyMessage('VOID_1234');
      });

      act(() => {
        vi.advanceTimersByTime(1000);
      });

      // 포커스 복원
      act(() => {
        window.dispatchEvent(new Event('focus'));
      });

      expect(document.title).toBe('BLIP');
    });
  });

  describe('requestPermission', () => {
    it('permission이 "default"이면 requestPermission을 호출한다', async () => {
      Object.defineProperty(MockNotification, 'permission', {
        value: 'default',
        writable: true,
        configurable: true,
      });

      const { result } = renderHook(() => useNotification());

      await act(async () => {
        await result.current.requestPermission();
      });

      expect(MockNotification.requestPermission).toHaveBeenCalled();
    });

    it('이미 "granted"면 requestPermission을 호출하지 않는다', async () => {
      Object.defineProperty(MockNotification, 'permission', {
        value: 'granted',
        writable: true,
        configurable: true,
      });

      MockNotification.requestPermission = vi.fn();

      const { result } = renderHook(() => useNotification());

      await act(async () => {
        await result.current.requestPermission();
      });

      expect(MockNotification.requestPermission).not.toHaveBeenCalled();
    });
  });
});
