import nacl from 'tweetnacl';
import { encodeUTF8, decodeBase64 } from 'tweetnacl-util';
import type { EncryptedPayload } from '@/types/chat';

/**
 * 메시지 복호화 (nacl.box.open - XSalsa20-Poly1305)
 * 사전 계산된 공유 비밀 사용
 */
export function decryptMessage(
  payload: EncryptedPayload,
  sharedSecret: Uint8Array
): string | null {
  const ciphertext = decodeBase64(payload.ciphertext);
  const nonce = decodeBase64(payload.nonce);
  const decrypted = nacl.box.open.after(ciphertext, nonce, sharedSecret);

  if (!decrypted) {
    return null;
  }

  return encodeUTF8(decrypted);
}
