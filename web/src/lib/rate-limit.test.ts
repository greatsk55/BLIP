import { describe, it, expect, vi, beforeEach } from 'vitest';
import { getClientIp } from './rate-limit';

// Upstash 모듈 mock (모듈 최상위 레벨에서 Redis.fromEnv() 호출하므로)
vi.mock('@upstash/redis', () => ({
  Redis: {
    fromEnv: () => ({}),
  },
}));

vi.mock('@upstash/ratelimit', () => ({
  Ratelimit: class {
    static slidingWindow = vi.fn();
    limit = vi.fn().mockResolvedValue({ success: true, remaining: 5, reset: Date.now() + 60000 });
  },
}));

describe('getClientIp', () => {
  it('x-forwarded-for에서 첫 번째 IP를 추출한다', () => {
    const headers = new Headers({
      'x-forwarded-for': '1.2.3.4, 5.6.7.8',
    });
    expect(getClientIp(headers)).toBe('1.2.3.4');
  });

  it('x-forwarded-for가 단일 IP면 그대로 반환', () => {
    const headers = new Headers({
      'x-forwarded-for': '10.0.0.1',
    });
    expect(getClientIp(headers)).toBe('10.0.0.1');
  });

  it('x-forwarded-for가 없으면 x-real-ip를 사용한다', () => {
    const headers = new Headers({
      'x-real-ip': '192.168.1.1',
    });
    expect(getClientIp(headers)).toBe('192.168.1.1');
  });

  it('둘 다 없으면 "unknown"을 반환한다', () => {
    const headers = new Headers();
    expect(getClientIp(headers)).toBe('unknown');
  });

  it('x-forwarded-for의 공백을 trim한다', () => {
    const headers = new Headers({
      'x-forwarded-for': '  3.3.3.3  , 4.4.4.4',
    });
    expect(getClientIp(headers)).toBe('3.3.3.3');
  });
});
