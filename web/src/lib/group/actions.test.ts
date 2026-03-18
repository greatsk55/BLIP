/**
 * Group actions 유닛 테스트
 * Server actions는 headers(), createServerSupabase() 등에 의존하므로
 * 순수 유틸리티 로직 위주로 테스트합니다.
 */
import { describe, it, expect } from 'vitest';

// actions.ts 내부의 순수 함수 로직을 간접 테스트
// Server Actions 자체는 'use server' + next/headers 의존으로 직접 import 불가
// 대신 동일 로직을 검증

describe('Group actions — pure logic', () => {
  describe('constantTimeEqual (재구현 검증)', () => {
    function constantTimeEqual(a: string, b: string): boolean {
      if (a.length !== b.length) return false;
      let result = 0;
      for (let i = 0; i < a.length; i++) {
        result |= a.charCodeAt(i) ^ b.charCodeAt(i);
      }
      return result === 0;
    }

    it('동일 문자열은 true', () => {
      expect(constantTimeEqual('abc', 'abc')).toBe(true);
    });

    it('다른 문자열은 false', () => {
      expect(constantTimeEqual('abc', 'abd')).toBe(false);
    });

    it('길이 다르면 false', () => {
      expect(constantTimeEqual('abc', 'ab')).toBe(false);
    });

    it('빈 문자열끼리는 true', () => {
      expect(constantTimeEqual('', '')).toBe(true);
    });
  });

  describe('generateAdminToken (재구현 검증)', () => {
    function generateAdminToken(): string {
      const bytes = crypto.getRandomValues(new Uint8Array(12));
      const charset = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      const chars = Array.from(bytes).map((b) => charset[b % charset.length]);
      return `${chars.slice(0, 4).join('')}-${chars.slice(4, 8).join('')}-${chars.slice(8, 12).join('')}`;
    }

    it('XXXX-XXXX-XXXX 포맷으로 생성된다', () => {
      const token = generateAdminToken();
      expect(token).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}-[A-Z2-9]{4}$/);
    });

    it('매번 다른 값을 생성한다', () => {
      const tokens = new Set(Array.from({ length: 10 }, generateAdminToken));
      expect(tokens.size).toBe(10);
    });

    it('혼동 문자(0, O, 1, I)를 포함하지 않는다', () => {
      for (let i = 0; i < 20; i++) {
        const token = generateAdminToken().replace(/-/g, '');
        expect(token).not.toMatch(/[0O1I]/);
      }
    });
  });

  describe('hashAdminToken (재구현 검증)', () => {
    async function hashAdminToken(token: string): Promise<string> {
      const encoder = new TextEncoder();
      const data = encoder.encode(token);
      const hashBuffer = await crypto.subtle.digest('SHA-256', data);
      return Array.from(new Uint8Array(hashBuffer))
        .map((b) => b.toString(16).padStart(2, '0'))
        .join('');
    }

    it('64자 hex 문자열을 반환한다', async () => {
      const hash = await hashAdminToken('TEST-TOKEN-1234');
      expect(hash).toMatch(/^[0-9a-f]{64}$/);
    });

    it('동일 입력은 동일 해시', async () => {
      const h1 = await hashAdminToken('SAME');
      const h2 = await hashAdminToken('SAME');
      expect(h1).toBe(h2);
    });

    it('다른 입력은 다른 해시', async () => {
      const h1 = await hashAdminToken('AAA');
      const h2 = await hashAdminToken('BBB');
      expect(h1).not.toBe(h2);
    });
  });
});
