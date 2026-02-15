import { describe, it, expect } from 'vitest';
import nacl from 'tweetnacl';
import { decodeBase64 } from 'tweetnacl-util';
import { encryptSymmetric, decryptSymmetric, encryptBinary, decryptBinaryRaw } from './symmetric';

/** 테스트용 대칭키 생성 (32바이트 랜덤) */
function createSymmetricKey(): Uint8Array {
  return nacl.randomBytes(nacl.secretbox.keyLength);
}

describe('symmetric encrypt + decrypt (nacl.secretbox)', () => {
  it('암호화 → 복호화 왕복: 원문 복원', () => {
    const key = createSymmetricKey();
    const plaintext = 'Hello, BLIP Board!';

    const encrypted = encryptSymmetric(plaintext, key);
    const decrypted = decryptSymmetric(encrypted, key);

    expect(decrypted).toBe(plaintext);
  });

  it('같은 메시지를 두 번 암호화하면 다른 ciphertext (랜덤 nonce)', () => {
    const key = createSymmetricKey();
    const plaintext = 'same message';

    const enc1 = encryptSymmetric(plaintext, key);
    const enc2 = encryptSymmetric(plaintext, key);

    expect(enc1.ciphertext).not.toBe(enc2.ciphertext);
    expect(enc1.nonce).not.toBe(enc2.nonce);
  });

  it('잘못된 키로 복호화하면 null', () => {
    const key = createSymmetricKey();
    const wrongKey = createSymmetricKey();

    const encrypted = encryptSymmetric('secret', key);
    const decrypted = decryptSymmetric(encrypted, wrongKey);

    expect(decrypted).toBeNull();
  });

  it('빈 문자열 암호화/복호화', () => {
    const key = createSymmetricKey();

    const encrypted = encryptSymmetric('', key);
    const decrypted = decryptSymmetric(encrypted, key);

    expect(decrypted).toBe('');
  });

  it('긴 메시지 (10KB) 암호화/복호화', () => {
    const key = createSymmetricKey();
    const longMessage = 'A'.repeat(10 * 1024);

    const encrypted = encryptSymmetric(longMessage, key);
    const decrypted = decryptSymmetric(encrypted, key);

    expect(decrypted).toBe(longMessage);
  });

  it('유니코드 (한글, 이모지, 일본어) 암호화/복호화', () => {
    const key = createSymmetricKey();
    const unicode = '안녕하세요 BLIP 게시판! 🔒🚀 日本語テスト';

    const encrypted = encryptSymmetric(unicode, key);
    const decrypted = decryptSymmetric(encrypted, key);

    expect(decrypted).toBe(unicode);
  });

  it('변조된 ciphertext는 복호화 실패 (무결성)', () => {
    const key = createSymmetricKey();
    const encrypted = encryptSymmetric('integrity test', key);

    const tampered = {
      ...encrypted,
      ciphertext:
        encrypted.ciphertext[0] === 'A'
          ? 'B' + encrypted.ciphertext.slice(1)
          : 'A' + encrypted.ciphertext.slice(1),
    };

    const decrypted = decryptSymmetric(tampered, key);
    expect(decrypted).toBeNull();
  });

  it('동일한 키를 가진 여러 사용자가 서로의 메시지를 읽을 수 있다', () => {
    const sharedKey = createSymmetricKey();

    // User A가 암호화
    const fromA = encryptSymmetric('message from A', sharedKey);
    // User B가 복호화
    expect(decryptSymmetric(fromA, sharedKey)).toBe('message from A');

    // User B가 암호화
    const fromB = encryptSymmetric('message from B', sharedKey);
    // User A가 복호화
    expect(decryptSymmetric(fromB, sharedKey)).toBe('message from B');

    // User C도 같은 키로 복호화
    expect(decryptSymmetric(fromA, sharedKey)).toBe('message from A');
    expect(decryptSymmetric(fromB, sharedKey)).toBe('message from B');
  });
});

describe('binary encrypt + decrypt (nacl.secretbox)', () => {
  it('바이너리 데이터 왕복: 원본 복원', () => {
    const key = nacl.randomBytes(nacl.secretbox.keyLength);
    const data = nacl.randomBytes(1024);

    const encrypted = encryptBinary(data, key);
    const ciphertext = decodeBase64(encrypted.ciphertext);
    const nonce = decodeBase64(encrypted.nonce);
    const decrypted = decryptBinaryRaw(ciphertext, nonce, key);

    expect(decrypted).not.toBeNull();
    expect(new Uint8Array(decrypted!)).toEqual(data);
  });

  it('대용량 바이너리 (1MB) 암복호화', () => {
    const key = nacl.randomBytes(nacl.secretbox.keyLength);
    const data = nacl.randomBytes(1024 * 1024);

    const encrypted = encryptBinary(data, key);
    const ciphertext = decodeBase64(encrypted.ciphertext);
    const nonce = decodeBase64(encrypted.nonce);
    const decrypted = decryptBinaryRaw(ciphertext, nonce, key);

    expect(decrypted).not.toBeNull();
    expect(decrypted!.length).toBe(data.length);
  });

  it('잘못된 키로 바이너리 복호화 실패', () => {
    const key = nacl.randomBytes(nacl.secretbox.keyLength);
    const wrongKey = nacl.randomBytes(nacl.secretbox.keyLength);
    const data = nacl.randomBytes(256);

    const encrypted = encryptBinary(data, key);
    const ciphertext = decodeBase64(encrypted.ciphertext);
    const nonce = decodeBase64(encrypted.nonce);

    expect(decryptBinaryRaw(ciphertext, nonce, wrongKey)).toBeNull();
  });

  it('빈 바이너리 암복호화', () => {
    const key = nacl.randomBytes(nacl.secretbox.keyLength);
    const data = new Uint8Array(0);

    const encrypted = encryptBinary(data, key);
    const ciphertext = decodeBase64(encrypted.ciphertext);
    const nonce = decodeBase64(encrypted.nonce);
    const decrypted = decryptBinaryRaw(ciphertext, nonce, key);

    expect(decrypted).not.toBeNull();
    expect(decrypted!.length).toBe(0);
  });
});
