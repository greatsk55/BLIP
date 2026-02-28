import { describe, it, expect } from 'vitest';
import nacl from 'tweetnacl';
import {
  generateInviteCode,
  deriveWrappingKey,
  wrapEncryptionKey,
  unwrapEncryptionKey,
  hashEncryptionKeyForAuth,
  hashInviteCode,
} from './invite';

describe('generateInviteCode', () => {
  it('XXXX-XXXX-XXXX 형식 생성', () => {
    const code = generateInviteCode();
    expect(code).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$/);
  });

  it('혼동 문자 (0, 1, I, O) 미포함', () => {
    // 100번 반복하여 확률적 검증
    for (let i = 0; i < 100; i++) {
      const code = generateInviteCode();
      expect(code).not.toMatch(/[01IO]/);
    }
  });

  it('매번 다른 코드 생성 (랜덤성)', () => {
    const codes = new Set<string>();
    for (let i = 0; i < 50; i++) {
      codes.add(generateInviteCode());
    }
    // 50개 모두 유니크해야 함 (충돌 확률 극히 낮음)
    expect(codes.size).toBe(50);
  });
});

describe('deriveWrappingKey', () => {
  it('32바이트 (256비트) 키 유도', async () => {
    const key = await deriveWrappingKey('ABCD-EFGH-JKLM', 'test-board-id');
    expect(key).toBeInstanceOf(Uint8Array);
    expect(key.length).toBe(32);
  });

  it('같은 입력 → 같은 키 (결정적)', async () => {
    const key1 = await deriveWrappingKey('ABCD-EFGH-JKLM', 'board-1');
    const key2 = await deriveWrappingKey('ABCD-EFGH-JKLM', 'board-1');
    expect(key1).toEqual(key2);
  });

  it('다른 초대코드 → 다른 키', async () => {
    const key1 = await deriveWrappingKey('ABCD-EFGH-JKLM', 'board-1');
    const key2 = await deriveWrappingKey('WXYZ-2345-6789', 'board-1');
    expect(key1).not.toEqual(key2);
  });

  it('다른 boardId → 다른 키 (salt 분리)', async () => {
    const key1 = await deriveWrappingKey('ABCD-EFGH-JKLM', 'board-1');
    const key2 = await deriveWrappingKey('ABCD-EFGH-JKLM', 'board-2');
    expect(key1).not.toEqual(key2);
  });

  it('대소문자 무관 (toUpperCase 정규화)', async () => {
    const key1 = await deriveWrappingKey('abcd-efgh-jklm', 'board-1');
    const key2 = await deriveWrappingKey('ABCD-EFGH-JKLM', 'board-1');
    expect(key1).toEqual(key2);
  });
});

describe('wrapEncryptionKey + unwrapEncryptionKey', () => {
  it('wrap → unwrap 왕복: 원본 키 복원', async () => {
    const encryptionSeed = nacl.randomBytes(32);
    const wrappingKey = await deriveWrappingKey('TEST-CODE-1234', 'board-wrap');

    const wrapped = wrapEncryptionKey(encryptionSeed, wrappingKey);
    const unwrapped = unwrapEncryptionKey(wrapped.ciphertext, wrapped.nonce, wrappingKey);

    expect(unwrapped).not.toBeNull();
    expect(new Uint8Array(unwrapped!)).toEqual(encryptionSeed);
  });

  it('같은 키를 두 번 wrap하면 다른 ciphertext (랜덤 nonce)', async () => {
    const seed = nacl.randomBytes(32);
    const wrappingKey = await deriveWrappingKey('TEST-CODE-1234', 'board-nonce');

    const w1 = wrapEncryptionKey(seed, wrappingKey);
    const w2 = wrapEncryptionKey(seed, wrappingKey);

    expect(w1.ciphertext).not.toBe(w2.ciphertext);
    expect(w1.nonce).not.toBe(w2.nonce);
  });

  it('잘못된 wrapping key로 unwrap 실패', async () => {
    const seed = nacl.randomBytes(32);
    const correctKey = await deriveWrappingKey('CORRECT-KEY-1234', 'board-bad');
    const wrongKey = await deriveWrappingKey('WRONG-KEY-5678', 'board-bad');

    const wrapped = wrapEncryptionKey(seed, correctKey);
    const unwrapped = unwrapEncryptionKey(wrapped.ciphertext, wrapped.nonce, wrongKey);

    expect(unwrapped).toBeNull();
  });

  it('변조된 ciphertext로 unwrap 실패 (무결성)', async () => {
    const seed = nacl.randomBytes(32);
    const wrappingKey = await deriveWrappingKey('TAMPER-TEST-1234', 'board-tamper');

    const wrapped = wrapEncryptionKey(seed, wrappingKey);

    // ciphertext 첫 글자 변조
    const tampered =
      wrapped.ciphertext[0] === 'A'
        ? 'B' + wrapped.ciphertext.slice(1)
        : 'A' + wrapped.ciphertext.slice(1);

    const unwrapped = unwrapEncryptionKey(tampered, wrapped.nonce, wrappingKey);
    expect(unwrapped).toBeNull();
  });
});

describe('hashEncryptionKeyForAuth', () => {
  it('base64 인코딩된 해시 반환', async () => {
    const seed = nacl.randomBytes(32);
    const hash = await hashEncryptionKeyForAuth(seed);

    expect(typeof hash).toBe('string');
    expect(hash.length).toBeGreaterThan(0);
    // base64 형식 검증
    expect(() => atob(hash)).not.toThrow();
  });

  it('같은 seed → 같은 해시 (결정적)', async () => {
    const seed = nacl.randomBytes(32);
    const h1 = await hashEncryptionKeyForAuth(seed);
    const h2 = await hashEncryptionKeyForAuth(seed);
    expect(h1).toBe(h2);
  });

  it('다른 seed → 다른 해시', async () => {
    const seed1 = nacl.randomBytes(32);
    const seed2 = nacl.randomBytes(32);
    const h1 = await hashEncryptionKeyForAuth(seed1);
    const h2 = await hashEncryptionKeyForAuth(seed2);
    expect(h1).not.toBe(h2);
  });
});

describe('hashInviteCode', () => {
  it('base64 인코딩된 해시 반환', async () => {
    const hash = await hashInviteCode('ABCD-EFGH-JKLM');
    expect(typeof hash).toBe('string');
    expect(hash.length).toBeGreaterThan(0);
    expect(() => atob(hash)).not.toThrow();
  });

  it('같은 코드 → 같은 해시 (결정적)', async () => {
    const h1 = await hashInviteCode('ABCD-EFGH-JKLM');
    const h2 = await hashInviteCode('ABCD-EFGH-JKLM');
    expect(h1).toBe(h2);
  });

  it('대소문자 무관 (toUpperCase 정규화)', async () => {
    const h1 = await hashInviteCode('abcd-efgh-jklm');
    const h2 = await hashInviteCode('ABCD-EFGH-JKLM');
    expect(h1).toBe(h2);
  });

  it('다른 코드 → 다른 해시', async () => {
    const h1 = await hashInviteCode('ABCD-EFGH-JKLM');
    const h2 = await hashInviteCode('WXYZ-2345-6789');
    expect(h1).not.toBe(h2);
  });
});

describe('초대 코드 전체 플로우 (E2E 시나리오)', () => {
  it('보드 생성 → 초대 코드 공유 → 참여자 unwrap → 동일 seed', async () => {
    // 1. 관리자: 보드 생성 시 encryptionSeed 생성
    const encryptionSeed = nacl.randomBytes(32);
    const boardId = 'test-board-e2e';

    // 2. 관리자: 초대 코드 생성 + wrap
    const inviteCode = generateInviteCode();
    const wrappingKey = await deriveWrappingKey(inviteCode, boardId);
    const wrapped = wrapEncryptionKey(encryptionSeed, wrappingKey);

    // 3. 서버에 해시 저장
    const codeHash = await hashInviteCode(inviteCode);
    const eAuthHash = await hashEncryptionKeyForAuth(encryptionSeed);

    // 4. 참여자: 초대 코드로 wrapping key 유도 → unwrap
    const participantWrappingKey = await deriveWrappingKey(inviteCode, boardId);
    const participantSeed = unwrapEncryptionKey(
      wrapped.ciphertext,
      wrapped.nonce,
      participantWrappingKey
    );

    // 5. 검증: 참여자가 얻은 seed === 관리자의 seed
    expect(participantSeed).not.toBeNull();
    expect(new Uint8Array(participantSeed!)).toEqual(encryptionSeed);

    // 6. 참여자의 eAuth 해시도 동일
    const participantEAuth = await hashEncryptionKeyForAuth(participantSeed!);
    expect(participantEAuth).toBe(eAuthHash);

    // 7. 초대 코드 해시 일치 검증 (서버 측)
    const participantCodeHash = await hashInviteCode(inviteCode);
    expect(participantCodeHash).toBe(codeHash);
  });

  it('초대 코드 갱신 → 이전 코드 무효화 + 기존 멤버 영향 없음', async () => {
    const encryptionSeed = nacl.randomBytes(32);
    const boardId = 'test-board-rotate';

    // 1. 초기 초대 코드
    const oldCode = generateInviteCode();
    const oldWrappingKey = await deriveWrappingKey(oldCode, boardId);
    const oldWrapped = wrapEncryptionKey(encryptionSeed, oldWrappingKey);

    // 2. 기존 멤버가 seed를 보유 (정상 작동)
    const memberSeed = unwrapEncryptionKey(
      oldWrapped.ciphertext,
      oldWrapped.nonce,
      oldWrappingKey
    );
    expect(new Uint8Array(memberSeed!)).toEqual(encryptionSeed);

    // 3. 관리자: 초대 코드 갱신
    const newCode = generateInviteCode();
    const newWrappingKey = await deriveWrappingKey(newCode, boardId);
    const newWrapped = wrapEncryptionKey(encryptionSeed, newWrappingKey);

    // 4. 새 코드로 참여: 성공
    const newParticipantKey = await deriveWrappingKey(newCode, boardId);
    const newParticipantSeed = unwrapEncryptionKey(
      newWrapped.ciphertext,
      newWrapped.nonce,
      newParticipantKey
    );
    expect(new Uint8Array(newParticipantSeed!)).toEqual(encryptionSeed);

    // 5. 이전 코드로 새 wrapped key 접근 시도: 실패
    const oldAttackerKey = await deriveWrappingKey(oldCode, boardId);
    const attackerSeed = unwrapEncryptionKey(
      newWrapped.ciphertext,
      newWrapped.nonce,
      oldAttackerKey
    );
    expect(attackerSeed).toBeNull();

    // 6. 기존 멤버: seed 직접 보유하므로 영향 없음
    const memberEAuth = await hashEncryptionKeyForAuth(memberSeed!);
    const newMemberEAuth = await hashEncryptionKeyForAuth(newParticipantSeed!);
    expect(memberEAuth).toBe(newMemberEAuth); // 같은 seed → 같은 인증
  });
});
