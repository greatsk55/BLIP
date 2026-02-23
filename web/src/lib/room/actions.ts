'use server';

import { headers } from 'next/headers';
import { createServerSupabase } from '@/lib/supabase/server';
import { generateRoomId, generateRoomPassword } from './password';
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

// IP당 1시간에 3개 방 생성
const CREATE_ROOM_LIMIT = { windowMs: 3_600_000, maxRequests: 3 };
// IP+방 조합당 1시간에 5회 비밀번호 시도
const VERIFY_LIMIT = { windowMs: 3_600_000, maxRequests: 5 };

/**
 * 방 생성 Server Action
 * 1. roomId + 비밀번호 생성
 * 2. 비밀번호 → PBKDF2 → authKey → SHA-256 해시
 * 3. Supabase에 방 메타데이터 저장
 * 4. roomId + 비밀번호 반환 (비밀번호는 이 순간에만 노출)
 */
export async function createRoom(): Promise<{
  roomId: string;
  password: string;
} | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`create:${ip}`, CREATE_ROOM_LIMIT);
  if (!rateCheck.allowed) {
    return { error: 'TOO_MANY_REQUESTS' };
  }

  const supabase = createServerSupabase();
  const roomId = generateRoomId();
  const password = generateRoomPassword();

  const { authKey } = await deriveKeysFromPassword(password, roomId);
  const authKeyHash = await hashAuthKey(authKey);

  // 24시간 안전망: 방 만들고 아무도 안 온 경우에만 정리
  // 실제 삭제는 모든 참여자가 퇴장할 때 발생 (연결 기반)
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const { error } = await supabase.from('rooms').insert({
    id: roomId,
    auth_key_hash: authKeyHash,
    created_at: new Date().toISOString(),
    expires_at: expiresAt,
    status: 'waiting',
    participant_count: 0,
  });

  if (error) {
    return { error: 'Failed to create room' };
  }

  return { roomId, password };
}

/**
 * 비밀번호 검증 Server Action
 * 클라이언트가 입력한 비밀번호의 authKey 해시를 DB와 비교
 */
export async function verifyPassword(
  roomId: string,
  password: string
): Promise<{ valid: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`verify:${ip}:${roomId}`, VERIFY_LIMIT);
  if (!rateCheck.allowed) {
    return { valid: false, error: 'TOO_MANY_REQUESTS' };
  }

  const supabase = createServerSupabase();

  const { data: room, error } = await supabase
    .from('rooms')
    .select('auth_key_hash, status, expires_at, participant_count')
    .eq('id', roomId)
    .single();

  if (error || !room) {
    return { valid: false, error: 'ROOM_NOT_FOUND' };
  }

  if (room.status === 'destroyed') {
    return { valid: false, error: 'ROOM_DESTROYED' };
  }

  // 24시간 안전망 초과 (아무도 접속하지 않은 버려진 방)
  if (new Date(room.expires_at) < new Date()) {
    return { valid: false, error: 'ROOM_EXPIRED' };
  }

  // 1:1 채팅 — 2명 이상이면 입장 불가
  if (room.participant_count >= 2) {
    return { valid: false, error: 'ROOM_FULL' };
  }

  const { authKey } = await deriveKeysFromPassword(password, roomId);
  const authKeyHash = await hashAuthKey(authKey);

  if (!constantTimeEqual(authKeyHash, room.auth_key_hash)) {
    return { valid: false, error: 'INVALID_PASSWORD' };
  }

  return { valid: true };
}

/**
 * 방 상태 확인
 */
export async function getRoomStatus(
  roomId: string
): Promise<{ exists: boolean; status?: string; error?: string }> {
  const supabase = createServerSupabase();

  const { data: room, error } = await supabase
    .from('rooms')
    .select('status, expires_at')
    .eq('id', roomId)
    .single();

  if (error || !room) {
    return { exists: false };
  }

  if (new Date(room.expires_at) < new Date()) {
    return { exists: true, status: 'expired' };
  }

  return { exists: true, status: room.status };
}

/**
 * 방 참여자 수 업데이트
 * authKeyHash 검증 필수 — 방 비밀번호를 모르면 조작 불가
 */
export async function updateParticipantCount(
  roomId: string,
  count: number,
  authKeyHash: string
): Promise<void> {
  if (!authKeyHash) return;
  const supabase = createServerSupabase();

  if (count === 0) {
    // 원자적 업데이트: SELECT + UPDATE 사이 race condition 제거
    // WHERE 절에 status='active'와 auth_key_hash를 포함하여
    // 이미 destroyed된 방이나 인증 불일치는 0행 업데이트 (무시)
    await supabase
      .from('rooms')
      .update({ status: 'destroyed', participant_count: 0 })
      .eq('id', roomId)
      .eq('auth_key_hash', authKeyHash)
      .eq('status', 'active');
  } else {
    // 인증 검증을 WHERE 절에 포함 — 불일치 시 0행 업데이트 (무시)
    await supabase
      .from('rooms')
      .update({
        participant_count: count,
        status: count > 0 ? 'active' : 'waiting',
      })
      .eq('id', roomId)
      .eq('auth_key_hash', authKeyHash);
  }
}

/**
 * 방 삭제 (파쇄)
 * authKeyHash 검증 필수 — 방 비밀번호를 모르면 삭제 불가
 */
export async function destroyRoom(roomId: string, authKeyHash: string): Promise<void> {
  if (!authKeyHash) return;
  const supabase = createServerSupabase();
  await supabase.from('rooms').delete().eq('id', roomId).eq('auth_key_hash', authKeyHash);
}
