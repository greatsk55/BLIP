import { describe, it, expect } from 'vitest';
import { generateUsername } from './username';

const VALID_PREFIXES = [
  'GHOST', 'SHADOW', 'CIPHER', 'VOID', 'SIGNAL', 'PHANTOM',
  'ECHO', 'PULSE', 'FLUX', 'DRIFT', 'SPARK', 'TRACE',
  'NEXUS', 'SURGE', 'ORBIT', 'PRISM',
];

describe('generateUsername', () => {
  it('PREFIX_HASH 형식이다', () => {
    const username = generateUsername();
    expect(username).toMatch(/^[A-Z]+_[a-z2-9]{4}$/);
  });

  it('PREFIX가 유효한 목록 내에 있다', () => {
    for (let i = 0; i < 50; i++) {
      const username = generateUsername();
      const prefix = username.split('_')[0];
      expect(VALID_PREFIXES).toContain(prefix);
    }
  });

  it('해시 부분은 4자리이다', () => {
    const username = generateUsername();
    const hash = username.split('_')[1];
    expect(hash.length).toBe(4);
  });
});
