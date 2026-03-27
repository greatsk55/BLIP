# BLIP 익명 예측 투표 — 통합 PRD v1.0

> **작성일**: 2026-03-25
> **버전**: v1.0 (MVP 기획)
> **목표 릴리즈**: v2.0.0
> **팀**: PM / UX / Backend / Frontend Web / Mobile / Growth

---

## 1. Executive Summary

### 한 줄 정의
**"매일 새 질문 → 익명 투표 → 결과 공개 → 맞춘 쾌감 → 토론"**

### Why Now?
BLIP은 "잠깐 쓰고 버리는 통신 도구"로 성공적인 포지셔닝을 했지만, **일회성 도구의 한계**로 DAU/리텐션이 약하다. 익명 예측 투표는:

- BLIP의 **익명 + 계정 없음** 철학과 완벽히 부합
- **매일 돌아오는 이유** 생성 (도파민 루프)
- 투표 → 토론방 연결로 **기존 채팅 기능** 시너지
- 돈 안 걸어서 **법적 리스크 제로** (도박법 회피)

### 핵심 수치 목표

| 지표 | 현재 | 목표 | 증가율 |
|------|------|------|--------|
| DAU | 10K | 13K | +30% |
| D7 재방문율 | ~10% | 25-35% | +150% |
| D30 재방문율 | ~3% | 10-15% | +400% |
| 평균 세션 시간 | 3-5분 | 4-6분 | +30% |
| 광고 노출/DAU | 1회 | 2회 | +100% |

---

## 2. 기능 개요

### 2.1 사용자 플로우

```
아침 9AM ─── 푸시: "새로운 예측이 열렸어요!" ──→ 앱/웹 진입
    │
    ▼
투표 메인 ── 오늘의 질문 카드 리스트 ──→ 카테고리 필터
    │
    ▼
질문 상세 ── "트럼프 탄핵될까?" ──→ [YES] [NO] 원탭 투표 (3초)
    │
    ▼
투표 완료 ── "투표 완료! 결과는 내일 공개" ──→ [토론방 참여] CTA
    │
    ▼
다음날 ──── 푸시: "결과 공개! 당신은 맞췄어요 🎯"
    │
    ▼
결과 화면 ── 애니메이션 차트 + 내 예측 맞았는지 ──→ [토론방] [공유]
    │
    ▼
새 질문 ──── 루프 반복
```

### 2.2 핵심 기능

| 기능 | 설명 | MVP | Phase 2 |
|------|------|:---:|:-------:|
| Daily Poll | 매일 새 질문 자동 배포 | ✅ | |
| Binary 투표 | Yes/No 선택 | ✅ | |
| Multiple Choice | 다지선다 (최대 5개) | ✅ | |
| Numeric 예측 | 숫자 범위 예측 | | ✅ |
| 실시간 투표 수 | Supabase Broadcast | ✅ | |
| 결과 공개 | 애니메이션 차트 | ✅ | |
| 토론방 자동 생성 | 투표→채팅 연결 | ✅ | |
| 로컬 스코어 | 적중률/스트릭 (localStorage) | ✅ | |
| 배지 시스템 | 예측 신, 연속왕 등 | ✅ | |
| 푸시 알림 | 새 질문 + 결과 공개 | ✅ | |
| 커뮤니티 질문 제출 | 유저가 질문 만들기 | | ✅ |
| 글로벌 랭킹 | 익명 주간 랭킹 | | ✅ |
| OG 공유 카드 | "나 맞췄다" SNS 공유 | | ✅ |
| AI 요약 | 투표+토론 인사이트 | | ✅ |

### 2.3 카테고리

| ID | 이름 | 아이콘 | 예시 |
|----|------|--------|------|
| politics | 정치 | landmark | "이재명 유죄?" |
| sports | 스포츠 | trophy | "손흥민 이번 경기 골?" |
| tech | 기술 | cpu | "AI가 AGI에 도달?" |
| economy | 경제 | trending-up | "비트코인 7만 돌파?" |
| entertainment | 연예 | popcorn | "BTS 컴백 첫주 100만장?" |
| society | 사회 | users | "출산율 반등할까?" |
| gaming | 게임 | gamepad | "GTA6 올해 출시?" |
| other | 기타 | help-circle | 자유 주제 |

---

## 3. 아키텍처 설계

### 3.1 데이터베이스 (Supabase PostgreSQL)

```sql
-- 006_predictions.sql

CREATE TABLE predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_encrypted TEXT NOT NULL,      -- E2EE 암호화된 질문
  question_nonce TEXT NOT NULL,
  category TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('yes_no', 'multiple', 'numeric')),
  options JSONB,                          -- 다지선다 옵션
  correct_answer TEXT,                    -- 공개 후 저장
  created_at TIMESTAMPTZ DEFAULT NOW(),
  closes_at TIMESTAMPTZ NOT NULL,         -- 투표 마감
  reveals_at TIMESTAMPTZ NOT NULL,        -- 결과 공개
  status TEXT DEFAULT 'active'
    CHECK (status IN ('active', 'closed', 'revealed', 'archived')),
  vote_count INT DEFAULT 0,
  source TEXT DEFAULT 'admin',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE prediction_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID NOT NULL REFERENCES predictions(id) ON DELETE CASCADE,
  answer TEXT NOT NULL,
  voter_fingerprint TEXT NOT NULL,        -- SHA-256 해시 (익명)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(prediction_id, voter_fingerprint)  -- 중복 투표 방지
);

CREATE TABLE prediction_categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  color TEXT
);

CREATE TABLE prediction_discussions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID REFERENCES predictions(id) ON DELETE CASCADE,
  room_id TEXT,                           -- 기존 채팅방 ID
  side TEXT CHECK (side IN ('yes', 'no', 'neutral')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS: 모든 테이블 anon 차단, service_role만 접근
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prediction_votes ENABLE ROW LEVEL SECURITY;

-- 인덱스
CREATE INDEX idx_predictions_status ON predictions(status, closes_at);
CREATE INDEX idx_predictions_reveals ON predictions(reveals_at) WHERE status = 'closed';
CREATE INDEX idx_votes_prediction ON prediction_votes(prediction_id);

-- 결과 공개 후 투표 기록 자동 삭제 (BLIP 철학)
-- pg_cron: 매일 03:00 UTC
SELECT cron.schedule('cleanup-prediction-votes', '0 3 * * *', $$
  DELETE FROM prediction_votes
  WHERE prediction_id IN (
    SELECT id FROM predictions
    WHERE status = 'revealed' AND reveals_at < NOW() - INTERVAL '30 days'
  );
$$);
```

### 3.2 API 설계

| Method | Endpoint | 설명 | Rate Limit |
|--------|----------|------|------------|
| GET | `/api/predictions` | 활성 질문 목록 | 10/분 |
| GET | `/api/predictions/[id]` | 질문 상세 | 20/분 |
| POST | `/api/predictions/[id]/vote` | 투표 제출 | 5/분/fingerprint |
| GET | `/api/predictions/[id]/results` | 결과 조회 | 10/분 |
| POST | `/api/predictions/submit` | 유저 질문 제출 (Phase 2) | 1/시간 |

### 3.3 Server Action (투표 핵심 로직)

```typescript
// web/src/lib/predictions/actions.ts
'use server';

export async function votePrediction(
  predictionId: string,
  answer: string,
  voterFingerprint: string
): Promise<{ success: boolean; error?: string }> {
  // 1. Rate limit 검증
  // 2. 예측 존재 + 투표 기간 확인
  // 3. answer 유효성 (yes_no → yes|no만)
  // 4. UNIQUE 제약으로 중복 방지
  // 5. vote_count 원자적 증가
  // 6. Broadcast로 실시간 업데이트
}
```

### 3.4 익명성 보장 (voter_fingerprint)

```
SHA-256(
  browser_fingerprint      // UA + language + platform + screen
  + sessionToken           // Supabase Realtime 채널 ID
  + SALT                   // 서버 환경변수
)
→ 64자 hex 문자열
→ DB에 해시만 저장 (역추적 불가)
→ UNIQUE(prediction_id, voter_fingerprint)로 중복 방지
```

**핵심**: IP 저장 안 함, 계정 없음, 개인 식별 불가능

### 3.5 실시간 (Supabase Broadcast)

```typescript
// 채널: predictions:{predictionId}
// 이벤트:
// - vote_count_updated (5초 배치)
// - voting_closed
// - results_revealed

supabase.channel(`predictions:${id}`)
  .on('broadcast', { event: 'vote_count_updated' }, (payload) => {
    setVoteCount(payload.voteCount);
  })
  .subscribe();
```

### 3.6 스케줄링 (Vercel Cron)

```json
// vercel.json
{
  "crons": [
    { "path": "/api/cron/predictions", "schedule": "*/2 * * * *" }
  ]
}
```

- **매 2분**: active → closed (마감 시간 도달)
- **매 2분**: closed → revealed (공개 시간 도달) + Broadcast
- **매일 03:00**: 오래된 투표 기록 삭제

---

## 4. 웹 프론트엔드 (Next.js)

### 4.1 라우트 구조

```
/[locale]/vote/                  → 투표 메인 (질문 리스트)
/[locale]/vote/[id]              → 질문 상세 + 투표
/[locale]/vote/[id]/results      → 결과 페이지
```

### 4.2 컴포넌트 구조

```
web/src/
├── app/[locale]/vote/
│   ├── page.tsx                  # SSR 메타데이터
│   ├── VoteClient.tsx            # 메인 클라이언트
│   └── [id]/
│       ├── page.tsx
│       ├── VoteDetailClient.tsx
│       └── results/
│           ├── page.tsx
│           └── VoteResultsClient.tsx
├── components/vote/
│   ├── PredictionCard.tsx        # 질문 카드
│   ├── VoteButton.tsx            # YES/NO 버튼
│   ├── CountdownTimer.tsx        # 마감 카운트다운
│   ├── ResultChart.tsx           # 결과 차트 (Framer Motion)
│   ├── CategoryFilter.tsx        # 카테고리 탭
│   ├── PredictionFeed.tsx        # 질문 피드
│   └── DiscussionCTA.tsx         # 토론방 CTA
├── hooks/
│   ├── useVote.ts                # 투표 상태 + Realtime
│   └── usePredictionList.ts      # 목록 + 페이지네이션
├── lib/vote/
│   ├── actions.ts                # Server Actions
│   └── device-token.ts           # 익명 fingerprint
└── types/vote.ts                 # 타입 정의
```

### 4.3 핵심 컴포넌트

**VoteButton 상태**:
```
IDLE     → border: signal-green/30, text: ghost-grey
HOVER    → border: signal-green, bg: signal-green/10, scale: 1.02
SELECTED → bg: signal-green, text: void-black, checkmark 애니메이션
DISABLED → opacity: 0.5
```

**ResultChart 애니메이션** (Framer Motion):
```
t=0.0  배경 fade in
t=0.2  제목 등장 (scale 0→1)
t=0.4  차트 바 scaleX(0→1) stagger
t=0.6  숫자 카운트업
t=1.2  내 투표 하이라이트 pulse
t=1.5  다음 투표 카드 등장
```

### 4.4 랜딩 페이지 개선

기존 페이지에 **PredictionCTA** 섹션 추가 (Solution 다음):

```
Hero → Problem → Solution → [PredictionCTA] → CommunityBoard → BlipMe → Philosophy
```

섹션 내용:
- "PREDICT. DISCUSS. DECIDE."
- 오늘의 핫 예측 3개 미니 카드
- [Predict Now] / [Create Poll] CTA

### 4.5 i18n (8개 언어)

```json
{
  "Vote": {
    "title": "Prediction Market",
    "description": "Anonymous prediction voting. No accounts, no traces.",
    "categories": { "all": "All", "tech": "Technology", ... },
    "vote": { "yes": "Yes", "no": "No", "yourVote": "Your vote" },
    "buttons": { "discuss": "Start Discussion" },
    "results": { "title": "Results", "closed": "Voting closed" }
  }
}
```

---

## 5. 모바일 앱 (Flutter)

### 5.1 화면 구조

```
바텀 네비게이션 (기존 3탭 유지)
├─ Tab 0: Home (투표 홍보 배너 추가)
├─ Tab 1: Chat
├─ Tab 2: Community
│
└─ 전체 화면 라우트 (GoRouter)
   ├─ /prediction/list           → PredictionListScreen
   ├─ /prediction/:pollId        → PredictionDetailScreen
   └─ /prediction/:pollId/result → PredictionResultScreen
```

### 5.2 파일 구조

```
mobile/lib/features/prediction/
├── domain/models/
│   ├── prediction_poll.dart      # DecryptedPoll 모델
│   ├── prediction_option.dart    # 옵션 모델
│   └── user_vote.dart            # 로컬 투표 기록
├── providers/
│   └── prediction_provider.dart  # Riverpod StateNotifier
├── presentation/
│   ├── prediction_list_screen.dart
│   ├── prediction_detail_screen.dart
│   ├── prediction_result_screen.dart
│   └── widgets/
│       ├── prediction_card.dart
│       ├── vote_button.dart
│       ├── countdown_timer.dart
│       ├── result_bar_chart.dart
│       └── category_chip.dart
```

### 5.3 상태 관리 (Riverpod)

```dart
class PredictionState {
  final List<DecryptedPoll> polls;
  final PredictionStatus status;        // loading, browsing, voted, error
  final Map<String, UserVote> userVotes; // pollId → UserVote (로컬)
  // copyWith() 패턴 (기존 BoardState와 동일)
}

class PredictionNotifier extends StateNotifier<PredictionState> {
  Future<void> loadPolls() async { ... }
  void subscribeToPollUpdates(String pollId) { ... }
  Future<void> submitVote(String pollId, String optionId) async { ... }
}
```

### 5.4 기존 코드 재활용

| 기존 | 새 기능 적용 |
|------|------------|
| BoardNotifier 패턴 | PredictionNotifier (동일 구조) |
| Supabase Realtime (Board) | 투표율 실시간 업데이트 |
| DecryptedPost 모델 | DecryptedPoll 모델 |
| LocalStorageService | UserVote 저장 추가 |
| FCM PushService | prediction_poll_result 타입 추가 |
| GoRouter 라우팅 | 3개 경로 추가 |
| ApiClient (Dio) | getPredictionPolls 메서드 추가 |

### 5.5 푸시 알림 딥링크

```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  if (message.data['type'] == 'prediction_poll_result') {
    context.push('/prediction/${message.data['pollId']}/result');
  }
});
```

---

## 6. 스코어 & 게이미피케이션

### 6.1 로컬 스코어 (서버 저장 안 함 = BLIP 철학)

```typescript
interface PollScore {
  correctVotes: number;     // 맞춘 수
  totalVotes: number;       // 전체 투표 수
  accuracy: number;         // 적중률 %
  streak: number;           // 연속 정답
  badges: PollBadge[];      // 획득 배지
}
// localStorage(웹) / SharedPreferences(앱)에만 저장
// 서버는 사용자의 정확도를 알 수 없음
```

### 6.2 배지 시스템

| 배지 | 조건 | 아이콘 |
|------|------|--------|
| First Correct | 첫 정답 | 🎯 |
| 3-Day Streak | 3연승 | 🔥 |
| 7-Day Streak | 7연승 | ⚡ |
| Perfect Week | 주간 100% | 💎 |
| Prediction Oracle | 7일+90% | 🌟 |

---

## 7. 리텐션 전략

### 7.1 Daily Loop

```
09:00 → 푸시: "새 질문 열림" ────→ 투표 (3초)
                                      │
24:00 → 투표 마감 ──────────────→ 결과 대기
                                      │
다음날 09:00 → 푸시: "결과 공개!" → 확인 + 새 질문 → 루프
```

### 7.2 Weekly Loop

- 월요일: 주간 예측왕 발표 (익명 랭킹)
- 금요일: 이주의 핫 토픽 회고

### 7.3 예상 전환율

| 시점 | 전환율 | 근거 |
|------|--------|------|
| D1 | 70%+ | 원탭 투표, 마찰 제로 |
| D7 | 25-35% | 결과 확인 재방문 |
| D30 | 10-15% | 습관화 + 스트릭 |

---

## 8. 수익화

### 8.1 광고 배치

```
1️⃣ 투표 화면 하단: 300x250 (모바일 320x50)
2️⃣ 결과 공개 화면: 차트 하단 300x250
3️⃣ 토론방 진입 전: 배너 (기존 채팅 광고 패턴)
4️⃣ 카테고리 필터: 리더보드 728x90
```

### 8.2 수익 예상

```
기존: 10K DAU × 30일 × 1.2 노출 × $2 eCPM = $720K/년
투표 후: 13K DAU × 30일 × 2.0 노출 × $2 eCPM = $1,560K/년
증가율: +116%
```

---

## 9. 바이럴 전략

### 9.1 공유 메커니즘

- 투표 후 → [SHARE] → SNS 공유 (Twitter, Discord, Telegram)
- 결과 확인 후 → "나 맞췄다 🎯" 카드 공유
- OG 이미지 자동 생성 (`/api/og/prediction/[id]`)

### 9.2 투표→토론방 연결

투표 결과 공개 시 자동으로 E2EE 토론방 생성:
- 찬성파 vs 반대파 방
- 기존 채팅 로직 100% 재활용
- 48시간 후 자동 파쇄

---

## 10. 보안 체크리스트

- [x] voter_fingerprint: SHA-256 해시만 저장 (IP 저장 안 함)
- [x] UNIQUE 제약: 중복 투표 방지
- [x] Rate Limit: Upstash Redis (IP + fingerprint)
- [x] RLS: anon 전면 차단, service_role만 접근
- [x] 타이밍 공격 방어: 고정 200ms 응답
- [x] CSRF: checkOrigin() 검증
- [x] XSS: dangerouslySetInnerHTML 사용 금지
- [x] 데이터 정책: 결과 공개 30일 후 투표 기록 자동 삭제
- [x] 도박법: "투표/예측" 용어만 사용, 현금 상품 없음

---

## 11. 정책 & 가이드라인

### 11.1 질문 정책

| 주제 | 허용 | 예시 |
|------|------|------|
| 정치 (중립 표현) | ✅ | "GDP 성장률 2% 이상?" |
| 스포츠 | ✅ | "손흥민 골 넣을까?" |
| 경제/기술 | ✅ | "비트코인 7만 돌파?" |
| 성/젠더 | ⚠️ 신중 | 사전 검토 필수 |
| 폭력/혐오 | ❌ 금지 | |
| 도박/약물 | ❌ 금지 | |
| 개인 특정 | ❌ 금지 | 특정인 소문 투표 |

### 11.2 법적 스탠스

- "예측 게임"이지 "도박"이 아님
- 현금 상품 없음, 점수만 (로컬 저장)
- "보유하지 않은 데이터는 제공할 수 없음"

---

## 12. 경쟁 분석

| 서비스 | 비용 | 익명 | 즉시성 | 토론 | BLIP 우위 |
|--------|------|------|--------|------|-----------|
| Polymarket | 💰 유료 | ❌ | ⏱ 느림 | ❌ | ✅ 무료+익명+빠름 |
| Manifold | 무료 | ❌ 계정 | ⏱ 느림 | ❌ | ✅ 계정 없음+토론 |
| Metaculus | 무료 | ❌ 계정 | ⏱ 느림 | 제한 | ✅ 익명+E2EE 토론 |
| **BLIP** | **무료** | **✅ 완전** | **✅ 3초** | **✅ E2EE** | **🏆** |

---

## 13. 구현 로드맵

### Phase 1: MVP (4주)

| 주차 | 작업 | 담당 |
|------|------|------|
| Week 1 | DB 스키마 + API + 타입 정의 | Backend |
| Week 2 | 웹 UI (카드, 버튼, 타이머) + 훅 | Frontend Web |
| Week 3 | Flutter UI + Riverpod + 로컬 저장 | Mobile |
| Week 4 | 실시간(Broadcast) + 푸시 + i18n 8개 언어 | 전체 |

### Phase 2: Growth (2주)

| 작업 | 담당 |
|------|------|
| 랜딩 페이지 PredictionCTA 섹션 | Frontend Web |
| 스트릭/배지 게이미피케이션 | Frontend + Mobile |
| OG 이미지 동적 생성 | Backend |
| A/B 테스트 프레임워크 | Growth |

### Phase 3: 확장 (이후)

- Numeric prediction (범위 투표)
- 커뮤니티 질문 제출 + 승인
- 주간 익명 랭킹
- AI 투표+토론 요약

---

## 14. 디자인 시스템

### 색상

| 요소 | 색상 | 용도 |
|------|------|------|
| YES 투표 | `signal-green` (#00FF94) | 긍정 |
| NO 투표 | `glitch-red` (#FF2A6D) | 부정 |
| 배경 | `void-black` (#050505) | 메인 |
| 텍스트 | `ink` (#FFFFFF) | 본문 |
| 보조 | `ghost-grey` (#888888) | 메타 |

### 애니메이션

| 동작 | 시간 | 이징 |
|------|------|------|
| 버튼 호버 | 300ms | easeOut |
| 페이지 진입 | 600ms | easeOut |
| 결과 차트 | 1000ms | easeInOut |
| 투표 확인 | 300ms | spring |

### 타이포그래피

- 질문: font-sans, 20px, bold
- 카테고리: font-mono, 12px, uppercase
- 투표 수: font-mono, 16px, signal-green
- 버튼: font-mono, 14px, bold, uppercase

---

## 15. 테스트 계획

### Unit Tests
- 투표 로직 (중복 방지, 마감 확인)
- Device Token 해시 검증
- 스코어 계산 (적중률, 스트릭)
- 카운트다운 타이머

### Integration Tests
- Server Action → Supabase → Broadcast
- 투표 → 결과 → 토론방 생성 체인

### E2E Tests
- 전체 투표 플로우 (Playwright / Flutter Integration)
- 모바일 반응형
- 8개 언어 렌더링

---

## 부록: 마케팅 카피

### 한국어
```
새로운 예측이 열렸어요.
3초 만에 투표하세요. 결과는 내일.
틀렸다면? 토론방을 열고 대화해요.

계정 없이. 익명으로. 기록은 이 기기에서만.
```

### English
```
A new question just dropped.
Cast your vote in one tap. Results tomorrow.
Wrong? Start a discussion room right now.

No signup. Anonymous. Your streak, your secret.
```

---

*이 문서는 6명의 에이전트 팀이 BLIP 코드베이스를 분석하여 작성한 통합 PRD입니다.*
