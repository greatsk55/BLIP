import { describe, it, expect } from 'vitest';
import nacl from 'tweetnacl';
import { encryptFileChunk, decryptFileChunk } from './file';

describe('file chunk encryption', () => {
  const sharedSecret = nacl.box.before(
    nacl.box.keyPair().publicKey,
    nacl.box.keyPair().secretKey
  );

  it('encrypts and decrypts a chunk correctly', () => {
    const original = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]);
    const encrypted = encryptFileChunk(original, sharedSecret);

    expect(encrypted.ciphertext).toBeInstanceOf(Uint8Array);
    expect(encrypted.nonce).toBeInstanceOf(Uint8Array);
    expect(encrypted.nonce.length).toBe(nacl.box.nonceLength);
    // 암호문은 원본 + 16바이트 MAC
    expect(encrypted.ciphertext.length).toBe(original.length + nacl.box.overheadLength);

    const decrypted = decryptFileChunk(encrypted.ciphertext, encrypted.nonce, sharedSecret);
    expect(decrypted).not.toBeNull();
    expect(decrypted).toEqual(original);
  });

  it('generates unique nonce per call', () => {
    const data = new Uint8Array([1, 2, 3]);
    const a = encryptFileChunk(data, sharedSecret);
    const b = encryptFileChunk(data, sharedSecret);

    expect(a.nonce).not.toEqual(b.nonce);
    expect(a.ciphertext).not.toEqual(b.ciphertext);
  });

  it('returns null for wrong shared secret', () => {
    const data = new Uint8Array([10, 20, 30]);
    const encrypted = encryptFileChunk(data, sharedSecret);

    const wrongSecret = nacl.box.before(
      nacl.box.keyPair().publicKey,
      nacl.box.keyPair().secretKey
    );

    const result = decryptFileChunk(encrypted.ciphertext, encrypted.nonce, wrongSecret);
    expect(result).toBeNull();
  });

  it('returns null for tampered ciphertext', () => {
    const data = new Uint8Array([100, 200]);
    const encrypted = encryptFileChunk(data, sharedSecret);

    // 암호문 변조
    encrypted.ciphertext[0] ^= 0xff;

    const result = decryptFileChunk(encrypted.ciphertext, encrypted.nonce, sharedSecret);
    expect(result).toBeNull();
  });

  it('handles empty data', () => {
    const empty = new Uint8Array(0);
    const encrypted = encryptFileChunk(empty, sharedSecret);
    const decrypted = decryptFileChunk(encrypted.ciphertext, encrypted.nonce, sharedSecret);

    expect(decrypted).not.toBeNull();
    expect(decrypted!.length).toBe(0);
  });

  it('handles large chunks (64KB)', () => {
    const large = new Uint8Array(64 * 1024);
    for (let i = 0; i < large.length; i++) large[i] = i % 256;

    const encrypted = encryptFileChunk(large, sharedSecret);
    const decrypted = decryptFileChunk(encrypted.ciphertext, encrypted.nonce, sharedSecret);

    expect(decrypted).toEqual(large);
  });

  it('uses ECDH shared secret from key exchange', () => {
    // 실제 ECDH 키 교환 시뮬레이션
    const alice = nacl.box.keyPair();
    const bob = nacl.box.keyPair();
    const aliceShared = nacl.box.before(bob.publicKey, alice.secretKey);
    const bobShared = nacl.box.before(alice.publicKey, bob.secretKey);

    const data = new Uint8Array([42, 43, 44]);
    const encrypted = encryptFileChunk(data, aliceShared);
    const decrypted = decryptFileChunk(encrypted.ciphertext, encrypted.nonce, bobShared);

    expect(decrypted).toEqual(data);
  });
});
