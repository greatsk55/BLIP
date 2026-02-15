import nacl from 'tweetnacl';
import type { EncryptedFileChunk } from '@/types/chat';

/**
 * 파일 청크 암호화 (nacl.box - XSalsa20-Poly1305)
 * 바이너리 직접 처리 (base64 변환 없음 — 33% 오버헤드 제거)
 */
export function encryptFileChunk(
  chunk: Uint8Array,
  sharedSecret: Uint8Array
): EncryptedFileChunk {
  const nonce = nacl.randomBytes(nacl.box.nonceLength);
  const ciphertext = nacl.box.after(chunk, nonce, sharedSecret);

  if (!ciphertext) {
    throw new Error('File chunk encryption failed');
  }

  return { ciphertext, nonce };
}

/**
 * 파일 청크 복호화 (nacl.box.open - XSalsa20-Poly1305)
 * 실패 시 null 반환 (변조 감지)
 */
export function decryptFileChunk(
  ciphertext: Uint8Array,
  nonce: Uint8Array,
  sharedSecret: Uint8Array
): Uint8Array | null {
  return nacl.box.open.after(ciphertext, nonce, sharedSecret);
}
