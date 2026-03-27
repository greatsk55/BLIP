'use server';

import { headers } from 'next/headers';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { validateBetAmount, validateCreatePrediction } from './validation';
import {
  DAILY_REWARD_INTERVAL_HOURS,
} from './constants';
import { getRank } from './rank';

// ── Rate Limits ──────────────────────────────────────────────

const BET_LIMIT = { windowMs: 60_000, maxRequests: 20 };
const CREATE_LIMIT = { windowMs: 3_600_000, maxRequests: 5 };
const SETTLE_LIMIT = { windowMs: 60_000, maxRequests: 3 };
const REWARD_LIMIT = { windowMs: 3_600_000, maxRequests: 1 };

// ── registerDevice ───────────────────────────────────────────

export async function registerDevice(
  deviceFingerprint: string,
  hardwareHash: string | null
): Promise<{ success: true; balance: number; isNew: boolean } | { error: string }> {
  if (!deviceFingerprint) return { error: 'INVALID_DEVICE' };

  const supabase = createServerSupabase();

  const { data, error } = await supabase.rpc('register_device', {
    p_device_fingerprint: deviceFingerprint,
    p_hardware_hash: hardwareHash,
  });

  if (error) return { error: error.message };

  const row = Array.isArray(data) ? data[0] : data;
  return {
    success: true,
    balance: row.balance,
    isNew: row.is_new,
  };
}

// ── getDevicePoints ──────────────────────────────────────────

export async function getDevicePoints(
  deviceFingerprint: string
): Promise<{
  balance: number;
  totalEarned: number;
  totalWon: number;
  totalLost: number;
} | { error: string }> {
  if (!deviceFingerprint) return { error: 'INVALID_DEVICE' };

  const supabase = createServerSupabase();

  const { data, error } = await supabase
    .from('device_points')
    .select('balance, total_earned, total_won, total_lost')
    .eq('device_fingerprint', deviceFingerprint)
    .single();

  if (error || !data) return { error: 'DEVICE_NOT_FOUND' };

  return {
    balance: data.balance,
    totalEarned: data.total_earned,
    totalWon: data.total_won,
    totalLost: data.total_lost,
  };
}

// ── fetchPredictions ─────────────────────────────────────────

export async function fetchPredictions(
  locale: string = 'en',
  category?: string,
  limit = 20
): Promise<{ predictions: any[] } | { error: string }> {
  const supabase = createServerSupabase();

  let query = supabase
    .from('predictions')
    .select('*')
    .eq('locale', locale)
    .order('created_at', { ascending: false })
    .limit(limit);

  if (category && category !== 'all') {
    query = query.eq('category', category);
  }

  const { data, error } = await query;

  if (error) return { error: error.message };

  // fallback: 해당 locale에 데이터 없으면 'en'으로 재조회
  if ((!data || data.length === 0) && locale !== 'en') {
    let fallbackQuery = supabase
      .from('predictions')
      .select('*')
      .eq('locale', 'en')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (category && category !== 'all') {
      fallbackQuery = fallbackQuery.eq('category', category);
    }

    const { data: fallbackData } = await fallbackQuery;
    return { predictions: fallbackData ?? [] };
  }

  return { predictions: data ?? [] };
}

// ── fetchPrediction (단건) ───────────────────────────────────

export async function fetchPrediction(
  predictionId: string
): Promise<{ prediction: any } | { error: string }> {
  if (!predictionId) return { error: 'INVALID_PREDICTION' };

  const supabase = createServerSupabase();

  const { data, error } = await supabase
    .from('predictions')
    .select('*')
    .eq('id', predictionId)
    .single();

  if (error || !data) return { error: 'PREDICTION_NOT_FOUND' };

  return { prediction: data };
}

// ── fetchOdds (특정 예측의 현재 배당률) ──────────────────────

export async function fetchOdds(
  predictionId: string
): Promise<{ odds: Record<string, number> } | { error: string }> {
  if (!predictionId) return { error: 'INVALID_PREDICTION' };

  const supabase = createServerSupabase();

  // 예측 정보
  const { data: prediction } = await supabase
    .from('predictions')
    .select('total_pool, options')
    .eq('id', predictionId)
    .single();

  if (!prediction) return { error: 'PREDICTION_NOT_FOUND' };

  const totalPool = prediction.total_pool ?? 0;
  const options: string[] = prediction.options ?? ['yes', 'no'];

  // 각 옵션별 베팅 합계
  const { data: bets } = await supabase
    .from('prediction_bets')
    .select('option_id, bet_amount')
    .eq('prediction_id', predictionId)
    .eq('status', 'pending');

  const optionTotals: Record<string, number> = {};
  for (const opt of options) {
    optionTotals[opt] = 0;
  }
  for (const bet of bets ?? []) {
    optionTotals[bet.option_id] = (optionTotals[bet.option_id] ?? 0) + bet.bet_amount;
  }

  // 배당률 계산
  const effectivePool = totalPool * 0.9;
  const odds: Record<string, number> = {};
  for (const opt of options) {
    if (optionTotals[opt] > 0) {
      odds[opt] = Math.min(20.0, Math.max(1.05, effectivePool / optionTotals[opt]));
    } else {
      odds[opt] = 20.0;
    }
  }

  return { odds };
}

// ── fetchMyBets (내 베팅 기록) ────────────────────────────────

export async function fetchMyBets(
  deviceFingerprint: string,
  predictionId?: string
): Promise<{ bets: any[] } | { error: string }> {
  if (!deviceFingerprint) return { error: 'INVALID_DEVICE' };

  const supabase = createServerSupabase();

  let query = supabase
    .from('prediction_bets')
    .select('*, predictions(question, category, status, correct_answer, closes_at)')
    .eq('device_fingerprint', deviceFingerprint)
    .order('created_at', { ascending: false });

  if (predictionId) {
    query = query.eq('prediction_id', predictionId);
  }

  const { data, error } = await query;

  if (error) return { error: error.message };

  return { bets: data ?? [] };
}

// ── fetchMyPredictions (내가 만든 예측) ──────────────────────

export async function fetchMyPredictions(
  deviceFingerprint: string
): Promise<{ predictions: any[] } | { error: string }> {
  if (!deviceFingerprint) return { error: 'INVALID_DEVICE' };

  const supabase = createServerSupabase();

  const { data, error } = await supabase
    .from('predictions')
    .select('*')
    .eq('creator_fingerprint', deviceFingerprint)
    .order('created_at', { ascending: false });

  if (error) return { error: error.message };

  return { predictions: data ?? [] };
}

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
    .from('device_points')
    .select('balance')
    .eq('device_fingerprint', deviceFingerprint)
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
    if (error.code === '23505') return { error: 'DUPLICATE_BET' };
    return { error: error.message };
  }

  const row = Array.isArray(data) ? data[0] : data;
  return { success: true, odds: row.odds, newBalance: row.new_balance };
}

// ── createPrediction ─────────────────────────────────────────

export async function createPrediction(
  deviceFingerprint: string,
  question: string,
  category: string,
  options: string[],
  closesAt: string,
  revealsAt: string,
  locale: string = 'en'
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
    .from('device_points')
    .select('balance, total_earned')
    .eq('device_fingerprint', deviceFingerprint)
    .single();

  if (!device) return { error: 'DEVICE_NOT_FOUND' };

  // 2. 등급별 할인 적용
  const rank = getRank(device.total_earned);
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
    p_locale: locale,
  });

  if (error) return { error: error.message };

  const row = Array.isArray(data) ? data[0] : data;
  return { success: true, predictionId: row.prediction_id };
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
  const validOptions: string[] = Array.isArray(prediction.options)
    ? prediction.options
    : [];
  if (!validOptions.includes(resultOptionId)) {
    return { error: 'INVALID_OPTION' };
  }

  // 3. Supabase RPC (정산 + 배분)
  const { data, error } = await supabase.rpc('settle_prediction', {
    p_prediction_id: predictionId,
    p_result_option_id: resultOptionId,
  });

  if (error) return { error: error.message };

  const row = Array.isArray(data) ? data[0] : data;
  return {
    success: true,
    totalPaid: row.total_paid,
    creatorEarned: row.creator_earned,
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

  // RPC로 보상 지급 (48시간 체크 + 팜 방지 모두 DB에서 처리)
  const { data, error } = await supabase.rpc('claim_daily_reward', {
    p_device_fingerprint: deviceFingerprint,
  });

  if (error) return { error: error.message };

  const row = Array.isArray(data) ? data[0] : data;
  return { success: true, newBalance: row.new_balance };
}
