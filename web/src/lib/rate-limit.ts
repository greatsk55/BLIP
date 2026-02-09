/**
 * Upstash Redis 기반 Rate Limiter
 *
 * Sliding Window 알고리즘으로 서버리스 환경(Vercel)에서도
 * 인스턴스 간 상태 공유가 보장됨
 */

import { Redis } from '@upstash/redis';
import { Ratelimit } from '@upstash/ratelimit';

const redis = Redis.fromEnv();

export interface RateLimitConfig {
  windowMs: number;
  maxRequests: number;
}

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  retryAfterMs?: number;
}

// Ratelimit 인스턴스 캐시 (동일 설정 재사용)
const limiterCache = new Map<string, Ratelimit>();

function getLimiter(config: RateLimitConfig): Ratelimit {
  const cacheKey = `${config.windowMs}:${config.maxRequests}`;
  let limiter = limiterCache.get(cacheKey);
  if (!limiter) {
    const windowSec = `${Math.ceil(config.windowMs / 1000)} s` as `${number} s`;
    limiter = new Ratelimit({
      redis,
      limiter: Ratelimit.slidingWindow(config.maxRequests, windowSec),
      prefix: 'blip:rl',
    });
    limiterCache.set(cacheKey, limiter);
  }
  return limiter;
}

export async function checkRateLimit(
  key: string,
  config: RateLimitConfig
): Promise<RateLimitResult> {
  const limiter = getLimiter(config);
  const { success, remaining, reset } = await limiter.limit(key);

  return {
    allowed: success,
    remaining,
    retryAfterMs: success ? undefined : Math.max(0, reset - Date.now()),
  };
}

/**
 * IP 주소 추출 (Next.js headers)
 */
export function getClientIp(headersList: Headers): string {
  return (
    headersList.get('x-forwarded-for')?.split(',')[0]?.trim() ??
    headersList.get('x-real-ip') ??
    'unknown'
  );
}
