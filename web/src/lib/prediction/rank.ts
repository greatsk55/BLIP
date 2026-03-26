import { RANK_THRESHOLDS, type RankThreshold } from './constants';

export interface RankBadge {
  emoji: string;
  color: string;
}

/**
 * 포인트 기반 랭크 조회
 * 음수는 Static(최저)으로 처리
 */
export function getRank(points: number): RankThreshold {
  const p = Math.max(0, points);
  const rank = RANK_THRESHOLDS.find((t) => p >= t.min && p <= t.max);
  return rank ?? RANK_THRESHOLDS[0];
}

/**
 * 랭크 뱃지(emoji + color) 반환
 */
export function getRankBadge(points: number): RankBadge {
  const rank = getRank(points);
  return { emoji: rank.emoji, color: rank.color };
}
