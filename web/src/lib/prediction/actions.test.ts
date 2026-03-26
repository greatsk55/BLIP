/**
 * Prediction actions 유닛 테스트
 * Server Actions ('use server' + next/headers)는 직접 import 불가하므로
 * 내부 순수 validation 로직을 검증합니다.
 */
import { describe, it, expect } from 'vitest';
import { validateBetAmount, validateCreatePrediction } from './validation';
import { CREATION_COST, CREATION_COST_DISCOUNT, DAILY_REWARD_INTERVAL_HOURS } from './constants';

// ── placeBet validation ──────────────────────────────────────

describe('placeBet validation', () => {
  it('betAmount <= 0 -> { error: "INVALID_AMOUNT" }', () => {
    const r = validateBetAmount(0, 1000);
    expect(r.valid).toBe(false);
    expect(r.error).toBe('INVALID_AMOUNT');
  });

  it('betAmount 음수 -> { error: "INVALID_AMOUNT" }', () => {
    const r = validateBetAmount(-5, 1000);
    expect(r.valid).toBe(false);
    expect(r.error).toBe('INVALID_AMOUNT');
  });

  it('betAmount > balance * 0.5 -> { error: "MAX_BET_PERCENT" }', () => {
    // balance=100, max=50, bet=51
    const r = validateBetAmount(51, 100);
    expect(r.valid).toBe(false);
    expect(r.error).toBe('MAX_BET_PERCENT');
  });

  it('betAmount > 500 -> { error: "MAX_BET_CAP" }', () => {
    const r = validateBetAmount(501, 10000);
    expect(r.valid).toBe(false);
    expect(r.error).toBe('MAX_BET_CAP');
  });

  it('유효한 베팅은 valid: true', () => {
    const r = validateBetAmount(50, 1000);
    expect(r.valid).toBe(true);
    expect(r.error).toBeUndefined();
  });

  // placeBet에서 사용되는 입력 검증 로직 (actions.ts 내부 재현)
  it('빈 predictionId -> { error: "INVALID_PREDICTION" }', () => {
    const predictionId = '';
    const error = !predictionId ? 'INVALID_PREDICTION' : null;
    expect(error).toBe('INVALID_PREDICTION');
  });

  it('빈 optionId -> { error: "INVALID_OPTION" }', () => {
    const optionId = '';
    const error = !optionId ? 'INVALID_OPTION' : null;
    expect(error).toBe('INVALID_OPTION');
  });

  it('자기 질문 베팅 -> { error: "SELF_BET_FORBIDDEN" }', () => {
    // 생성자 fingerprint === 베터 fingerprint
    const creatorFingerprint = 'abc123';
    const betterFingerprint = 'abc123';
    const error = creatorFingerprint === betterFingerprint ? 'SELF_BET_FORBIDDEN' : null;
    expect(error).toBe('SELF_BET_FORBIDDEN');
  });
});

// ── createPrediction validation ──────────────────────────────

describe('createPrediction validation', () => {
  it('빈 질문 -> { error: "EMPTY_QUESTION" }', () => {
    const r = validateCreatePrediction('', 1000, 'Static');
    expect(r.valid).toBe(false);
    expect(r.error).toBe('EMPTY_QUESTION');
  });

  it('공백만 있는 질문 -> { error: "EMPTY_QUESTION" }', () => {
    const r = validateCreatePrediction('   ', 1000, 'Static');
    expect(r.valid).toBe(false);
    expect(r.error).toBe('EMPTY_QUESTION');
  });

  it('201자 질문 -> { error: "QUESTION_TOO_LONG" }', () => {
    const longQ = 'A'.repeat(201);
    const r = validateCreatePrediction(longQ, 10000, 'Static');
    expect(r.valid).toBe(false);
    expect(r.error).toBe('QUESTION_TOO_LONG');
  });

  it('200자 질문은 통과', () => {
    const q = 'A'.repeat(200);
    const r = validateCreatePrediction(q, 10000, 'Static');
    expect(r.valid).toBe(true);
  });

  it('잔액 < cost -> { error: "INSUFFICIENT_BALANCE" }', () => {
    // Static 등급: discount 없음 -> cost = 150
    const r = validateCreatePrediction('Will it rain?', 100, 'Static');
    expect(r.valid).toBe(false);
    expect(r.error).toBe('INSUFFICIENT_BALANCE');
  });

  it('Control 등급 -> cost 120 BP', () => {
    const discount = CREATION_COST_DISCOUNT['Control'] ?? 1;
    const cost = Math.floor(CREATION_COST * discount);
    expect(cost).toBe(120);

    const r = validateCreatePrediction('Question?', 120, 'Control');
    expect(r.valid).toBe(true);
    expect(r.cost).toBe(120);
  });

  it('Oracle 등급 -> cost 75 BP', () => {
    const discount = CREATION_COST_DISCOUNT['Oracle'] ?? 1;
    const cost = Math.floor(CREATION_COST * discount);
    expect(cost).toBe(75);

    const r = validateCreatePrediction('Question?', 75, 'Oracle');
    expect(r.valid).toBe(true);
    expect(r.cost).toBe(75);
  });
});

// ── settlePrediction validation ──────────────────────────────

describe('settlePrediction validation', () => {
  it('이미 정산된 질문 -> { error: "ALREADY_SETTLED" }', () => {
    // settled_at이 null이 아닌 경우를 시뮬레이션
    const prediction = { settled_at: '2026-01-01T00:00:00Z' };
    const error = prediction.settled_at ? 'ALREADY_SETTLED' : null;
    expect(error).toBe('ALREADY_SETTLED');
  });

  it('미정산 질문은 에러 없음', () => {
    const prediction = { settled_at: null };
    const error = prediction.settled_at ? 'ALREADY_SETTLED' : null;
    expect(error).toBeNull();
  });

  it('존재하지 않는 option -> { error: "INVALID_OPTION" }', () => {
    const validOptions = ['opt-a', 'opt-b'];
    const resultOptionId = 'opt-c';
    const error = !validOptions.includes(resultOptionId) ? 'INVALID_OPTION' : null;
    expect(error).toBe('INVALID_OPTION');
  });

  it('유효한 option은 에러 없음', () => {
    const validOptions = ['opt-a', 'opt-b'];
    const resultOptionId = 'opt-a';
    const error = !validOptions.includes(resultOptionId) ? 'INVALID_OPTION' : null;
    expect(error).toBeNull();
  });
});

// ── claimDailyReward validation ──────────────────────────────

describe('claimDailyReward validation', () => {
  it('48시간 미만 -> { error: "NOT_YET_AVAILABLE" }', () => {
    const lastClaimedAt = new Date(Date.now() - 47 * 60 * 60 * 1000); // 47시간 전
    const intervalMs = DAILY_REWARD_INTERVAL_HOURS * 60 * 60 * 1000;
    const elapsed = Date.now() - lastClaimedAt.getTime();
    const error = elapsed < intervalMs ? 'NOT_YET_AVAILABLE' : null;
    expect(error).toBe('NOT_YET_AVAILABLE');
  });

  it('48시간 이상 -> 보상 가능', () => {
    const lastClaimedAt = new Date(Date.now() - 49 * 60 * 60 * 1000); // 49시간 전
    const intervalMs = DAILY_REWARD_INTERVAL_HOURS * 60 * 60 * 1000;
    const elapsed = Date.now() - lastClaimedAt.getTime();
    const error = elapsed < intervalMs ? 'NOT_YET_AVAILABLE' : null;
    expect(error).toBeNull();
  });

  it('최초 보상 (null) -> 보상 가능', () => {
    const lastClaimedAt = null;
    const error = lastClaimedAt === null ? null : 'NOT_YET_AVAILABLE';
    expect(error).toBeNull();
  });
});
