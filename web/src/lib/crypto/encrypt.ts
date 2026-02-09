import nacl from 'tweetnacl';
import { decodeUTF8, encodeBase64 } from 'tweetnacl-util';
import type { EncryptedPayload } from '@/types/chat';

/**
 * 메시지 암호화 (nacl.box - XSalsa20-Poly1305)
 * 사전 계산된 공유 비밀 사용
 */
export function encryptMessage(
  plaintext: string,
  sharedSecret: Uint8Array
): EncryptedPayload {
  const nonce = nacl.randomBytes(nacl.box.nonceLength);
  const messageBytes = decodeUTF8(plaintext);
  const ciphertext = nacl.box.after(messageBytes, nonce, sharedSecret);

  if (!ciphertext) {
    throw new Error('Encryption failed');
  }

  return {
    ciphertext: encodeBase64(ciphertext),
    nonce: encodeBase64(nonce),
  };
}
