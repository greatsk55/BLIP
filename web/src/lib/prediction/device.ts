/**
 * Device fingerprint 생성 및 해싱
 * 계정 없는 구조에서 디바이스 식별에 사용
 */

export interface DeviceComponents {
  hardwareConcurrency?: number;
  deviceMemory?: number;
  screenWidth?: number;
  screenHeight?: number;
  colorDepth?: number;
  timezone?: string;
  language?: string;
  userAgent?: string;
}

/**
 * 디바이스 컴포넌트를 조합하여 SHA-256 fingerprint 생성
 * 동일 컴포넌트 -> 동일 해시 (결정론적)
 */
export async function generateDeviceFingerprint(
  components: DeviceComponents
): Promise<string> {
  // 키 정렬하여 순서 보장
  const sorted = Object.keys(components)
    .sort()
    .map((key) => `${key}=${components[key as keyof DeviceComponents] ?? ''}`)
    .join('|');

  return hashFingerprint(sorted);
}

/**
 * SHA-256 해시 (64자 hex 문자열 반환)
 */
export async function hashFingerprint(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
