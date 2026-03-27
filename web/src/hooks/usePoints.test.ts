import { describe, it, expect } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import { usePoints } from './usePoints';

describe('usePoints', () => {
  it('초기 상태: balance=0, rank=Static, loading=true', () => {
    const { result } = renderHook(() => usePoints());

    expect(result.current.balance).toBe(0);
    expect(result.current.rank.name).toBe('Static');
    expect(result.current.loading).toBe(true);
  });

  it('balance=100 → rank=Signal (50~199)', () => {
    const { result } = renderHook(() => usePoints());

    act(() => {
      result.current.setBalance(100);
    });

    expect(result.current.balance).toBe(100);
    expect(result.current.rank.name).toBe('Signal');
    expect(result.current.rankInfo.emoji).toBe('⚡');
    expect(result.current.rankInfo.color).toBe('blue');
  });

  it('balance=4 → rank=Static (0~4)', () => {
    const { result } = renderHook(() => usePoints());

    act(() => {
      result.current.setBalance(4);
    });

    expect(result.current.rank.name).toBe('Static');
    expect(result.current.rankInfo.emoji).toBe('💀');
    expect(result.current.rankInfo.color).toBe('grey');
  });

  it('balance=5 → rank=Receiver (5~49)', () => {
    const { result } = renderHook(() => usePoints());

    act(() => {
      result.current.setBalance(5);
    });

    expect(result.current.rank.name).toBe('Receiver');
  });

  it('balance=5000 → rank=Oracle (5000+)', () => {
    const { result } = renderHook(() => usePoints());

    act(() => {
      result.current.setBalance(5000);
    });

    expect(result.current.rank.name).toBe('Oracle');
    expect(result.current.rankInfo.emoji).toBe('👑');
    expect(result.current.rankInfo.color).toBe('gold');
  });

  it('balance 변경 시 rank가 자동으로 재계산된다', () => {
    const { result } = renderHook(() => usePoints());

    act(() => {
      result.current.setBalance(50);
    });
    expect(result.current.rank.name).toBe('Signal');

    act(() => {
      result.current.setBalance(200);
    });
    expect(result.current.rank.name).toBe('Decoder');

    act(() => {
      result.current.setBalance(1000);
    });
    expect(result.current.rank.name).toBe('Control');
  });
});
