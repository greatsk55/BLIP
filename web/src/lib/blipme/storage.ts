/**
 * BLIP me 로컬 저장소 (SSOT)
 * - ownerToken: 소유권 증명 (해시만 서버에 저장)
 * - linkId: 현재 활성 링크 ID (캐시)
 */

const OWNER_TOKEN_KEY = 'blip-me-owner-token';
const LINK_ID_KEY = 'blip-me-link-id';

const isBrowser = typeof window !== 'undefined';

// ─── ownerToken 관리 ───

/** ownerToken 조회 (없으면 null) */
export function getOwnerToken(): string | null {
  if (!isBrowser) return null;
  return localStorage.getItem(OWNER_TOKEN_KEY);
}

/** ownerToken 저장 */
export function saveOwnerToken(token: string): void {
  if (!isBrowser) return;
  localStorage.setItem(OWNER_TOKEN_KEY, token);
}

/** ownerToken 삭제 */
export function removeOwnerToken(): void {
  if (!isBrowser) return;
  localStorage.removeItem(OWNER_TOKEN_KEY);
}

// ─── linkId 캐시 ───

/** 현재 활성 링크 ID 조회 */
export function getCachedLinkId(): string | null {
  if (!isBrowser) return null;
  return localStorage.getItem(LINK_ID_KEY);
}

/** 링크 ID 캐시 저장 */
export function saveLinkId(linkId: string): void {
  if (!isBrowser) return;
  localStorage.setItem(LINK_ID_KEY, linkId);
}

/** 링크 ID 캐시 삭제 */
export function removeLinkId(): void {
  if (!isBrowser) return;
  localStorage.removeItem(LINK_ID_KEY);
}

/** BLIP me 데이터 전체 삭제 */
export function clearBlipMeData(): void {
  removeOwnerToken();
  removeLinkId();
}
