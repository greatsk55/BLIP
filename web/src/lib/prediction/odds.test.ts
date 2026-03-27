import { describe, it, expect } from 'vitest';
import { calculateOdds } from './odds';
import { MIN_ODDS, MAX_ODDS } from './constants';

describe('calculateOdds', () => {
  it('기본 배당률: 총풀 1000, YES 800, NO 200', () => {
    // rake 10% 적용: 유효풀 = 1000 * 0.9 = 900
    // YES odds = 900 / 800 = 1.125
    // NO odds = 900 / 200 = 4.5
    const result = calculateOdds(1000, 800, 200);
    expect(result.yesOdds).toBe(1.125);
    expect(result.noOdds).toBe(4.5);
  });

  it('Rake 10%가 적용된다', () => {
    const result = calculateOdds(100, 50, 50);
    // 유효풀 = 90, 각 odds = 90/50 = 1.8
    expect(result.yesOdds).toBe(1.8);
    expect(result.noOdds).toBe(1.8);
  });

  it('최소 배당 1.05x 클램핑', () => {
    // 극단적으로 한쪽에 몰린 경우
    const result = calculateOdds(1000, 999, 1);
    expect(result.yesOdds).toBe(MIN_ODDS);
  });

  it('최대 배당 20.0x 클램핑', () => {
    const result = calculateOdds(10000, 1, 9999);
    expect(result.yesOdds).toBe(MAX_ODDS);
  });

  it('optionTotal=0 이면 MAX_ODDS 반환', () => {
    const result = calculateOdds(1000, 0, 1000);
    expect(result.yesOdds).toBe(MAX_ODDS);
  });

  it('totalPool=0 이면 MIN_ODDS 반환', () => {
    const result = calculateOdds(0, 0, 0);
    expect(result.yesOdds).toBe(MIN_ODDS);
    expect(result.noOdds).toBe(MIN_ODDS);
  });

  it('음수 입력 시 throw', () => {
    expect(() => calculateOdds(-1, 0, 0)).toThrow();
    expect(() => calculateOdds(100, -1, 0)).toThrow();
    expect(() => calculateOdds(100, 0, -1)).toThrow();
  });
});
