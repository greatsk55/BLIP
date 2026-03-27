import { describe, it, expect } from 'vitest';
import { calculatePayout, distributeRake, distributePayouts } from './payout';

describe('calculatePayout', () => {
  it('승리자 payout = betAmount * odds (floor)', () => {
    expect(calculatePayout(100, 2.5, true)).toBe(250);
    expect(calculatePayout(33, 3.3, true)).toBe(108); // floor(108.9)
  });

  it('패배자 payout = 0', () => {
    expect(calculatePayout(100, 2.5, false)).toBe(0);
  });
});

describe('distributeRake', () => {
  it('Rake 100 → 생성자 50, 소각 30, 주간풀 20', () => {
    const result = distributeRake(100);
    expect(result.creator).toBe(50);
    expect(result.burn).toBe(30);
    expect(result.weeklyPool).toBe(20);
  });

  it('합이 원래 rake와 같다', () => {
    const result = distributeRake(77);
    expect(result.creator + result.burn + result.weeklyPool).toBe(77);
  });
});

describe('distributePayouts', () => {
  it('remainder: 마지막 수혜자가 나머지 수령 (합 = 풀 정확히 일치)', () => {
    const winners = [
      { id: 'a', betAmount: 30 },
      { id: 'b', betAmount: 30 },
      { id: 'c', betAmount: 40 },
    ];
    const totalPool = 900; // rake 적용 후
    const result = distributePayouts(winners, totalPool);
    const sum = result.reduce((s, r) => s + r.payout, 0);
    expect(sum).toBe(totalPool);
  });

  it('참여자 10명 이상 최소보장 30 BP', () => {
    const winners = Array.from({ length: 10 }, (_, i) => ({
      id: `w${i}`,
      betAmount: i === 0 ? 1 : 100,
    }));
    const totalPool = 5000;
    const result = distributePayouts(winners, totalPool);
    // 가장 작은 베팅자도 최소 30 BP
    const minPayout = Math.min(...result.map((r) => r.payout));
    expect(minPayout).toBeGreaterThanOrEqual(30);
  });

  it('승리자 0명 → 전액 환불 배열', () => {
    const result = distributePayouts([], 900);
    expect(result).toEqual([]);
  });
});
