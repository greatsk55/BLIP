import nacl from 'tweetnacl';
import { encodeBase64, decodeBase64 } from 'tweetnacl-util';
import type { KeyPair } from '@/types/chat';

/**
 * ECDH 키쌍 생성 (Curve25519)
 */
export function generateKeyPair(): KeyPair {
  const keyPair = nacl.box.keyPair();
  return {
    publicKey: keyPair.publicKey,
    secretKey: keyPair.secretKey,
  };
}

/**
 * ECDH 공유 비밀 계산
 * 상대방의 공개키와 내 비밀키로 공유 비밀 생성
 */
export function computeSharedSecret(
  theirPublicKey: Uint8Array,
  mySecretKey: Uint8Array
): Uint8Array {
  return nacl.box.before(theirPublicKey, mySecretKey);
}

/**
 * 비밀번호에서 이중 키 유도 (PBKDF2)
 * - 앞 32바이트: authKey (서버 검증용)
 * - 뒤 32바이트: encryptionSeed (암호화 키 시드, 서버 모름)
 */
export async function deriveKeysFromPassword(
  password: string,
  roomId: string
): Promise<{ authKey: Uint8Array; encryptionSeed: Uint8Array }> {
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    encoder.encode(password),
    'PBKDF2',
    false,
    ['deriveBits']
  );

  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: encoder.encode(`blip-room-${roomId}`),
      iterations: 100000,
      hash: 'SHA-256',
    },
    keyMaterial,
    512 // 64바이트 = 512비트
  );

  const derived = new Uint8Array(derivedBits);
  return {
    authKey: derived.slice(0, 32),
    encryptionSeed: derived.slice(32, 64),
  };
}

/**
 * authKey를 SHA-256 해시 (서버 저장용)
 */
export async function hashAuthKey(authKey: Uint8Array): Promise<string> {
  const hashBuffer = await crypto.subtle.digest('SHA-256', authKey.buffer as ArrayBuffer);
  return encodeBase64(new Uint8Array(hashBuffer));
}

/**
 * 공개키를 base64 문자열로 변환
 */
export function publicKeyToString(publicKey: Uint8Array): string {
  return encodeBase64(publicKey);
}

/**
 * base64 문자열을 공개키로 변환
 */
export function stringToPublicKey(str: string): Uint8Array {
  return decodeBase64(str);
}
