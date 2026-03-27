/**
 * Idempotency key 유틸리티
 *
 * 실제 멱등성 보장은 DB의 UNIQUE 제약(idempotency_key 컬럼)으로 처리.
 * 이 모듈은 클라이언트에서 키를 생성하는 헬퍼만 제공합니다.
 */

/**
 * 클라이언트용 idempotency key 생성
 * format: {prefix}-{timestamp}-{random}
 */
export function generateIdempotencyKey(prefix: string = 'bet'): string {
  const timestamp = Date.now().toString(36);
  const random = crypto.getRandomValues(new Uint8Array(8));
  const hex = Array.from(random)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return `${prefix}-${timestamp}-${hex}`;
}
