/**
 * 랜덤 익명 닉네임 생성기
 *
 * 형식: "{PREFIX}_{4자리해시}" → 예: "GHOST_7x2k"
 * 해커/프로토콜 미학에 맞춘 닉네임
 */

const PREFIXES = [
  'GHOST',
  'SHADOW',
  'CIPHER',
  'VOID',
  'SIGNAL',
  'PHANTOM',
  'ECHO',
  'PULSE',
  'FLUX',
  'DRIFT',
  'SPARK',
  'TRACE',
  'NEXUS',
  'SURGE',
  'ORBIT',
  'PRISM',
] as const;

const HASH_CHARS = 'abcdefghjkmnpqrstuvwxyz23456789';

/**
 * 랜덤 닉네임 생성
 * @returns "GHOST_7x2k" 형태의 닉네임
 */
export function generateUsername(): string {
  const prefix = PREFIXES[Math.floor(Math.random() * PREFIXES.length)];
  const hashBytes = crypto.getRandomValues(new Uint8Array(4));
  const hash = Array.from(hashBytes)
    .map((b) => HASH_CHARS[b % HASH_CHARS.length])
    .join('');
  return `${prefix}_${hash}`;
}
