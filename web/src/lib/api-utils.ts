/**
 * API Route 공용 유틸리티
 *
 * - 입력 타입 검증
 * - JSON 파싱 에러 처리
 * - CSRF origin 검증
 * - 페이지네이션 상한
 */

// ─── 타입 가드 ───

export const isString = (v: unknown): v is string =>
  typeof v === 'string' && v.length > 0;

export const isNumber = (v: unknown): v is number =>
  typeof v === 'number' && Number.isFinite(v);

export const isStringArray = (v: unknown): v is string[] =>
  Array.isArray(v) && v.every((item) => typeof item === 'string');

// ─── 안전한 JSON 파싱 ───

export async function parseJsonBody<T = Record<string, unknown>>(
  request: Request
): Promise<T | null> {
  try {
    return (await request.json()) as T;
  } catch {
    return null;
  }
}

// ─── CSRF Origin 검증 ───

const ALLOWED_ORIGINS = new Set([
  process.env.NEXT_PUBLIC_SITE_URL,
  process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : undefined,
].filter(Boolean) as string[]);

// 개발 환경에서는 localhost 허용
if (process.env.NODE_ENV === 'development') {
  ALLOWED_ORIGINS.add('http://localhost:3000');
  ALLOWED_ORIGINS.add('http://localhost:3001');
}

export function checkOrigin(request: Request): boolean {
  const origin = request.headers.get('origin');
  // origin이 없는 경우 (same-origin 요청, sendBeacon 등)
  if (!origin) return true;
  // 설정된 origin 목록에 없으면 거부
  if (ALLOWED_ORIGINS.size === 0) return true; // 설정 안 된 경우 pass
  return ALLOWED_ORIGINS.has(origin);
}

// ─── 페이지네이션 ───

export const MAX_PAGINATION_LIMIT = 50;

export function clampLimit(limit: unknown, defaultLimit = 20): number {
  if (!isNumber(limit)) return defaultLimit;
  return Math.min(Math.max(1, Math.floor(limit)), MAX_PAGINATION_LIMIT);
}

// ─── 숫자 범위 검증 ───

export function clampInt(
  value: unknown,
  min: number,
  max: number,
  fallback: number
): number {
  if (!isNumber(value)) return fallback;
  return Math.min(Math.max(min, Math.floor(value)), max);
}
