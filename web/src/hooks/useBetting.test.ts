import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { useBetting } from './useBetting';

describe('useBetting', () => {
  it('betAmount 변경 → expectedPayout = floor(amount * odds)', () => {
    const { result } = renderHook(() => useBetting(100, 1.8));

    // 초기값: betAmount=1, expectedPayout=floor(1*1.8)=1
    expect(result.current.betAmount).toBe(1);
    expect(result.current.expectedPayout).toBe(1);

    act(() => {
      result.current.setBetAmount(10);
    });

    // floor(10 * 1.8) = floor(18) = 18
    expect(result.current.expectedPayout).toBe(18);
  });

  it('maxBet = min(floor(balance * 0.5), 500)', () => {
    const { result } = renderHook(() => useBetting(100, 2.0));

    // min(floor(100 * 0.5), 500) = min(50, 500) = 50
    expect(result.current.maxBet).toBe(50);
  });

  it('balance=100 → maxBet=50', () => {
    const { result } = renderHook(() => useBetting(100, 1.5));
    expect(result.current.maxBet).toBe(50);
  });

  it('balance=2000 → maxBet=500 (CAP 적용)', () => {
    const { result } = renderHook(() => useBetting(2000, 1.5));

    // min(floor(2000 * 0.5), 500) = min(1000, 500) = 500
    expect(result.current.maxBet).toBe(500);
  });

  it('balance=0 → maxBet=0', () => {
    const { result } = renderHook(() => useBetting(0, 2.0));
    expect(result.current.maxBet).toBe(0);
  });

  it('odds 변경 시 expectedPayout이 재계산된다', () => {
    const { result, rerender } = renderHook(
      ({ balance, odds }) => useBetting(balance, odds),
      { initialProps: { balance: 100, odds: 2.0 } }
    );

    act(() => {
      result.current.setBetAmount(10);
    });
    expect(result.current.expectedPayout).toBe(20); // floor(10 * 2.0)

    rerender({ balance: 100, odds: 3.5 });
    expect(result.current.expectedPayout).toBe(35); // floor(10 * 3.5)
  });

  it('balance 변경 시 maxBet이 재계산된다', () => {
    const { result, rerender } = renderHook(
      ({ balance, odds }) => useBetting(balance, odds),
      { initialProps: { balance: 100, odds: 2.0 } }
    );

    expect(result.current.maxBet).toBe(50);

    rerender({ balance: 500, odds: 2.0 });
    expect(result.current.maxBet).toBe(250);
  });
});
