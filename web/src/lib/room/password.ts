/**
 * 방 비밀번호 생성 모듈
 *
 * 형식: "XXXX-XXXX" (8자리 영숫자, 하이픈 구분)
 * 엔트로피: 충분한 랜덤성 보장 (crypto.getRandomValues)
 */

const CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외: 0/O, 1/I

/**
 * 방 비밀번호 생성
 * @returns "K7X2-M9P4" 형태의 비밀번호
 */
export function generateRoomPassword(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  const chars = Array.from(bytes).map((b) => CHARSET[b % CHARSET.length]);
  return `${chars.slice(0, 4).join('')}-${chars.slice(4, 8).join('')}`;
}

/**
 * 방 ID 생성 (URL-safe, 읽기 쉬운 형태)
 * @returns "a7x2k9m3" 형태의 방 ID
 */
export function generateRoomId(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  const charset = 'abcdefghjkmnpqrstuvwxyz23456789';
  return Array.from(bytes)
    .map((b) => charset[b % charset.length])
    .join('');
}
