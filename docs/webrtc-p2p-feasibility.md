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

---

## 2. 제안: 하이브리드 P2P 전략

### 전략

```
1:1 채팅   → WebRTC DataChannel P2P (Supabase 시그널링)
그룹 채팅  → 현재 방식 유지 (Supabase Realtime 중계)
P2P 실패 시 → 자동으로 Supabase Broadcast fallback
```

### 왜 이 전략이 BLIP에 맞는가

1. **현재 BLIP은 1:1 전용** — DB CHECK 제약(`participant_count <= 2`)부터 클라이언트 자동 퇴장까지 5단계 방어
2. **WebRTC 인프라가 이미 완성** — 양 플랫폼에서 미디어 전송으로 검증 완료
3. **Fallback으로 안정성 보장** — DataChannel 실패해도 기존 Broadcast 경로 유지
4. **그룹 채팅 확장 시 자연스러운 분기** — 멀티피어 WebRTC 메시 없이 Supabase 중계로 처리

### 전환 후 데이터 플로우

```
[1:1 텍스트 — 정상]   A ↔ WebRTC DataChannel ↔ B
[1:1 텍스트 — 실패]   A → Supabase Broadcast → B  (자동 전환)
[1:1 미디어]          A ↔ WebRTC DataChannel ↔ B  (현재와 동일)
[시그널링/키교환]      A → Supabase Broadcast → B  (현재와 동일)
[Presence/이탈감지]   A → Supabase Presence → B   (현재와 동일)
```

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

## 4. 구현 설계

### 4.1 바이너리 프로토콜 확장

기존 패킷 타입에 `PACKET_TEXT = 0x04` 추가:

```
기존:
  0x01 = HEADER  (파일 전송 시작)
  0x02 = CHUNK   (파일 청크)
  0x03 = DONE    (파일 전송 완료)
  0x05 = CANCEL  (파일 전송 취소)

추가:
  0x04 = TEXT    (텍스트 메시지)
```

**TEXT 패킷 구조:**
```
[1B type=0x04][encrypted JSON({id, senderId, senderName, ciphertext, nonce, timestamp})]
```

이미 사용 중인 `encryptMessage()` / `decryptMessage()` 함수를 그대로 활용.

### 4.2 전송 경로 결정 로직

```
sendMessage(text):
  if DataChannel.readyState === 'open':
    → DataChannel.send(PACKET_TEXT + encryptedPayload)
  else:
    → Supabase Broadcast.send('message', encryptedPayload)  // 기존 방식
```

### 4.3 수신 경로 (양쪽 모두 리스닝)

```
onDataChannelMessage(PACKET_TEXT):
  → decryptMessage() → 화면 표시

onBroadcast('message'):
  → 중복 체크(messageId) → decryptMessage() → 화면 표시
```

중복 방지: `messageId`를 `Set`에 저장, 이미 처리된 메시지는 무시.

### 4.4 Fallback 전환 시나리오

```
상태                          텍스트 경로          미디어 경로
─────────────────────────────────────────────────────────────
WebRTC 연결 전                Supabase Broadcast   대기
WebRTC 연결 성공              DataChannel          DataChannel
DataChannel 일시 끊김         Supabase Broadcast   전송 불가
ICE restart 성공              DataChannel          DataChannel
WebRTC 완전 실패              Supabase Broadcast   전송 불가
```

### 4.5 변경이 필요한 파일

**웹 (3개 파일):**

| 파일 | 변경 내용 |
|------|----------|
| `hooks/useWebRTC.ts` | `PACKET_TEXT` 수신 핸들러 추가, `sendText()` 함수 추가, DataChannel 상태 노출 |
| `hooks/useChat.ts` | `sendMessage()`에서 DataChannel 우선 시도, Broadcast fallback, 중복 메시지 필터 |
| `components/chat/ChatRoom.tsx` | `sendMessage`를 WebRTC 경유로 연결 (변경 최소) |

**모바일 (2개 파일):**

| 파일 | 변경 내용 |
|------|----------|
| `providers/webrtc_provider.dart` | `PACKET_TEXT` 수신 핸들러 추가, `sendText()` 함수 추가 |
| `providers/chat_provider.dart` | `sendMessage()`에서 DataChannel 우선 시도, Broadcast fallback, 중복 메시지 필터 |

**공통 상수:**

| 파일 | 변경 내용 |
|------|----------|
| `mobile/lib/core/constants/app_constants.dart` | `packetText = 0x04` 추가 |

---

## 5. 고려사항

### 5.1 TURN 서버 의존성

현재 BLIP은 **IP 노출 방지를 위해 TURN-only** (`iceTransportPolicy: 'relay'`) 사용.

```
현재:   A → Supabase(암호화된 메시지 경유) → B
전환 후: A → Cloudflare TURN(암호화된 바이너리 경유) → B
         ↘ Supabase(fallback, 빈도 낮음) ↗
```

- 완전한 P2P는 아니지만, 메시지 내용이 Supabase를 경유하지 않게 됨
- TURN 서버는 DTLS 위의 암호화된 바이너리만 릴레이 (내용 해독 불가)
- Supabase 서버 로그에 메시지 payload가 남을 가능성 제거

### 5.2 서버 비용 영향

| 항목 | 현재 | 전환 후 |
|------|------|---------|
| Supabase Realtime | 모든 텍스트 경유 | 시그널링/키교환 + 간헐적 fallback |
| Cloudflare TURN | 미디어만 | 텍스트 + 미디어 (미미한 증가) |
| **Supabase 비용** | **높음** | **대폭 감소** |
| **TURN 비용** | 미디어 기준 | 텍스트 추가 (미미) |

### 5.3 모바일 백그라운드 전환

- 모바일 앱이 백그라운드로 가면 WebRTC 연결이 끊어질 수 있음
- 현재도 Presence leave grace period (60초)로 이를 처리 중
- Fallback 덕분에 텍스트 전송은 즉시 Supabase 경로로 전환

### 5.4 중복 메시지 방지

DataChannel + Broadcast 양쪽에서 동시에 메시지를 수신할 가능성은 낮지만 (전송 경로는 하나만 선택), fallback 전환 시점의 race condition 방지를 위해 `processedMessageIds: Set<string>`으로 중복 필터 필요.

---

## 6. 구현 난이도 평가

| 작업 | 난이도 | 이유 |
|------|--------|------|
| PACKET_TEXT 프로토콜 추가 | **낮음** | 기존 바이너리 프로토콜에 1바이트 타입 추가 |
| DataChannel 텍스트 송수신 | **낮음** | 기존 `encryptMessage()`/`decryptMessage()` 재사용 |
| Fallback 경로 전환 | **중간** | DataChannel 상태 감시 + 전송 경로 분기 |
| 중복 메시지 필터 | **낮음** | messageId Set 체크 |
| 양 플랫폼 동기화 | **중간** | 웹/모바일 동일 프로토콜 준수 확인 |
| 테스트 | **중간** | DataChannel 끊김/복구 시나리오 테스트 |

**전체 난이도: 중간** — WebRTC 인프라가 이미 있어 새 프레임워크 도입 불필요.

---

## 7. 결론

### 이 하이브리드 전략은 적합하다

| 기준 | 평가 |
|------|------|
| 기술적 가능성 | **YES** — WebRTC 인프라 양 플랫폼에 이미 완성 |
| 안정성 | **유지** — Fallback으로 기존 안정성 보장 |
| 보안 향상 | **실질적** — 정상 경로에서 Supabase가 메시지 relay하지 않음 |
| Supabase 비용 | **대폭 감소** — 텍스트 트래픽이 P2P로 이동 |
| 구현 난이도 | **중간** — 5개 파일 수정, 기존 인프라 재사용 |
| 그룹 채팅 확장성 | **자연스러움** — 1:1은 P2P, 그룹은 Supabase |

### 이전 분석 대비 달라진 점

이전 결론이 "권장하지 않음"이었던 주요 이유와 이 전략이 해소하는 부분:

| 이전 우려 | 해소 여부 |
|-----------|----------|
| 안정성 하락 | **해소** — Fallback이 기존 안정성을 보장 |
| Supabase 제거 불가 | **해당 없음** — 제거가 아니라 역할 축소 |
| 구현 복잡도 | **수용 가능** — 인프라 이미 있음, 핵심은 전송 경로 분기뿐 |
| 실익 제한적 | **재평가** — Supabase 비용 절감 + 서버 로그 노출 제거 |
