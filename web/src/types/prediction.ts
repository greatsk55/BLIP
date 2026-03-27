// ─── 포인트 베팅 시스템 타입 정의 ───

import type { RankThreshold } from '@/lib/prediction/constants';

// ─── 등급 ───

export type Rank = 'Static' | 'Receiver' | 'Signal' | 'Decoder' | 'Control' | 'Oracle';

export interface RankInfo {
  name: Rank;
  emoji: string;
  color: string;
}

// ─── 디바이스 포인트 ───

export interface DevicePoints {
  deviceFingerprint: string;
  balance: number;
  totalEarned: number;
  totalSpent: number;
  totalWon: number;
  totalLost: number;
  rank: Rank;
  rankInfo: RankInfo;
  lastDailyRewardAt: string | null;
}

// ─── 예측 질문 ───

export type PredictionStatus = 'active' | 'closed' | 'settled' | 'cancelled';
export type PredictionType = 'yes_no' | 'multiple';

export interface Prediction {
  id: string;
  creatorFingerprint: string;
  question: string;
  category: string;
  type: PredictionType;
  options: string[];
  correctAnswer: string | null;
  status: PredictionStatus;
  totalPool: number;
  createdAt: string;
  closesAt: string;
  revealsAt: string;
  settledAt: string | null;
}

// ─── 베팅 ───

export type BetStatus = 'pending' | 'won' | 'lost' | 'refunded';

export interface PredictionBet {
  id: string;
  predictionId: string;
  deviceFingerprint: string;
  optionId: string;
  betAmount: number;
  oddsAtBet: number;
  status: BetStatus;
  payout: number | null;
  createdAt: string;
  settledAt: string | null;
}

// ─── 배당률 ───

export interface BetOdds {
  [optionId: string]: number;
}

// ─── 정산 결과 ───

export interface SettlementResult {
  won: boolean;
  betAmount: number;
  odds: number;
  payout: number;
  balanceChange: number;
}

// ─── 에러 ───

export interface PredictionError {
  error: string;
}

export type PredictionResult<T> = T | PredictionError;

// ─── 유틸리티: RankThreshold → RankInfo 변환 ───

export function toRankInfo(threshold: RankThreshold): RankInfo {
  return {
    name: threshold.name as Rank,
    emoji: threshold.emoji,
    color: threshold.color,
  };
}
