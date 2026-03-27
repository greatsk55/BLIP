export interface RakeDistribution {
  creator: number;
  burn: number;
  weeklyPool: number;
}

export interface Winner {
  id: string;
  betAmount: number;
}

export interface PayoutResult {
  id: string;
  payout: number;
}

const MIN_GUARANTEE = 30;
const MIN_GUARANTEE_THRESHOLD = 10;

/**
 * 개별 payout 계산
 */
export function calculatePayout(
  betAmount: number,
  odds: number,
  isWinner: boolean
): number {
  if (!isWinner) return 0;
  return Math.floor(betAmount * odds);
}

/**
 * Rake 분배: 생성자 50%, 소각 30%, 주간풀 20%
 * remainder는 생성자에게 귀속
 */
export function distributeRake(rakeAmount: number): RakeDistribution {
  const burn = Math.floor(rakeAmount * 0.3);
  const weeklyPool = Math.floor(rakeAmount * 0.2);
  const creator = rakeAmount - burn - weeklyPool; // 나머지 포함

  return { creator, burn, weeklyPool };
}

/**
 * 승리자 풀 분배
 * - 비율 기반 배분 (betAmount 비례)
 * - 참여자 10명 이상이면 최소보장 30 BP
 * - 마지막 수혜자가 remainder 수령 → 합 = totalPool 정확히 일치
 */
export function distributePayouts(
  winners: Winner[],
  totalPool: number
): PayoutResult[] {
  if (winners.length === 0) return [];

  const totalBet = winners.reduce((s, w) => s + w.betAmount, 0);
  const applyMinGuarantee = winners.length >= MIN_GUARANTEE_THRESHOLD;

  // 1차: 비율 기반 배분 (floor)
  let results: PayoutResult[] = winners.map((w) => ({
    id: w.id,
    payout: Math.floor((w.betAmount / totalBet) * totalPool),
  }));

  // 최소보장 적용
  if (applyMinGuarantee) {
    results = results.map((r) => ({
      ...r,
      payout: Math.max(r.payout, MIN_GUARANTEE),
    }));
  }

  // remainder 처리: 마지막 수혜자가 수령
  const currentSum = results.reduce((s, r) => s + r.payout, 0);
  const remainder = totalPool - currentSum;
  results[results.length - 1].payout += remainder;

  return results;
}
