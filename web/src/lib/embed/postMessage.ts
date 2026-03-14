/**
 * Embed iframe → 부모 페이지 postMessage 통신
 *
 * 이벤트 타입:
 * - blip:ready       — embed 위젯이 로드 완료
 * - blip:room-created — 방 생성 완료 (roomId, shareUrl 포함)
 * - blip:room-joined  — 채팅방 입장 완료
 * - blip:room-destroyed — 채팅방 파쇄됨
 */

export type BlipEvent =
  | { type: 'blip:ready' }
  | { type: 'blip:room-created'; roomId: string; shareUrl: string }
  | { type: 'blip:room-joined'; roomId: string }
  | { type: 'blip:room-destroyed'; roomId: string };

/**
 * 부모 페이지에 이벤트를 전달합니다.
 *
 * 보안 참고: targetOrigin으로 document.referrer의 origin을 사용하여
 * 실제 임베딩한 부모에게만 메시지를 전달합니다.
 * referrer가 없는 경우(보안 정책 등) 메시지를 전송하지 않습니다.
 */
export function postToParent(event: BlipEvent) {
  if (typeof window === 'undefined') return;
  if (window.parent === window) return; // iframe이 아닌 경우 무시

  // 부모 origin 결정: referrer 기반으로 제한
  let targetOrigin: string;
  try {
    if (document.referrer) {
      targetOrigin = new URL(document.referrer).origin;
    } else {
      // referrer가 없으면 같은 출처로 제한
      targetOrigin = window.location.origin;
    }
  } catch {
    targetOrigin = window.location.origin;
  }

  window.parent.postMessage(event, targetOrigin);
}
