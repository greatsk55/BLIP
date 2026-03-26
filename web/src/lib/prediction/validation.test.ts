import { describe, it, expect } from 'vitest';
import { validateBetAmount, validateCreatePrediction } from './validation';

describe('validateBetAmount', () => {
  it('0 → 에러', () => {
    const r = validateBetAmount(0, 100);
    expect(r.valid).toBe(false);
  });

  it('-1 → 에러', () => {
    const r = validateBetAmount(-1, 100);
    expect(r.valid).toBe(false);
  });

  it('NaN → 에러', () => {
    const r = validateBetAmount(NaN, 100);
    expect(r.valid).toBe(false);
  });

  it('1.5 (소수) → 에러', () => {
    const r = validateBetAmount(1.5, 100);
    expect(r.valid).toBe(false);
  });

  it('balance 100, amount 51 → 에러 (50% 초과)', () => {
    const r = validateBetAmount(51, 100);
    expect(r.valid).toBe(false);
    expect(r.error).toContain('MAX_BET_PERCENT');
  });

  it('balance 100, amount 50 → 성공', () => {
    const r = validateBetAmount(50, 100);
    expect(r.valid).toBe(true);
  });

  it('balance 1200, amount 500 → 성공', () => {
    const r = validateBetAmount(500, 1200);
    expect(r.valid).toBe(true);
  });

  it('balance 1200, amount 501 → 에러 (MAX_BET_CAP)', () => {
    const r = validateBetAmount(501, 1200);
    expect(r.valid).toBe(false);
    expect(r.error).toContain('MAX_BET_CAP');
  });
});

describe('validateCreatePrediction', () => {
  it('빈 질문 → 에러', () => {
    const r = validateCreatePrediction('', 1000, 'Signal');
    expect(r.valid).toBe(false);
    expect(r.error).toContain('EMPTY_QUESTION');
  });

  it('201자 → 에러', () => {
    const r = validateCreatePrediction('a'.repeat(201), 1000, 'Signal');
    expect(r.valid).toBe(false);
    expect(r.error).toContain('QUESTION_TOO_LONG');
  });

  it('200자 → 성공', () => {
    const r = validateCreatePrediction('a'.repeat(200), 1000, 'Signal');
    expect(r.valid).toBe(true);
  });

  it('balance < 150 → INSUFFICIENT_BALANCE', () => {
    const r = validateCreatePrediction('test question', 149, 'Signal');
    expect(r.valid).toBe(false);
    expect(r.error).toContain('INSUFFICIENT_BALANCE');
  });

  it('rank=Control → cost 120 (20% 할인)', () => {
    const r = validateCreatePrediction('test question', 120, 'Control');
    expect(r.valid).toBe(true);
    expect(r.cost).toBe(120);
  });

  it('rank=Control, balance 119 → INSUFFICIENT_BALANCE', () => {
    const r = validateCreatePrediction('test question', 119, 'Control');
    expect(r.valid).toBe(false);
  });

  it('rank=Oracle → cost 75 (50% 할인)', () => {
    const r = validateCreatePrediction('test question', 75, 'Oracle');
    expect(r.valid).toBe(true);
    expect(r.cost).toBe(75);
  });

  it('일반 랭크 → cost 150', () => {
    const r = validateCreatePrediction('test question', 150, 'Receiver');
    expect(r.valid).toBe(true);
    expect(r.cost).toBe(150);
  });
});
