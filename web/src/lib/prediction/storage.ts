// ─── 디바이스 토큰 & 포인트 캐시 (localStorage) ───

const DEVICE_TOKEN_KEY = 'blip_device_token';
const POINTS_CACHE_KEY = 'blip_points_cache';

function isBrowser(): boolean {
  return typeof window !== 'undefined';
}

export function getDeviceToken(): string | null {
  if (!isBrowser()) return null;
  return localStorage.getItem(DEVICE_TOKEN_KEY);
}

export function setDeviceToken(token: string): void {
  if (!isBrowser()) return;
  localStorage.setItem(DEVICE_TOKEN_KEY, token);
}

export function getPointsCache(): { balance: number } | null {
  if (!isBrowser()) return null;
  try {
    const raw = localStorage.getItem(POINTS_CACHE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as { balance: number };
  } catch {
    return null;
  }
}

export function setPointsCache(data: { balance: number }): void {
  if (!isBrowser()) return;
  localStorage.setItem(POINTS_CACHE_KEY, JSON.stringify(data));
}
