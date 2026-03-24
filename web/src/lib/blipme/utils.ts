/**
 * BLIP me 유틸리티
 * - 링크 ID 생성
 * - ownerToken 생성 및 해싱
 */

const CHARSET = 'abcdefghjkmnpqrstuvwxyz23456789'; // 혼동 문자 제외

/**
 * BLIP me 링크 ID 생성 (8자, URL-safe)
 */
export function generateLinkId(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  return Array.from(bytes)
    .map((b) => CHARSET[b % CHARSET.length])
    .join('');
}

/**
 * ownerToken 생성 (32바이트 hex)
 * 클라이언트에서만 호출 — localStorage에 저장
 */
export function generateOwnerToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

/**
 * ownerToken → SHA-256 해시 (서버 저장용)
 */
export async function hashOwnerToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('');
}
