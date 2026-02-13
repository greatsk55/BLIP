import { describe, it, expect } from 'vitest';
import { generateKeyPair, computeSharedSecret } from './keys';
import { encryptMessage } from './encrypt';
import { decryptMessage } from './decrypt';

/** 테스트용 공유 비밀 생성 헬퍼 */
function createSharedSecret() {
  const alice = generateKeyPair();
  const bob = generateKeyPair();
  return {
    shared: computeSharedSecret(bob.publicKey, alice.secretKey),
    aliceShared: computeSharedSecret(bob.publicKey, alice.secretKey),
    bobShared: computeSharedSecret(alice.publicKey, bob.secretKey),
  };
}

describe('encrypt + decrypt 통합', () => {
  it('암호화 → 복호화 왕복: 원문 복원', () => {
    const { shared } = createSharedSecret();
    const plaintext = 'Hello, BLIP!';

    const encrypted = encryptMessage(plaintext, shared);
    const decrypted = decryptMessage(encrypted, shared);

    expect(decrypted).toBe(plaintext);
  });

  it('같은 메시지를 두 번 암호화하면 다른 ciphertext (랜덤 nonce)', () => {
    const { shared } = createSharedSecret();
    const plaintext = 'same message';

    const enc1 = encryptMessage(plaintext, shared);
    const enc2 = encryptMessage(plaintext, shared);

    expect(enc1.ciphertext).not.toBe(enc2.ciphertext);
    expect(enc1.nonce).not.toBe(enc2.nonce);
  });

  it('잘못된 sharedSecret으로 복호화하면 null', () => {
    const { shared } = createSharedSecret();
    const wrongSecret = createSharedSecret().shared;

    const encrypted = encryptMessage('secret', shared);
    const decrypted = decryptMessage(encrypted, wrongSecret);

    expect(decrypted).toBeNull();
  });

  it('빈 문자열 암호화/복호화', () => {
    const { shared } = createSharedSecret();

    const encrypted = encryptMessage('', shared);
    const decrypted = decryptMessage(encrypted, shared);

    expect(decrypted).toBe('');
  });

  it('긴 메시지 (10KB) 암호화/복호화', () => {
    const { shared } = createSharedSecret();
    const longMessage = 'A'.repeat(10 * 1024);

    const encrypted = encryptMessage(longMessage, shared);
    const decrypted = decryptMessage(encrypted, shared);

    expect(decrypted).toBe(longMessage);
  });

  it('유니코드 (한글, 이모지) 암호화/복호화', () => {
    const { shared } = createSharedSecret();
    const unicode = '안녕하세요 BLIP! 🔒🚀 日本語テスト';

    const encrypted = encryptMessage(unicode, shared);
    const decrypted = decryptMessage(encrypted, shared);

    expect(decrypted).toBe(unicode);
  });

  it('변조된 ciphertext는 복호화 실패 (무결성)', () => {
    const { shared } = createSharedSecret();
    const encrypted = encryptMessage('integrity test', shared);

    // ciphertext의 첫 문자를 변조
    const tampered = {
      ...encrypted,
      ciphertext:
        encrypted.ciphertext[0] === 'A'
          ? 'B' + encrypted.ciphertext.slice(1)
          : 'A' + encrypted.ciphertext.slice(1),
    };

    const decrypted = decryptMessage(tampered, shared);
    expect(decrypted).toBeNull();
  });

  it('Alice와 Bob이 동일한 공유 비밀로 통신한다', () => {
    const { aliceShared, bobShared } = createSharedSecret();

    // Alice가 암호화 → Bob이 복호화
    const fromAlice = encryptMessage('from Alice', aliceShared);
    expect(decryptMessage(fromAlice, bobShared)).toBe('from Alice');

    // Bob이 암호화 → Alice가 복호화
    const fromBob = encryptMessage('from Bob', bobShared);
    expect(decryptMessage(fromBob, aliceShared)).toBe('from Bob');
  });
});
