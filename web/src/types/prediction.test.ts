import { describe, it, expect } from 'vitest';
import type {
  Rank,
  RankInfo,
  DevicePoints,
  Prediction,
  PredictionBet,
  BetOdds,
  SettlementResult,
  PredictionError,
  PredictionResult,
} from './prediction';
import { toRankInfo } from './prediction';
import { RANK_THRESHOLDS } from '@/lib/prediction/constants';

describe('prediction types', () => {
  it('Rank 타입은 6개 등급만 허용한다', () => {
    const ranks: Rank[] = ['Static', 'Receiver', 'Signal', 'Decoder', 'Control', 'Oracle'];
    expect(ranks).toHaveLength(6);
  });

  it('RankInfo 구조가 올바르다', () => {
    const info: RankInfo = { name: 'Static', emoji: '💀', color: 'grey' };
    expect(info.name).toBe('Static');
    expect(info.emoji).toBe('💀');
    expect(info.color).toBe('grey');
  });

  it('DevicePoints 기본 구조 검증', () => {
    const dp: DevicePoints = {
      deviceFingerprint: 'abc123',
      balance: 100,
      totalEarned: 200,
      totalSpent: 100,
      totalWon: 150,
      totalLost: 50,
      rank: 'Signal',
      rankInfo: { name: 'Signal', emoji: '⚡', color: 'blue' },
      lastDailyRewardAt: null,
    };
    expect(dp.balance).toBe(100);
    expect(dp.rank).toBe('Signal');
  });

  it('Prediction 구조 검증', () => {
    const p: Prediction = {
      id: 'pred-1',
      creatorFingerprint: 'dev-1',
      question: 'BTC 10만불 돌파?',
      category: 'crypto',
      type: 'yes_no',
      options: ['yes', 'no'],
      correctAnswer: null,
      status: 'active',
      totalPool: 1000,
      createdAt: '2026-01-01T00:00:00Z',
      closesAt: '2026-01-02T00:00:00Z',
      revealsAt: '2026-01-03T00:00:00Z',
      settledAt: null,
    };
    expect(p.status).toBe('active');
    expect(p.options).toHaveLength(2);
  });

  it('PredictionBet 구조 검증', () => {
    const bet: PredictionBet = {
      id: 'bet-1',
      predictionId: 'pred-1',
      deviceFingerprint: 'dev-1',
      optionId: 'yes',
      betAmount: 50,
      oddsAtBet: 1.8,
      status: 'pending',
      payout: null,
      createdAt: '2026-01-01T00:00:00Z',
      settledAt: null,
    };
    expect(bet.betAmount).toBe(50);
    expect(bet.status).toBe('pending');
  });

  it('BetOdds는 동적 키를 허용한다', () => {
    const odds: BetOdds = { yes: 1.8, no: 2.1 };
    expect(odds['yes']).toBe(1.8);
    expect(odds['no']).toBe(2.1);
  });

  it('SettlementResult 구조 검증', () => {
    const result: SettlementResult = {
      won: true,
      betAmount: 50,
      odds: 1.8,
      payout: 90,
      balanceChange: 40,
    };
    expect(result.balanceChange).toBe(40);
  });

  it('PredictionResult<T>는 성공 또는 에러를 반환한다', () => {
    const success: PredictionResult<SettlementResult> = {
      won: true,
      betAmount: 50,
      odds: 1.8,
      payout: 90,
      balanceChange: 40,
    };
    const error: PredictionResult<SettlementResult> = { error: 'INSUFFICIENT_BALANCE' };

    expect('error' in error).toBe(true);
    expect('won' in success).toBe(true);
  });

  it('toRankInfo는 RankThreshold를 RankInfo로 변환한다', () => {
    const info = toRankInfo(RANK_THRESHOLDS[0]);
    expect(info).toEqual({ name: 'Static', emoji: '💀', color: 'grey' });
  });

  it('toRankInfo는 모든 RANK_THRESHOLDS에 대해 동작한다', () => {
    RANK_THRESHOLDS.forEach((t) => {
      const info = toRankInfo(t);
      expect(info.name).toBe(t.name);
      expect(info.emoji).toBe(t.emoji);
      expect(info.color).toBe(t.color);
    });
  });
});
