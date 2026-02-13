import { describe, it, expect } from 'vitest';
import { generateRoomPassword, generateRoomId } from './password';

describe('generateRoomPassword', () => {
  it('XXXX-XXXX 형식이다', () => {
    const password = generateRoomPassword();
    expect(password).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}$/);
  });

  it('혼동 문자(0, O, 1, I)를 포함하지 않는다', () => {
    // 100번 생성해서 전부 확인
    for (let i = 0; i < 100; i++) {
      const password = generateRoomPassword();
      expect(password).not.toMatch(/[01OI]/);
    }
  });

  it('매번 다른 값을 생성한다', () => {
    const passwords = new Set(
      Array.from({ length: 20 }, () => generateRoomPassword())
    );
    // 20개 중 최소 15개는 달라야 함 (확률적 안전마진)
    expect(passwords.size).toBeGreaterThanOrEqual(15);
  });
});

describe('generateRoomId', () => {
  it('8자리 소문자+숫자이다', () => {
    const id = generateRoomId();
    expect(id).toMatch(/^[a-z2-9]{8}$/);
  });

  it('혼동 문자(0, o, 1, l, i)를 포함하지 않는다', () => {
    for (let i = 0; i < 100; i++) {
      const id = generateRoomId();
      expect(id).not.toMatch(/[01oli]/);
    }
  });

  it('매번 다른 값을 생성한다', () => {
    const ids = new Set(
      Array.from({ length: 20 }, () => generateRoomId())
    );
    expect(ids.size).toBeGreaterThanOrEqual(15);
  });
});
