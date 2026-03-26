'use server';

import { headers } from 'next/headers';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { validateBetAmount, validateCreatePrediction } from './validation';
import {
  CREATION_COST,
  CREATION_COST_DISCOUNT,
  DAILY_REWARD,
  DAILY_REWARD_INTERVAL_HOURS,
} from './constants';
import { getRank } from './rank';

// ── Rate Limits ──────────────────────────────────────────────

const BET_LIMIT = { windowMs: 60_000, maxRequests: 20 };
const CREATE_LIMIT = { windowMs: 3_600_000, maxRequests: 5 };
const SETTLE_LIMIT = { windowMs: 60_000, maxRequests: 3 };
const REWARD_LIMIT = { windowMs: 3_600_000, maxRequests: 1 };

// ── placeBet ─────────────────────────────────────────────────

export async function placeBet(
  predictionId: string,
  deviceFingerprint: string,
  optionId: string,
  betAmount: number,
  idempotencyKey: string
): Promise<{ success: true; odds: number; newBalance: number } | { error: string }> {
  // 1. Rate limit
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`bet:${ip}`, BET_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  // 2. 입력 검증
  if (!predictionId) return { error: 'INVALID_PREDICTION' };
  if (!optionId) return { error: 'INVALID_OPTION' };
  if (!deviceFingerprint) return { error: 'INVALID_DEVICE' };

  const supabase = createServerSupabase();

  // 디바이스 잔액 조회
  const { data: device } = await supabase
    .from('prediction_devices')
    .select('balance')
    .eq('fingerprint_hash', deviceFingerprint)
    .single();

  if (!device) return { error: 'DEVICE_NOT_FOUND' };

  // 금액 검증 (validation.ts 재사용)
  const validation = validateBetAmount(betAmount, device.balance);
  if (!validation.valid) return { error: validation.error! };

  // 자기 질문 베팅 방지
  const { data: prediction } = await supabase
    .from('predictions')
    .select('creator_fingerprint, settled_at')
    .eq('id', predictionId)
    .single();

  if (!prediction) return { error: 'PREDICTION_NOT_FOUND' };
  if (prediction.settled_at) return { error: 'ALREADY_SETTLED' };
  if (prediction.creator_fingerprint === deviceFingerprint) {
    return { error: 'SELF_BET_FORBIDDEN' };
  }

  // 3. Supabase RPC 호출 (원자적 베팅 + 배당률 계산)
  const { data, error } = await supabase.rpc('calculate_odds_and_place_bet', {
    p_prediction_id: predictionId,
    p_device_fingerprint: deviceFingerprint,
    p_option_id: optionId,
    p_bet_amount: betAmount,
    p_idempotency_key: idempotencyKey,
  });

  if (error) {
    // 멱등성 키 중복은 성공으로 처리 (이미 처리된 베팅)
    if (error.code === '23505') return { error: 'DUPLICATE_BET' };
    return { error: error.message };
  }

  return { success: true, odds: data.odds, newBalance: data.new_balance };
}

// ── createPrediction ─────────────────────────────────────────

export async function createPrediction(
  deviceFingerprint: string,
  question: string,
  category: string,
  options: string[],
  closesAt: string,
  revealsAt: string
): Promise<{ success: true; predictionId: string } | { error: string }> {
  // 1. Rate limit
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`create-pred:${ip}`, CREATE_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  if (!deviceFingerprint) return { error: 'INVALID_DEVICE' };
  if (!options || options.length < 2) return { error: 'INSUFFICIENT_OPTIONS' };

  const supabase = createServerSupabase();

  // 디바이스 정보 조회
  const { data: device } = await supabase
    .from('prediction_devices')
    .select('balance, total_points')
    .eq('fingerprint_hash', deviceFingerprint)
    .single();

  if (!device) return { error: 'DEVICE_NOT_FOUND' };

  // 2. 등급별 할인 적용
  const rank = getRank(device.total_points);
  const validation = validateCreatePrediction(question, device.balance, rank.name);
  if (!validation.valid) return { error: validation.error! };

  const cost = validation.cost!;

  // 3. 원자적: balance 차감 + prediction 생성
  const { data, error } = await supabase.rpc('create_prediction_atomic', {
    p_device_fingerprint: deviceFingerprint,
    p_question: question.trim(),
    p_category: category,
    p_options: options,
    p_closes_at: closesAt,
    p_reveals_at: revealsAt,
    p_cost: cost,
  });

  if (error) return { error: error.message };

  return { success: true, predictionId: data.prediction_id };
}

// ── settlePrediction ─────────────────────────────────────────

export async function settlePrediction(
  predictionId: string,
  resultOptionId: string,
  creatorFingerprint: string
): Promise<{ success: true; totalPaid: number; creatorEarned: number } | { error: string }> {
  // 1. Rate limit
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`settle:${ip}`, SETTLE_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  if (!predictionId) return { error: 'INVALID_PREDICTION' };
  if (!resultOptionId) return { error: 'INVALID_OPTION' };
  if (!creatorFingerprint) return { error: 'INVALID_DEVICE' };

  const supabase = createServerSupabase();

  // 2. 생성자 검증 + 정산 여부 확인
  const { data: prediction } = await supabase
    .from('predictions')
    .select('creator_fingerprint, settled_at, options')
    .eq('id', predictionId)
    .single();

  if (!prediction) return { error: 'PREDICTION_NOT_FOUND' };
  if (prediction.creator_fingerprint !== creatorFingerprint) {
    return { error: 'NOT_CREATOR' };
  }
  if (prediction.settled_at) return { error: 'ALREADY_SETTLED' };

  // option 유효성 검증
  const validOptions: string[] = (prediction.options ?? []).map(
    (o: { id: string }) => o.id
  );
  if (!validOptions.includes(resultOptionId)) {
    return { error: 'INVALID_OPTION' };
  }

  // 3. Supabase RPC (정산 + 배분)
  const { data, error } = await supabase.rpc('settle_prediction', {
    p_prediction_id: predictionId,
    p_result_option_id: resultOptionId,
    p_creator_fingerprint: creatorFingerprint,
  });

  if (error) return { error: error.message };

  return {
    success: true,
    totalPaid: data.total_paid,
    creatorEarned: data.creator_earned,
  };
}

// ── claimDailyReward ─────────────────────────────────────────

export async function claimDailyReward(
  deviceFingerprint: string
): Promise<{ success: true; newBalance: number } | { error: string }> {
  // 1. Rate limit
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`reward:${ip}`, REWARD_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  if (!deviceFingerprint) return { error: 'INVALID_DEVICE' };

  const supabase = createServerSupabase();

  // 디바이스 조회
  const { data: device } = await supabase
    .from('prediction_devices')
    .select('balance, last_reward_at')
    .eq('fingerprint_hash', deviceFingerprint)
    .single();

  if (!device) return { error: 'DEVICE_NOT_FOUND' };

  // 2. 시간 검증
  if (device.last_reward_at) {
    const intervalMs = DAILY_REWARD_INTERVAL_HOURS * 60 * 60 * 1000;
    const elapsed = Date.now() - new Date(device.last_reward_at).getTime();
    if (elapsed < intervalMs) {
      return { error: 'NOT_YET_AVAILABLE' };
    }
  }

  // 3. 보상 지급
  const newBalance = device.balance + DAILY_REWARD;
  const { error } = await supabase
    .from('prediction_devices')
    .update({
      balance: newBalance,
      last_reward_at: new Date().toISOString(),
    })
    .eq('fingerprint_hash', deviceFingerprint);

  if (error) return { error: error.message };

  return { success: true, newBalance };
}
