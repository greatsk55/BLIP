'use server';

import { headers } from 'next/headers';
import { createServerSupabase } from '@/lib/supabase/server';
import { generateRoomId, generateRoomPassword } from '@/lib/room/password';
import { deriveKeysFromPassword, hashAuthKey } from '@/lib/crypto';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

/** 타이밍 공격 방어용 상수시간 문자열 비교 */
function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

/** 관리자 토큰 생성 (비밀번호와 동일 포맷) */
function generateAdminToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(12));
  const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const chars = Array.from(bytes).map((b) => charset[b % charset.length]);
  return `${chars.slice(0, 4).join('')}-${chars.slice(4, 8).join('')}-${chars.slice(8, 12).join('')}`;
}

/** 관리자 토큰 해시 (SHA-256) */
async function hashAdminToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

const CREATE_LIMIT = { windowMs: 3_600_000, maxRequests: 3 };
const VERIFY_LIMIT = { windowMs: 3_600_000, maxRequests: 5 };

/**
 * 그룹 방 생성
 */
export async function createGroupRoom(title: string): Promise<{
  roomId: string;
  password: string;
  adminToken: string;
} | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`create-group:${ip}`, CREATE_LIMIT);
  if (!rateCheck.allowed) {
    return { error: 'TOO_MANY_REQUESTS' };
  }

  const supabase = createServerSupabase();
  const roomId = generateRoomId();
  const password = generateRoomPassword();
  const adminToken = generateAdminToken();

  const { authKey } = await deriveKeysFromPassword(password, roomId);
  const authKeyHash = await hashAuthKey(authKey);
  const adminTokenHash = await hashAdminToken(adminToken);

  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const { error } = await supabase.from('rooms').insert({
    id: roomId,
    auth_key_hash: authKeyHash,
    created_at: new Date().toISOString(),
    expires_at: expiresAt,
    status: 'waiting',
    participant_count: 0,
    type: 'group',
    max_participants: null,
    title: title.trim() || 'Untitled Group',
    admin_token_hash: adminTokenHash,
    is_locked: false,
    banned_tokens: [],
  });

  if (error) {
    return { error: 'Failed to create group room' };
  }

  return { roomId, password, adminToken };
}

/**
 * 그룹방 비밀번호 검증 (participant_count 제한 없음)
 */
export async function verifyGroupPassword(
  roomId: string,
  password: string
): Promise<{ valid: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`verify-group:${ip}:${roomId}`, VERIFY_LIMIT);
  if (!rateCheck.allowed) {
    return { valid: false, error: 'TOO_MANY_REQUESTS' };
  }

  const supabase = createServerSupabase();

  const { data: room, error } = await supabase
    .from('rooms')
    .select('auth_key_hash, status, expires_at, is_locked, type')
    .eq('id', roomId)
    .single();

  if (error || !room) {
    return { valid: false, error: 'ROOM_NOT_FOUND' };
  }

  if (room.type !== 'group') {
    return { valid: false, error: 'NOT_GROUP_ROOM' };
  }

  if (room.status === 'destroyed') {
    return { valid: false, error: 'ROOM_DESTROYED' };
  }

  if (new Date(room.expires_at) < new Date()) {
    return { valid: false, error: 'ROOM_EXPIRED' };
  }

  if (room.is_locked) {
    return { valid: false, error: 'ROOM_LOCKED' };
  }

  const { authKey } = await deriveKeysFromPassword(password, roomId);
  const authKeyHash = await hashAuthKey(authKey);

  if (!constantTimeEqual(authKeyHash, room.auth_key_hash)) {
    return { valid: false, error: 'INVALID_PASSWORD' };
  }

  return { valid: true };
}

/**
 * 그룹방 상태 확인
 */
export async function getGroupRoomStatus(
  roomId: string
): Promise<{ exists: boolean; status?: string; title?: string; type?: string; error?: string }> {
  const supabase = createServerSupabase();

  const { data: room, error } = await supabase
    .from('rooms')
    .select('status, expires_at, title, type')
    .eq('id', roomId)
    .single();

  if (error || !room) {
    return { exists: false };
  }

  if (room.type !== 'group') {
    return { exists: false, error: 'NOT_GROUP_ROOM' };
  }

  if (new Date(room.expires_at) < new Date()) {
    return { exists: true, status: 'expired' };
  }

  return { exists: true, status: room.status, title: room.title };
}

/**
 * 관리자 토큰 검증
 */
export async function verifyAdminToken(
  roomId: string,
  adminToken: string
): Promise<boolean> {
  const supabase = createServerSupabase();

  const { data: room } = await supabase
    .from('rooms')
    .select('admin_token_hash')
    .eq('id', roomId)
    .single();

  if (!room?.admin_token_hash) return false;

  const tokenHash = await hashAdminToken(adminToken);
  return constantTimeEqual(tokenHash, room.admin_token_hash);
}

/**
 * 그룹방 참여자 수 업데이트
 */
export async function updateGroupParticipantCount(
  roomId: string,
  count: number,
  authKeyHash: string
): Promise<void> {
  if (!authKeyHash) return;
  const supabase = createServerSupabase();

  // 그룹채팅은 참여자가 0이 되어도 파쇄하지 않음 (waiting 상태로 유지)
  // 방 파쇄는 관리자의 명시적 destroyGroupRoom()으로만 가능
  await supabase
    .from('rooms')
    .update({
      participant_count: Math.max(0, count),
      status: count > 0 ? 'active' : 'waiting',
    })
    .eq('id', roomId)
    .eq('auth_key_hash', authKeyHash)
    .eq('type', 'group')
    .neq('status', 'destroyed');
}

/**
 * 그룹방 잠금/해제
 */
export async function toggleGroupLock(
  roomId: string,
  adminToken: string,
  lock: boolean
): Promise<{ success: boolean }> {
  const isAdmin = await verifyAdminToken(roomId, adminToken);
  if (!isAdmin) return { success: false };

  const supabase = createServerSupabase();
  await supabase
    .from('rooms')
    .update({ is_locked: lock })
    .eq('id', roomId);

  return { success: true };
}

/**
 * 그룹방 폭파 (관리자)
 */
export async function destroyGroupRoom(
  roomId: string,
  adminToken: string
): Promise<{ success: boolean }> {
  const isAdmin = await verifyAdminToken(roomId, adminToken);
  if (!isAdmin) return { success: false };

  const supabase = createServerSupabase();
  await supabase
    .from('rooms')
    .update({ status: 'destroyed', participant_count: 0 })
    .eq('id', roomId);

  return { success: true };
}

/**
 * 사용자 밴 (관리자)
 */
export async function banUserFromGroup(
  roomId: string,
  adminToken: string,
  userToken: string
): Promise<{ success: boolean }> {
  const isAdmin = await verifyAdminToken(roomId, adminToken);
  if (!isAdmin) return { success: false };

  const supabase = createServerSupabase();

  const { data: room } = await supabase
    .from('rooms')
    .select('banned_tokens')
    .eq('id', roomId)
    .single();

  if (!room) return { success: false };

  const banned = room.banned_tokens || [];
  if (!banned.includes(userToken)) {
    banned.push(userToken);
  }

  await supabase
    .from('rooms')
    .update({ banned_tokens: banned })
    .eq('id', roomId);

  return { success: true };
}

/**
 * 밴 여부 확인
 */
export async function isUserBanned(
  roomId: string,
  userToken: string
): Promise<boolean> {
  const supabase = createServerSupabase();

  const { data: room } = await supabase
    .from('rooms')
    .select('banned_tokens')
    .eq('id', roomId)
    .single();

  if (!room) return false;
  return (room.banned_tokens || []).includes(userToken);
}

/**
 * 예측(투표) 전용 토론방 생성 또는 기존 방 반환
 * - 예측 ID당 하나의 그룹채팅방만 존재
 * - 이미 있으면 기존 방 정보 반환
 */
export async function getOrCreateDiscussionRoom(
  predictionId: string,
  predictionQuestion: string,
): Promise<{
  roomId: string;
  password: string;
} | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`discuss:${ip}`, CREATE_LIMIT);
  if (!rateCheck.allowed) {
    return { error: 'TOO_MANY_REQUESTS' };
  }

  const supabase = createServerSupabase();

  // 기존 토론방 조회
  const { data: existing } = await supabase
    .from('rooms')
    .select('id, auth_key_hash, status, expires_at')
    .eq('prediction_id', predictionId)
    .neq('status', 'destroyed')
    .single();

  if (existing && new Date(existing.expires_at) > new Date()) {
    // 기존 방이 있고 유효함 → 비밀번호는 prediction ID 기반 고정 생성
    const password = await derivePredictionPassword(predictionId);
    return { roomId: existing.id, password };
  }

  // 새 방 생성
  const roomId = generateRoomId();
  const password = await derivePredictionPassword(predictionId);
  const adminToken = generateAdminToken();

  const { authKey } = await deriveKeysFromPassword(password, roomId);
  const authKeyHash = await hashAuthKey(authKey);
  const adminTokenHash = await hashAdminToken(adminToken);

  const title = predictionQuestion.length > 40
    ? predictionQuestion.slice(0, 40) + '...'
    : predictionQuestion;

  // 토론방은 7일 TTL (예측 마감까지 충분한 시간)
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();

  const { error } = await supabase.from('rooms').insert({
    id: roomId,
    auth_key_hash: authKeyHash,
    created_at: new Date().toISOString(),
    expires_at: expiresAt,
    status: 'waiting',
    participant_count: 0,
    type: 'group',
    max_participants: null,
    title: `💬 ${title}`,
    admin_token_hash: adminTokenHash,
    is_locked: false,
    banned_tokens: [],
    prediction_id: predictionId,
  });

  if (error) {
    // UNIQUE 제약 위반 → 동시 생성 경쟁 → 재조회
    if (error.code === '23505') {
      const { data: race } = await supabase
        .from('rooms')
        .select('id')
        .eq('prediction_id', predictionId)
        .neq('status', 'destroyed')
        .single();
      if (race) {
        return { roomId: race.id, password };
      }
    }
    return { error: 'CREATION_FAILED' };
  }

  return { roomId, password };
}

/**
 * prediction ID로부터 결정적 비밀번호 파생
 * - 같은 예측 → 같은 비밀번호 → 누구나 참여 가능
 */
async function derivePredictionPassword(predictionId: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(`blip-discuss:${predictionId}`);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  // 처음 12바이트로 비밀번호 생성 (Base32-like)
  const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const chars = hashArray.slice(0, 12).map((b) => charset[b % charset.length]);
  return `${chars.slice(0, 4).join('')}-${chars.slice(4, 8).join('')}-${chars.slice(8, 12).join('')}`;
}
