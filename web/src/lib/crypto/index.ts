/**
 * BLIP E2EE 암호화 모듈 (SSOT)
 *
 * 라이브러리: tweetnacl (Curve25519 ECDH + XSalsa20-Poly1305)
 * 키 유도: Web Crypto API PBKDF2
 *
 * 인증 흐름 (서버):
 * 1. 비밀번호 → deriveKeysFromPassword() → authKey → hashAuthKey() → DB 검증
 *
 * E2EE 흐름 - 1:1 채팅 (클라이언트):
 * 1. generateKeyPair() → 랜덤 ECDH 키쌍 (Perfect Forward Secrecy)
 * 2. computeSharedSecret() → 상대 공개키 + 내 비밀키 → 공유 비밀
 * 3. encryptMessage() / decryptMessage() → 메시지 암복호화
 *
 * E2EE 흐름 - 게시판 (클라이언트):
 * 1. deriveKeysFromPassword() → encryptionSeed (대칭키)
 * 2. encryptSymmetric() / decryptSymmetric() → nacl.secretbox 기반 암복호화
 */
export {
  generateKeyPair,
  computeSharedSecret,
  deriveKeysFromPassword,
  hashAuthKey,
  publicKeyToString,
  stringToPublicKey,
} from './keys';

export { encryptMessage } from './encrypt';
export { decryptMessage } from './decrypt';
export { encryptFileChunk, decryptFileChunk } from './file';
export { encryptSymmetric, decryptSymmetric, encryptBinary, decryptBinaryRaw } from './symmetric';
export {
  generateInviteCode,
  deriveWrappingKey,
  wrapEncryptionKey,
  unwrapEncryptionKey,
  hashEncryptionKeyForAuth,
  hashInviteCode,
} from './invite';
