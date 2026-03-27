# BLIP 포인트 베팅 시스템 — PRD v2.0 (Addendum)

> **작성일**: 2026-03-25
> **기반 문서**: [PRD v1.0 — 익명 예측 투표](PRD_anonymous_prediction_voting.md)
> **팀**: Game Economy / Backend / UX / Anti-abuse / Frontend / Mobile+Growth

---

## 1. 변경 요약

v1.0 PRD에서 단순 투표였던 시스템을 **포인트 베팅 + 유저 질문 생성**으로 확장합니다.

| 항목 | v1.0 (기존) | v2.0 (변경) |
|------|-----------|-----------|
| 투표 방식 | 무료 원탭 | **BP(BLIP Points) 베팅** |
| 질문 생성 | 어드민 전용 | **유저도 생성 가능 (150 BP)** |
| 보상 | 로컬 스코어 | **BP 배당 정산** |
| 수익 모델 | 광고만 | 광고 + **Rake 수수료** |
| 리텐션 | 결과 확인 | **정산 도파민 + 손실 회피** |
| 커뮤니티 | 등급 없음 | **BP 기반 등급/뱃지** |

---

## 2. 포인트 경제 설계

### 2.1 기본 규칙

| 파라미터 | 값 | 근거 |
|----------|-----|------|
| 초기 지급 | **100 BP** | 약 10-15회 베팅 가능 |
| 자동 충전 | **1 BP / 2일** | 바닥나도 계속 플레이 |
| 충전 조건 | 최근 7일 내 1회 이상 베팅 | 팜 방지 |
| 질문 생성 비용 | **150 BP** | 스팸 방지 + 투자 개념 |
| 최소 베팅 | 1 BP | 진입 장벽 제로 |
| 최대 베팅 | min(보유의 50%, 500 BP) | 올인/양극화 방지 |
| BP 이체 | **불가** | 팜 실익 제거 |

### 2.2 배당률 (Parimutuel 방식)

```
배당률(선택지 X) = 총 베팅풀 × (1 - Rake) / 선택지 X에 걸린 BP

Rake = 10%
최소 배당: 1.05x
최대 배당: 20.0x
```

**예시**: 총 풀 1000 BP, YES 800 / NO 200
| 선택 | 배당률 | 10 BP 걸면 |
|------|--------|-----------|
| YES (다수) | 900/800 = **1.125x** | → 11.25 BP (+1.25) |
| NO (소수) | 900/200 = **4.5x** | → 45 BP (+35) |

**핵심**: 남들과 다른 예측에 높은 보상 → 소수 의견 유도

### 2.3 Rake 분배

```
Rake 10% 분배:
├── 50% → 질문 생성자 보상
├── 30% → 시스템 소각 (디플레이션)
└── 20% → 주간 예측왕 보상 풀
```

### 2.4 질문 생성자 보상

```
생성자 수익 = max(Rake의 50%, 최소 보장 30 BP*)
*최소 보장은 참여자 10명 이상일 때만

예시:
- 총 풀 1000 BP → Rake 100 → 생성자 50 BP (순손실 -100)
- 총 풀 3000 BP → Rake 300 → 생성자 150 BP (손익분기)
- 총 풀 5000 BP → Rake 500 → 생성자 250 BP (순이익 +100)
```

**자기 질문에 베팅 불가** (어뷰징 방지)

### 2.5 등급 시스템

| 등급 | BP 범위 | 뱃지 | 특전 |
|------|---------|------|------|
| 💀 잡음 (Static) | 0-4 | 회색 | 무료 투표 1일 1회 |
| 🌱 수신 (Receiver) | 5-49 | 초록 | 일반 베팅 |
| ⚡ 교신 (Signal) | 50-199 | 파랑 | 투표 댓글 가능 |
| 🔥 해독 (Decoder) | 200-999 | 주황 | 질문 생성 가능 |
| 💎 관제 (Control) | 1000-4999 | 보라 | 질문 생성 20% 할인 |
| 👑 오라클 (Oracle) | 5000+ | 금색 | 질문 생성 50% 할인, 전용 이펙트 |

커뮤니티 게시판에서 닉네임 옆에 등급 뱃지 표시.

### 2.6 경제 밸런스 (시뮬레이션 결과)

**100명 유저, 30일 Monte Carlo**:
```
Day 0:  중앙값 100 BP | 총 10,000 BP
Day 15: 중앙값 65 BP  | Rake 소각 누적
Day 30: 중앙값 40-60 BP

분포 (Day 30):
- 💀 0-4:   ~21%
- 🌱 5-49:  ~46%
- ⚡ 50-199: ~25%
- 🔥 200+:  ~8%
- 💎 1000+: ~2%
```

**밸런스 조정 룰**:
- 중앙값 < 40 → 자동 충전량 상향
- 중앙값 > 200 → Rake 소각률 상향
- 5000+ BP 보유 → 일일 0.5% 부유세

---

## 3. 데이터베이스 설계

### 3.1 핵심 테이블

```sql
-- 디바이스별 포인트
CREATE TABLE device_points (
  device_fingerprint TEXT PRIMARY KEY,
  balance INT NOT NULL DEFAULT 100 CHECK (balance >= 0),
  total_earned INT NOT NULL DEFAULT 0,
  total_spent INT NOT NULL DEFAULT 0,
  total_won INT NOT NULL DEFAULT 0,
  total_lost INT NOT NULL DEFAULT 0,
  last_daily_reward_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 베팅 기록
CREATE TABLE prediction_bets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID NOT NULL REFERENCES predictions(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  option_id TEXT NOT NULL,
  bet_amount INT NOT NULL CHECK (bet_amount >= 1),
  odds_at_bet DECIMAL(8,4) NOT NULL,
  status TEXT DEFAULT 'pending'
    CHECK (status IN ('pending', 'won', 'lost', 'refunded')),
  payout INT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

-- 질문 생성 기록 (생성자 보상 추적)
CREATE TABLE prediction_creations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID NOT NULL REFERENCES predictions(id),
  creator_fingerprint TEXT NOT NULL,
  creation_cost INT NOT NULL DEFAULT 150,
  total_earned INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.2 PostgreSQL RPC (원자적 트랜잭션)

```sql
-- 배당률 계산 + 베팅 생성 (원자적)
CREATE FUNCTION calculate_odds_and_place_bet(
  p_prediction_id UUID,
  p_device_fingerprint TEXT,
  p_option_id TEXT,
  p_bet_amount INT
) RETURNS TABLE(success BOOLEAN, odds DECIMAL, new_balance INT)
AS $$ ... $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 결과 공개 + 자동 정산 (원자적)
CREATE FUNCTION settle_prediction(
  p_prediction_id UUID,
  p_result_option_id TEXT
) RETURNS TABLE(success BOOLEAN, total_paid INT, creator_earned INT)
AS $$ ... $$ LANGUAGE plpgsql SECURITY DEFINER;

-- 이틀마다 1 BP 보상
CREATE FUNCTION claim_daily_reward(
  p_device_fingerprint TEXT
) RETURNS TABLE(success BOOLEAN, new_balance INT)
AS $$ ... $$ LANGUAGE plpgsql SECURITY DEFINER;
```

**핵심**: 모든 금전 거래는 `SELECT ... FOR UPDATE` + 단일 트랜잭션으로 race condition 방지.

---

## 4. 어뷰징 방지

### 4.1 시나리오별 대응

| 시나리오 | 위험도 | 대응 |
|----------|--------|------|
| **셀프 베팅** (자기 질문에 확정 답 베팅) | 높음 | 생성자 자기 질문 베팅 **금지** |
| **다중 디바이스 팜** | 중간 | BP 이체 불가 + 강화 fingerprint |
| **담합** (여러 명 한쪽 몰빵) | 중간 | 네트워크 그래프 분석, 마감 직전 급변 경고 |
| **포인트 팜** (충전만 수집) | 낮음 | 7일 미베팅 시 충전 정지 |
| **질문 어뷰징** (검증 불가 질문) | 중간 | AI 모더레이션 + 신고 시스템 |
| **배당률 조작** (마감 직전 대량 베팅) | 중간 | 시계열 분석, 한쪽 75%+ 집중 시 플래깅 |
| **디바이스 리셋** (100 BP 무한 수급) | 높음 | 강화 fingerprint (WebGL + Canvas + Hardware) |

### 4.2 강화 Fingerprint

```typescript
// 기존: SHA-256(IP + UA)
// 신규: SHA-256(IP + UA + WebGL GPU + Canvas hash + hardware + localStorage ID)

// Tier 1 (변조 어려움): CPU 코어, RAM, 터치포인트, 화면
// Tier 2 (변조 가능하지만 비용 높음): WebGL GPU, Canvas, 언어, 시간대
// Tier 3 (변조 가능): IP, User-Agent
```

### 4.3 Progressive Trust

```
신규 → 100 BP 즉시 + 완화된 제한
의심 신호 → Rate limit 강화 + 모니터링
높은 위험 → 베팅 제한 + 수동 검토
확정 어뷰저 → 포인트 동결, 동일 device_hash 재가입 차단
```

---

## 5. 법적 고려사항

### 5.1 도박법 분석

```
도박 3요소 중 BLIP BP:
1. 금전적 가치 → ❌ 현금 교환 불가, 구매 불가
2. 우연의 결과 → ⚠️ 해당 가능
3. 대가의 수수 → ❌ 무료 지급, 현금 가치 없음

→ 3요소 중 2개 해당 없음 = 대부분 법역에서 도박 아님
```

### 5.2 이용약관 필수 문구

```
1. "BP는 가상 포인트이며 금전적 가치가 없습니다"
2. "현금, 상품권, 기타 유가물로 교환 불가"
3. "BP는 구매할 수 없습니다"
4. "양도, 판매, 이체 불가"
5. "서비스 종료 시 BP는 소멸, 보상 없음"
```

### 5.3 절대 금지

```
❌ BP → 현금 교환
❌ BP 인앱결제 구매
❌ BP로 실물/디지털 상품 교환
❌ BP 이체/선물
❌ 외부 거래소 연동
```

---

## 6. UX/UI 핵심 화면

### 6.1 베팅 카드

```
┌──────────────────────────────┐
│ 비트코인 7만 달러 돌파?       │
│ [2시간 44분]                  │
│                               │
│ ┌────────────┬────────────┐  │
│ │ YES 1.25x  │ NO  5.00x  │  │
│ │ 420명      │ 85명       │  │
│ └────────────┴────────────┘  │
│                               │
│ [=======●=======] 50 BP      │
│ 예상 수익: +62.5 BP          │
│                               │
│ [PREDICT & BET]               │
└──────────────────────────────┘
```

### 6.2 정산 화면

```
┌─────────────────┐  ┌─────────────────┐
│   ✓ 맞았다!     │  │   ✕ 틀렸다...   │
│                 │  │                 │
│   +125 BP       │  │   -100 BP       │
│   (signal-green) │  │   (glitch-red)  │
│                 │  │                 │
│ 배당: 1.25x     │  │ 선택: NO        │
│ 베팅: 100 BP    │  │ 베팅: 100 BP    │
│                 │  │                 │
│ [확인] [공유]   │  │ [확인] [재도전] │
└─────────────────┘  └─────────────────┘
```

### 6.3 질문 생성 폼

```
┌──────────────────────────────┐
│ 질문 만들기 (150 BP)          │
│                               │
│ [질문 입력]                   │
│ 최대 200자                    │
│                               │
│ 카테고리: [암호화폐] [스포츠]  │
│ 마감: [1h] [6h] [24h]        │
│                               │
│ 💡 명확한 질문 = 더 많은 참여  │
│                               │
│ [CREATE QUESTION (150 BP)]    │
└──────────────────────────────┘
```

### 6.4 포인트 헤더

```
웹: [BLIP]  💰 1,250 BP  [73% 적중]  [7위]
앱: [←]                    💰 1,250 BP 📊
```

---

## 7. 웹 구현 (Next.js)

### 7.1 새 파일 구조

```
web/src/
├── types/points.ts           # DevicePoints, PredictionBet, BetOdds
├── hooks/
│   ├── usePoints.ts          # 잔액 + 등급 + 실시간 동기화
│   ├── useBetting.ts         # 베팅 + 배당률 + 정산
│   └── useOdds.ts            # Supabase Broadcast 배당률
├── lib/points/
│   ├── storage.ts            # device_token 관리
│   ├── actions.ts            # Server Actions (placeBet, settle)
│   └── utils.ts              # 등급 계산, 배당률 계산
├── components/points/
│   ├── PointsDisplay.tsx     # 헤더 잔액
│   ├── BettingSlider.tsx     # 베팅 금액 슬라이더
│   ├── OddsDisplay.tsx       # 실시간 배당률
│   ├── SettlementModal.tsx   # 정산 결과 팝업
│   ├── CreatePredictionForm.tsx
│   ├── RankBadge.tsx         # 등급 뱃지
│   └── Leaderboard.tsx
```

### 7.2 애니메이션 (Framer Motion)

- **포인트 변동**: 숫자 카운트업/다운 + signal-green/glitch-red 번쩍임
- **배당률 변동**: scale 1.2→1 + opacity 0→1 (0.3s)
- **정산 모달**: 배경 fade + 콘텐츠 spring scale
- **슬라이더**: "예상 수익" 박스 pulse (0.15s)

---

## 8. 모바일 구현 (Flutter)

### 8.1 새 파일 구조

```
mobile/lib/features/
├── points/
│   ├── domain/models/device_points.dart
│   ├── providers/points_provider.dart    # Riverpod StateNotifier
│   └── presentation/widgets/points_chip.dart
├── betting/
│   ├── domain/models/prediction_bet.dart
│   ├── providers/
│   │   ├── betting_provider.dart
│   │   └── odds_provider.dart
│   └── presentation/widgets/
│       ├── betting_bottom_sheet.dart
│       └── settlement_overlay.dart
├── prediction/
│   └── presentation/create_prediction_screen.dart
```

### 8.2 기존 코드 재활용

| 기존 | 신규 적용 |
|------|----------|
| ChatNotifier (StateNotifier) | PointsNotifier, BettingNotifier |
| LocalStorageService (SharedPrefs) | Points/Bets 저장 추가 |
| Supabase Broadcast | 배당률 실시간 구독 |
| FCM PushService | 정산/보너스 알림 추가 |
| AppColors.signalGreen | 포인트/승리 색상 |
| AppColors.glitchRed | 손실 색상 |

---

## 9. Growth 전략 업데이트

### 9.1 신규 리텐션 루프

```
기존: 질문 → 투표 → 결과 (수동적)
신규: 질문 → BP 베팅(능동) → 결과 → 정산(도파민!) → 재베팅
                                        ↑
                              손실 회피 심리 = 결과 꼭 확인
```

### 9.2 예상 전환율 (포인트 베팅 추가 후)

| 지표 | 기존 (투표만) | 신규 (BP 베팅) | 증감 |
|------|-------------|--------------|------|
| D1 | 70% | **80%+** | +15% |
| D7 | 25-35% | **40-48%** | +60% |
| D30 | 10-15% | **20-22%** | +80% |
| 세션 시간 | 3-5분 | **5-8분** | +80% |

### 9.3 푸시 알림 전략

```
"마감 1시간! 배당률 5.0x 기회 ⚡"     → 긴급성 + 이익
"정산 완료! +250 BP 획득 🎉"          → 도파민
"이틀 보상 1 BP 수령하세요 🎁"        → 일일 활성
"내 질문에 1000명 베팅! 공유하기"      → 바이럴
```

### 9.4 랜딩 페이지 개선

- Hero에 **듀얼 탭**: [채팅] | [예측 베팅]
- "무료 100 BP로 시작" CTA
- 실시간 배당판 위젯 (핫 예측 Top 3)

---

## 10. 모니터링 KPI

### 10.1 경제 지표 (일일 추적)

| 지표 | 목표 |
|------|------|
| 시스템 총 BP량 | 안정 유지 (±20%) |
| 유저 중앙값 BP | **60-80 BP** |
| 지니 계수 | < 0.4 (양극화 방지) |
| 일일 베팅 참여율 | > 30% |
| 질문당 평균 풀 | > 500 BP |

### 10.2 Growth 지표

| 지표 | 목표 |
|------|------|
| DAU | +40% (투표 페이지) |
| D7 재방문 | 40%+ |
| 투표→토론방 전환 | 15% |
| 질문 생성 수 | 300+/일 |

---

## 11. 구현 로드맵

### Phase 1: MVP (3주)

| 주차 | 작업 |
|------|------|
| Week 1 | DB 스키마 + RPC 함수 + device_points 초기화 |
| Week 2 | 웹: 베팅 카드 + 슬라이더 + 배당률 실시간 |
| Week 3 | 앱: Riverpod Provider + 베팅 시트 + 정산 오버레이 |

### Phase 2: 질문 생성 + 등급 (2주)

| 작업 |
|------|
| CreatePredictionForm (웹+앱) |
| 생성자 보상 정산 로직 |
| 등급 뱃지 (커뮤니티 게시판 연동) |
| 리더보드 |

### Phase 3: Growth + Anti-abuse (2주)

| 작업 |
|------|
| 랜딩 페이지 듀얼 탭 + 배당판 |
| 푸시 알림 (정산/보너스) |
| 강화 Fingerprint |
| Progressive Trust 시스템 |
| i18n 8개 언어 |

---

*이 문서는 6명의 에이전트 팀 (Game Economy / Backend / UX / Anti-abuse / Frontend / Mobile+Growth)이 BLIP 코드베이스를 분석하여 작성한 포인트 베팅 시스템 PRD입니다.*
