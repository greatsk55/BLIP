import { describe, it, expect } from 'vitest';
import {
  generateKeyPair,
  computeSharedSecret,
  deriveKeysFromPassword,
  hashAuthKey,
  publicKeyToString,
  stringToPublicKey,
} from './keys';

describe('generateKeyPair', () => {
  it('32바이트 공개키/비밀키를 반환한다', () => {
    const kp = generateKeyPair();
    expect(kp.publicKey).toBeInstanceOf(Uint8Array);
    expect(kp.secretKey).toBeInstanceOf(Uint8Array);
    expect(kp.publicKey.length).toBe(32);
    expect(kp.secretKey.length).toBe(32);
  });

  it('매번 다른 키쌍을 생성한다', () => {
    const kp1 = generateKeyPair();
    const kp2 = generateKeyPair();
    expect(kp1.publicKey).not.toEqual(kp2.publicKey);
    expect(kp1.secretKey).not.toEqual(kp2.secretKey);
  });
});

describe('computeSharedSecret', () => {
  it('양쪽 ECDH 결과가 동일하다 (A의 pub+B의 sec === B의 pub+A의 sec)', () => {
    const alice = generateKeyPair();
    const bob = generateKeyPair();

    const sharedA = computeSharedSecret(bob.publicKey, alice.secretKey);
    const sharedB = computeSharedSecret(alice.publicKey, bob.secretKey);

    expect(sharedA).toEqual(sharedB);
    expect(sharedA.length).toBe(32);
  });

  it('다른 키쌍이면 다른 공유 비밀이 나온다', () => {
    const alice = generateKeyPair();
    const bob = generateKeyPair();
    const charlie = generateKeyPair();

    const sharedAB = computeSharedSecret(bob.publicKey, alice.secretKey);
    const sharedAC = computeSharedSecret(charlie.publicKey, alice.secretKey);

    expect(sharedAB).not.toEqual(sharedAC);
  });
});

describe('deriveKeysFromPassword', () => {
  it('같은 입력이면 같은 출력 (결정적)', async () => {
    const result1 = await deriveKeysFromPassword('test-pass', 'room-123');
    const result2 = await deriveKeysFromPassword('test-pass', 'room-123');

    expect(result1.authKey).toEqual(result2.authKey);
    expect(result1.encryptionSeed).toEqual(result2.encryptionSeed);
  });

  it('다른 비밀번호면 다른 출력', async () => {
    const result1 = await deriveKeysFromPassword('pass-a', 'room-123');
    const result2 = await deriveKeysFromPassword('pass-b', 'room-123');

    expect(result1.authKey).not.toEqual(result2.authKey);
  });

  it('다른 roomId면 다른 출력 (salt 차이)', async () => {
    const result1 = await deriveKeysFromPassword('same-pass', 'room-1');
    const result2 = await deriveKeysFromPassword('same-pass', 'room-2');

    expect(result1.authKey).not.toEqual(result2.authKey);
  });

  it('authKey 32바이트 + encryptionSeed 32바이트', async () => {
    const result = await deriveKeysFromPassword('test', 'room');

    expect(result.authKey).toBeInstanceOf(Uint8Array);
    expect(result.encryptionSeed).toBeInstanceOf(Uint8Array);
    expect(result.authKey.length).toBe(32);
    expect(result.encryptionSeed.length).toBe(32);
  });
});

describe('hashAuthKey', () => {
  it('Base64 문자열을 반환한다', async () => {
    const { authKey } = await deriveKeysFromPassword('test', 'room');
    const hash = await hashAuthKey(authKey);

    expect(typeof hash).toBe('string');
    expect(hash.length).toBeGreaterThan(0);
  });

  it('같은 입력이면 같은 해시', async () => {
    const { authKey } = await deriveKeysFromPassword('test', 'room');
    const hash1 = await hashAuthKey(authKey);
    const hash2 = await hashAuthKey(authKey);

    expect(hash1).toBe(hash2);
  });
});

describe('publicKeyToString / stringToPublicKey', () => {
  it('왕복 변환 시 원래 키와 동일하다', () => {
    const kp = generateKeyPair();
    const str = publicKeyToString(kp.publicKey);
    const restored = stringToPublicKey(str);

    expect(restored).toEqual(kp.publicKey);
  });

  it('Base64 문자열로 변환된다', () => {
    const kp = generateKeyPair();
    const str = publicKeyToString(kp.publicKey);

    expect(typeof str).toBe('string');
    expect(str.length).toBeGreaterThan(0);
  });
});
