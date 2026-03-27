import {
  MIN_BET,
  MAX_BET_CAP,
  MAX_BET_PERCENT,
  CREATION_COST,
  CREATION_COST_DISCOUNT,
} from './constants';

export interface ValidationResult {
  valid: boolean;
  error?: string;
  cost?: number;
}

/**
 * 베팅 금액 유효성 검증
 */
export function validateBetAmount(
  amount: number,
  balance: number
): ValidationResult {
  if (!Number.isFinite(amount) || !Number.isInteger(amount) || amount < MIN_BET) {
    return { valid: false, error: 'INVALID_AMOUNT' };
  }

  if (amount > MAX_BET_CAP) {
    return { valid: false, error: 'MAX_BET_CAP' };
  }

  const maxByPercent = Math.floor(balance * MAX_BET_PERCENT);
  if (amount > maxByPercent) {
    return { valid: false, error: 'MAX_BET_PERCENT' };
  }

  return { valid: true };
}

/**
 * 예측 생성 유효성 검증
 */
export function validateCreatePrediction(
  question: string,
  balance: number,
  rank: string
): ValidationResult {
  if (!question || question.trim().length === 0) {
    return { valid: false, error: 'EMPTY_QUESTION' };
  }

  if (question.length > 200) {
    return { valid: false, error: 'QUESTION_TOO_LONG' };
  }

  const discount = CREATION_COST_DISCOUNT[rank] ?? 1;
  const cost = Math.floor(CREATION_COST * discount);

  if (balance < cost) {
    return { valid: false, error: 'INSUFFICIENT_BALANCE' };
  }

  return { valid: true, cost };
}
