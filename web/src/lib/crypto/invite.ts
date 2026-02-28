/**
 * BLIP 초대 코드 크립토 모듈
 *
 * 초대 코드(inviteCode)에서 wrapping key를 유도하고,
 * encryptionSeed를 wrap/unwrap하는 함수들.
 *
 * 보안 설계:
 * - 초대 코드 salt: "blip-invite-{boardId}" (password salt "blip-room-{boardId}"와 구분)
 * - PBKDF2 100,000회 → 256비트 wrapping key
 * - nacl.secretbox (XSalsa20-Poly1305)로 encryptionSeed wrap/unwrap
 */
import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64 } from 'tweetnacl-util';

const INVITE_CHARSET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 문자 제외 (0/O, 1/I)

/**
 * 초대 코드 생성 (XXXX-XXXX-XXXX, 12자리)
 * password(XXXX-XXXX, 8자리)보다 높은 엔트로피: 30^12 ≈ 5.3×10^17
 */
export function generateInviteCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(12));
  const chars = Array.from(bytes).map((b) => INVITE_CHARSET[b % INVITE_CHARSET.length]);
  return `${chars.slice(0, 4).join('')}-${chars.slice(4, 8).join('')}-${chars.slice(8, 12).join('')}`;
}

/**
 * 초대 코드에서 wrapping key 유도 (PBKDF2-SHA256)
 * password 유도와 다른 salt prefix("blip-invite-")를 사용하여 충돌 방지
 */
export async function deriveWrappingKey(
  inviteCode: string,
  boardId: string
): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    encoder.encode(inviteCode.toUpperCase()),
    'PBKDF2',
    false,
    ['deriveBits']
  );

  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: encoder.encode(`blip-invite-${boardId}`),
      iterations: 100000,
      hash: 'SHA-256',
    },
    keyMaterial,
    256 // 32바이트 = nacl.secretbox 키 길이
  );

  return new Uint8Array(derivedBits);
}

/**
 * encryptionSeed를 wrapping key로 암호화 (nacl.secretbox)
 */
export function wrapEncryptionKey(
  encryptionSeed: Uint8Array,
  wrappingKey: Uint8Array
): { ciphertext: string; nonce: string } {
  const nonce = nacl.randomBytes(nacl.secretbox.nonceLength);
  const wrapped = nacl.secretbox(encryptionSeed, nonce, wrappingKey);
  if (!wrapped) throw new Error('Key wrapping failed');
  return {
    ciphertext: encodeBase64(wrapped),
    nonce: encodeBase64(nonce),
  };
}

/**
 * wrapped encryptionSeed를 wrapping key로 복호화
 */
export function unwrapEncryptionKey(
  wrappedCiphertext: string,
  wrappedNonce: string,
  wrappingKey: Uint8Array
): Uint8Array | null {
  const ciphertext = decodeBase64(wrappedCiphertext);
  const nonce = decodeBase64(wrappedNonce);
  return nacl.secretbox.open(ciphertext, nonce, wrappingKey);
}

/**
 * encryptionSeed에서 보조 인증 해시 유도
 * invite code 경유 사용자의 서버 인증에 사용
 * (password-derived authKeyHash의 대체 경로)
 */
export async function hashEncryptionKeyForAuth(
  encryptionSeed: Uint8Array
): Promise<string> {
  const prefix = new TextEncoder().encode('blip-board-eauth:');
  const seedBase64 = new TextEncoder().encode(encodeBase64(encryptionSeed));
  const combined = new Uint8Array(prefix.length + seedBase64.length);
  combined.set(prefix);
  combined.set(seedBase64, prefix.length);

  const hashBuffer = await crypto.subtle.digest('SHA-256', combined);
  return encodeBase64(new Uint8Array(hashBuffer));
}

/**
 * 초대 코드 해시 (서버 저장/검증용)
 */
export async function hashInviteCode(inviteCode: string): Promise<string> {
  const encoder = new TextEncoder();
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(inviteCode.toUpperCase()));
  return encodeBase64(new Uint8Array(hashBuffer));
}
