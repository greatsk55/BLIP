'use server';

import { headers } from 'next/headers';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { generateLinkId, hashOwnerToken } from './utils';

// IP당 1시간에 3개 링크 생성
const CREATE_LINK_LIMIT = { windowMs: 3_600_000, maxRequests: 3 };
// IP당 1시간에 10회 연결 시도
const CONNECT_LIMIT = { windowMs: 3_600_000, maxRequests: 10 };

/** 타이밍 공격 방어용 상수시간 문자열 비교 */
function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

/**
 * BLIP me 링크 생성
 * ownerToken은 클라이언트에서 생성 → 해시만 서버에 저장
 */
export async function createBlipMeLink(ownerTokenHash: string): Promise<{
  linkId: string;
} | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`blipme-create:${ip}`, CREATE_LINK_LIMIT);
  if (!rateCheck.allowed) {
    return { error: 'TOO_MANY_REQUESTS' };
  }

  if (!ownerTokenHash || ownerTokenHash.length < 32) {
    return { error: 'INVALID_TOKEN' };
  }

  const supabase = createServerSupabase();
  const linkId = generateLinkId();

  const { error } = await supabase.from('blip_links').insert({
    id: linkId,
    owner_token_hash: ownerTokenHash,
    created_at: new Date().toISOString(),
    status: 'active',
    use_count: 0,
  });

  if (error) {
    return { error: 'CREATE_FAILED' };
  }

  return { linkId };
}

/**
 * 소유자의 BLIP me 링크 조회
 */
export async function getMyBlipMeLink(ownerTokenHash: string): Promise<{
  linkId: string;
  status: string;
  useCount: number;
  createdAt: string;
} | null> {
  if (!ownerTokenHash) return null;

  const supabase = createServerSupabase();
  const { data, error } = await supabase
    .from('blip_links')
    .select('id, status, use_count, created_at')
    .eq('owner_token_hash', ownerTokenHash)
    .eq('status', 'active')
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (error || !data) return null;

  return {
    linkId: data.id,
    status: data.status,
    useCount: data.use_count,
    createdAt: data.created_at,
  };
}

/**
 * BLIP me 링크 삭제 (소유자만)
 */
export async function deleteBlipMeLink(
  linkId: string,
  ownerTokenHash: string
): Promise<{ success: boolean; error?: string }> {
  if (!ownerTokenHash) return { success: false, error: 'INVALID_TOKEN' };

  const supabase = createServerSupabase();
  const { data, error } = await supabase
    .from('blip_links')
    .delete()
    .eq('id', linkId)
    .eq('owner_token_hash', ownerTokenHash)
    .select('id')
    .single();

  if (error || !data) {
    return { success: false, error: 'NOT_FOUND' };
  }

  return { success: true };
}

/**
 * BLIP me 링크 재생성 (기존 삭제 + 새 ID 생성)
 */
export async function regenerateBlipMeLink(
  oldLinkId: string,
  ownerTokenHash: string
): Promise<{ linkId: string } | { error: string }> {
  if (!ownerTokenHash) return { error: 'INVALID_TOKEN' };

  const supabase = createServerSupabase();

  // 기존 링크 소유권 확인 후 삭제
  const { data: deleted } = await supabase
    .from('blip_links')
    .delete()
    .eq('id', oldLinkId)
    .eq('owner_token_hash', ownerTokenHash)
    .select('id')
    .single();

  if (!deleted) {
    return { error: 'NOT_FOUND' };
  }

  // 새 링크 생성
  const newLinkId = generateLinkId();
  const { error } = await supabase.from('blip_links').insert({
    id: newLinkId,
    owner_token_hash: ownerTokenHash,
    created_at: new Date().toISOString(),
    status: 'active',
    use_count: 0,
  });

  if (error) {
    return { error: 'CREATE_FAILED' };
  }

  return { linkId: newLinkId };
}

/**
 * 방문자: BLIP me 링크로 방 생성
 * 1. 링크 유효성 확인
 * 2. 새 1:1 방 생성 (기존 createRoom 로직 재사용)
 * 3. Supabase Broadcast로 소유자에게 알림
 * 4. roomId + password 반환
 */
export async function connectViaBlipMe(linkId: string): Promise<{
  roomId: string;
  password: string;
} | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`blipme-connect:${ip}`, CONNECT_LIMIT);
  if (!rateCheck.allowed) {
    return { error: 'TOO_MANY_REQUESTS' };
  }

  const supabase = createServerSupabase();

  // 링크 조회
  const { data: link, error: linkError } = await supabase
    .from('blip_links')
    .select('id, owner_token_hash, status, use_count')
    .eq('id', linkId)
    .single();

  if (linkError || !link) {
    return { error: 'LINK_NOT_FOUND' };
  }

  if (link.status !== 'active') {
    return { error: 'LINK_DISABLED' };
  }

  // 방 생성 (기존 room 로직 재사용)
  const { generateRoomId, generateRoomPassword } = await import('@/lib/room/password');
  const { deriveKeysFromPassword, hashAuthKey } = await import('@/lib/crypto');

  const roomId = generateRoomId();
  const password = generateRoomPassword();

  const { authKey } = await deriveKeysFromPassword(password, roomId);
  const authKeyHash = await hashAuthKey(authKey);

  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const { error: roomError } = await supabase.from('rooms').insert({
    id: roomId,
    auth_key_hash: authKeyHash,
    created_at: new Date().toISOString(),
    expires_at: expiresAt,
    status: 'waiting',
    participant_count: 0,
  });

  if (roomError) {
    return { error: 'ROOM_CREATE_FAILED' };
  }

  // 사용 횟수 증가
  const currentCount = (link.use_count as number) ?? 0;
  await supabase
    .from('blip_links')
    .update({ use_count: currentCount + 1 })
    .eq('id', linkId);

  // Supabase Broadcast로 소유자에게 알림
  // 소유자는 `blipme:{linkId}` 채널을 구독하고 있어야 함
  const channel = supabase.channel(`blipme:${linkId}`);
  await channel.send({
    type: 'broadcast',
    event: 'incoming',
    payload: {
      roomId,
      password,
      timestamp: Date.now(),
    },
  });
  supabase.removeChannel(channel);

  return { roomId, password };
}

/**
 * BLIP me 링크 존재 여부 확인 (방문자용 — 최소 정보)
 */
export async function checkBlipMeLink(linkId: string): Promise<{
  exists: boolean;
  active: boolean;
}> {
  const supabase = createServerSupabase();
  const { data } = await supabase
    .from('blip_links')
    .select('status')
    .eq('id', linkId)
    .single();

  if (!data) return { exists: false, active: false };
  return { exists: true, active: data.status === 'active' };
}
