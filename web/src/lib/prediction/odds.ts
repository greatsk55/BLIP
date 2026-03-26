import { RAKE_RATE, MIN_ODDS, MAX_ODDS } from './constants';

export interface OddsResult {
  yesOdds: number;
  noOdds: number;
}

function clampOdds(odds: number): number {
  return Math.min(MAX_ODDS, Math.max(MIN_ODDS, odds));
}

/**
 * 배당률 계산 (순수 함수)
 * @param totalPool 전체 풀 금액
 * @param yesTotal YES 쪽 총 베팅액
 * @param noTotal NO 쪽 총 베팅액
 */
export function calculateOdds(
  totalPool: number,
  yesTotal: number,
  noTotal: number
): OddsResult {
  if (totalPool < 0 || yesTotal < 0 || noTotal < 0) {
    throw new Error('NEGATIVE_INPUT');
  }

  if (totalPool === 0) {
    return { yesOdds: MIN_ODDS, noOdds: MIN_ODDS };
  }

  const effectivePool = totalPool * (1 - RAKE_RATE);

  const yesOdds = yesTotal === 0 ? MAX_ODDS : clampOdds(effectivePool / yesTotal);
  const noOdds = noTotal === 0 ? MAX_ODDS : clampOdds(effectivePool / noTotal);

  return { yesOdds, noOdds };
}
