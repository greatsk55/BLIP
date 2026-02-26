# WebRTC P2P 텍스트 메시지 전환 타당성 분석

## 1. 현재 아키텍처 분석

### 현재 데이터 플로우

```
[텍스트 메시지] 사용자A → Supabase Broadcast(서버) → 사용자B
[미디어 파일]   사용자A → WebRTC DataChannel(P2P) → 사용자B
[시그널링]      사용자A → Supabase Broadcast(서버) → 사용자B
```

### 핵심 발견: WebRTC는 이미 구현되어 있다

BLIP 프로젝트에는 **WebRTC DataChannel 기반 P2P 파일 전송이 이미 양 플랫폼에 구현**되어 있다.

| 구성요소 | 웹 | 모바일 |
|---------|-----|--------|
| WebRTC 구현 | `web/src/hooks/useWebRTC.ts` | `mobile/lib/features/chat/providers/webrtc_provider.dart` |
| 시그널링 | Supabase Broadcast 경유 | Supabase Broadcast 경유 |
| TURN 서버 | Cloudflare Calls (`/api/turn-credentials`) | 동일 API 호출 |
| ICE 정책 | `iceTransportPolicy: 'relay'` (TURN only) | `iceTransportPolicy: 'relay'` (TURN only) |
| DataChannel | ordered=true, maxRetransmits=30 | ordered=true (SCTP reliable) |
| 암호화 | 공유 비밀키로 각 청크 암호화 | 동일 |
| 바이너리 프로토콜 | HEADER→CHUNK→DONE→CANCEL | 동일 (상호운용) |

**즉, 피드백이 제안하는 "서버가 시그널링만 하고 이후 P2P" 패턴은 미디어 전송에서 이미 작동 중이다.**

---

## 2. 제안: 텍스트 메시지도 WebRTC DataChannel로 전환

### 현재 구조 vs 제안 구조

```
현재 (텍스트):
  A → Supabase Broadcast(서버 경유) → B
  장점: 안정적, 이미 동작
  단점: 서버가 암호화된 패킷을 중계

제안 (텍스트):
  A ↔ B (WebRTC DataChannel, P2P)
  장점: 서버가 데이터 전송에 관여하지 않음
  단점: 연결 안정성 이슈, 추가 복잡도
```

### 기술적 타당성: YES (조건부)

양 플랫폼에서 WebRTC DataChannel이 이미 파일 전송용으로 사용 중이므로, 텍스트 메시지를 같은 DataChannel로 전송하는 것은 **기술적으로 가능**하다.

---

## 3. 플랫폼별 분석

### 3.1 웹 (Next.js + React)

**가능 여부: YES**

- `RTCPeerConnection` + `RTCDataChannel`은 모든 모던 브라우저에서 지원
- 현재 `useWebRTC.ts`에서 `RTCDataChannel`이 바이너리 파일 전송에 사용 중
- 텍스트 메시지 전송은 단순히 `dc.send(encryptedTextPayload)` 호출로 추가 가능
- `ordered: true` 설정으로 메시지 순서 보장됨

**브라우저 지원 현황:**

| 브라우저 | DataChannel | 비고 |
|---------|-------------|------|
| Chrome 26+ | O | |
| Firefox 22+ | O | |
| Safari 11+ | O | |
| Edge 79+ | O | |
| iOS Safari 11+ | O | |
| Samsung Internet | O | |

### 3.2 모바일 (Flutter)

**가능 여부: YES**

- `flutter_webrtc: ^0.12.3`이 이미 의존성에 포함
- `webrtc_provider.dart`에서 `RTCDataChannel`로 바이너리 프로토콜 구현 완료
- Android/iOS 네이티브 WebRTC 지원 (libwebrtc)
- `AndroidManifest.xml`에 `INTERNET`, `CAMERA`, `RECORD_AUDIO` 권한 이미 설정

**플랫폼별:**

| 플랫폼 | flutter_webrtc | 비고 |
|--------|---------------|------|
| Android 5.0+ | O | Google WebRTC (libwebrtc) |
| iOS 11+ | O | Apple WebRTC framework |

### 3.3 웹-모바일 간 상호운용

**가능 여부: YES**

- 현재 미디어 전송의 바이너리 프로토콜이 이미 웹↔모바일 상호운용되고 있음
- 동일한 DataChannel로 텍스트를 보내면 자동으로 상호운용됨

---

## 4. 구현 시 고려사항

### 4.1 연결 안정성 (가장 큰 리스크)

**현재 안정성 모델:**
```
텍스트: Supabase WebSocket → 서버가 재연결 관리 → 매우 안정적
미디어: WebRTC DataChannel → P2P, TURN 의존 → 간헐적 끊김 가능
```

**전환 후 리스크:**
- WebRTC DataChannel이 유일한 통신 경로가 되면, ICE 재연결 실패 시 **텍스트 전송 불가**
- 현재는 미디어 전송 실패해도 텍스트 채팅은 계속 가능하지만, 전환 후에는 둘 다 중단
- 모바일에서 앱이 백그라운드로 가면 WebRTC 연결이 끊어질 수 있음

**대응 방안:**
```
1. Fallback: DataChannel 끊어지면 Supabase Broadcast로 자동 전환
2. 재연결: ICE restart 메커니즘 구현
3. 하이브리드: 텍스트는 DataChannel 우선, 실패 시 Broadcast 경유
```

### 4.2 Supabase는 여전히 필요

WebRTC로 전환해도 다음 이유로 **Supabase Realtime은 제거 불가:**

1. **시그널링 채널** — WebRTC 연결 수립 전 Offer/Answer/ICE 교환
2. **키 교환** — ECDH 공개키 브로드캐스트
3. **Presence** — 상대방 온라인 상태 추적
4. **이탈 감지** — `user_left` 이벤트로 방 파쇄 트리거
5. **ICE 재시작** — 연결 복구 시 새 Offer/Answer 교환

```
전환 후에도:
  시그널링 + 키교환 + Presence: Supabase Broadcast (유지)
  텍스트 + 미디어: WebRTC DataChannel (P2P)
```

### 4.3 TURN 서버 의존성

현재 BLIP은 **IP 노출 방지를 위해 TURN-only** (`iceTransportPolicy: 'relay'`)를 사용 중.

```typescript
// web: useWebRTC.ts
const pc = new RTCPeerConnection({
  iceServers,
  iceTransportPolicy: 'relay',  // TURN-only
});
```

이는 P2P 전환 후에도 유지해야 하며, 이것이 의미하는 바:
- **진정한 P2P가 아님**: 데이터가 TURN 서버를 경유 (릴레이)
- **서버 의존성 여전히 존재**: Cloudflare TURN 서버
- **하지만**: Supabase 서버가 아닌 전용 미디어 릴레이 서버를 경유하므로, Supabase가 메시지를 볼 수 없음

```
현재:   A → Supabase(메시지 내용 경유) → B
전환 후: A → Cloudflare TURN(암호화된 바이너리만 경유) → B
```

**STUN-only로 변경 시 (진정한 P2P):**
- `iceTransportPolicy: 'all'`로 변경하면 STUN으로 직접 연결 시도
- **리스크**: 양쪽 IP가 서로에게 노출됨 → BLIP의 "익명성" 철학 위반
- **NAT 통과 실패 시**: 연결 불가 (TURN fallback 없음)

### 4.4 서버 비용 영향

| 항목 | 현재 | 텍스트 P2P 전환 후 |
|------|------|-------------------|
| Supabase Realtime 사용량 | 모든 메시지 경유 | 시그널링/키교환만 경유 (대폭 감소) |
| TURN 트래픽 | 미디어만 | 텍스트 + 미디어 (소폭 증가) |
| Cloudflare TURN 비용 | 미디어 기준 | 텍스트 추가 (미미한 증가) |

텍스트 메시지는 매우 작으므로 TURN 트래픽 증가는 미미하고, Supabase Realtime 사용량은 크게 줄어든다.

---

## 5. 구현 복잡도 분석

### 변경이 필요한 파일

**웹:**
| 파일 | 변경 내용 |
|------|----------|
| `hooks/useChat.ts` | 텍스트 전송을 DataChannel로 변경, Broadcast 폴백 |
| `hooks/useWebRTC.ts` | 텍스트 메시지 수신 핸들러 추가 |
| `components/chat/ChatRoom.tsx` | WebRTC 연결 전 텍스트 전송 로직 조정 |

**모바일:**
| 파일 | 변경 내용 |
|------|----------|
| `providers/chat_provider.dart` | 텍스트 전송을 DataChannel로 변경, Broadcast 폴백 |
| `providers/webrtc_provider.dart` | 텍스트 메시지 수신 핸들러 추가 |

### 예상 난이도: 중간

- WebRTC 인프라가 이미 구축되어 있으므로 새 프로토콜 설계 불필요
- 바이너리 프로토콜에 `PACKET_TEXT = 0x04` 추가하면 기존 프레임워크 재사용 가능
- 가장 큰 작업은 **Fallback 로직** 구현 (DataChannel 끊어졌을 때 Broadcast 경유)

---

## 6. 결론 및 권장사항

### 결론: 구조적으로 가능, 하지만 실익이 제한적

| 기준 | 평가 |
|------|------|
| 기술적 가능성 | **YES** — 양 플랫폼에 WebRTC 이미 구현 |
| 웹 지원 | **YES** — 모든 모던 브라우저 지원 |
| 모바일 지원 | **YES** — flutter_webrtc 이미 동작 중 |
| 상호운용 | **YES** — 웹↔모바일 이미 검증됨 |
| 보안 향상 | **제한적** — TURN-only이므로 TURN 서버 경유, 이미 E2EE |
| 안정성 | **하락 리스크** — WebRTC 연결이 유일 경로가 됨 |
| 구현 난이도 | **중간** — 인프라 있음, 폴백 로직이 핵심 |

### 권장: 현재 아키텍처 유지

**이유:**

1. **이미 E2EE가 적용되어 있다**
   - 서버가 데이터를 경유하지만, 평문을 볼 수 없음
   - `nacl.box.after()` (XSalsa20-Poly1305)로 암호화된 ciphertext만 전달
   - P2P로 전환해도 보안 수준이 실질적으로 향상되지 않음

2. **TURN-only 정책 때문에 진정한 P2P가 아니다**
   - IP 노출 방지를 위해 `iceTransportPolicy: 'relay'` 사용 중
   - TURN 서버가 릴레이 역할을 하므로, "서버가 빠지는" 구조가 아님
   - Supabase 대신 Cloudflare TURN 서버가 중계할 뿐

3. **안정성이 더 중요하다**
   - 임시적 채팅 서비스의 핵심은 "즉시 연결, 즉시 대화"
   - WebRTC DataChannel은 NAT/방화벽 환경에서 연결 실패 가능성이 있음
   - Supabase Broadcast는 WebSocket 기반으로 거의 모든 환경에서 안정적

4. **Supabase 제거 불가**
   - 시그널링, 키 교환, Presence, 이탈 감지를 위해 여전히 필요
   - 두 개의 실시간 경로 관리 → 복잡도 증가

### 만약 전환한다면

하이브리드 접근이 가장 현실적:

```
1단계: DataChannel 연결 성공 시 텍스트도 DataChannel로 전송
2단계: DataChannel 끊어지면 자동으로 Supabase Broadcast 폴백
3단계: 재연결 시 다시 DataChannel로 전환
```

이 접근은 안정성을 유지하면서 가능한 경우 P2P 경로를 사용한다. 단, 양 플랫폼의 코드 복잡도가 증가하며 테스트 범위도 확장된다.

---

## 7. 요약

```
Q: WebRTC P2P로 텍스트 메시지를 전환할 수 있는가?
A: YES — 기술적으로 가능. WebRTC 인프라가 이미 양 플랫폼에 구현됨.

Q: 해야 하는가?
A: 현 시점에서 권장하지 않음.
   - E2EE로 이미 서버가 메시지 내용을 볼 수 없음
   - TURN-only 정책으로 진정한 P2P가 아님
   - 안정성 저하 리스크 > 보안 향상 효과
   - 구현/유지보수 복잡도 증가
```
