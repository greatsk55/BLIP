import nacl from 'tweetnacl';
import { decodeUTF8, encodeUTF8, encodeBase64, decodeBase64 } from 'tweetnacl-util';
import type { EncryptedPayload } from '@/types/chat';

// ─── 바이너리 (이미지 등) 대칭키 암복호화 ───

/**
 * 바이너리 대칭키 암호화 (nacl.secretbox - XSalsa20-Poly1305)
 * 이미지 등 Uint8Array 데이터용. Base64 EncryptedPayload 반환.
 */
export function encryptBinary(
  data: Uint8Array,
  symmetricKey: Uint8Array
): EncryptedPayload {
  const nonce = nacl.randomBytes(nacl.secretbox.nonceLength);
  const ciphertext = nacl.secretbox(data, nonce, symmetricKey);

  if (!ciphertext) {
    throw new Error('Binary encryption failed');
  }

  return {
    ciphertext: encodeBase64(ciphertext),
    nonce: encodeBase64(nonce),
  };
}

/**
 * 바이너리 대칭키 복호화 (raw Uint8Array 입출력)
 * API Route에서 raw 바이너리를 받아 base64 변환 없이 직접 복호화.
 */
export function decryptBinaryRaw(
  ciphertext: Uint8Array,
  nonce: Uint8Array,
  symmetricKey: Uint8Array
): Uint8Array | null {
  return nacl.secretbox.open(ciphertext, nonce, symmetricKey);
}

// ─── 문자열 대칭키 암복호화 ───

/**
 * 대칭키 암호화 (nacl.secretbox - XSalsa20-Poly1305)
 *
 * 게시판 등 1:N 공유 대칭키 환경용.
 * deriveKeysFromPassword()의 encryptionSeed(32B)를 키로 사용.
 */
export function encryptSymmetric(
  plaintext: string,
  symmetricKey: Uint8Array
): EncryptedPayload {
  const nonce = nacl.randomBytes(nacl.secretbox.nonceLength);
  const messageBytes = decodeUTF8(plaintext);
  const ciphertext = nacl.secretbox(messageBytes, nonce, symmetricKey);

  if (!ciphertext) {
    throw new Error('Symmetric encryption failed');
  }

  return {
    ciphertext: encodeBase64(ciphertext),
    nonce: encodeBase64(nonce),
  };
}

/**
 * 대칭키 복호화 (nacl.secretbox.open - XSalsa20-Poly1305)
 */
export function decryptSymmetric(
  payload: EncryptedPayload,
  symmetricKey: Uint8Array
): string | null {
  const ciphertext = decodeBase64(payload.ciphertext);
  const nonce = decodeBase64(payload.nonce);
  const decrypted = nacl.secretbox.open(ciphertext, nonce, symmetricKey);

  if (!decrypted) {
    return null;
  }

  return encodeUTF8(decrypted);
}
