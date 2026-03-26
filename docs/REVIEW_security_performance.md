# BLIP 포인트 베팅 시스템 — 통합 보안/퍼포먼스 리뷰

> **리뷰일**: 2026-03-25
> **리뷰어**: 시니어 엔지니어 6명 (Security, Performance, Architect, Crypto, Infra, QA)
> **대상**: PRD v1.0 + v2.0

---

## 전체 판정: 🟡 조건부 승인

**출시 전 Critical 5건 + High 8건 해결 필수**

---

## Critical Issues (5건) — 즉시 해결

### C1. Race Condition: Balance 동시 수정
- **발견**: Security + QA
- **문제**: 2개 탭에서 동시 베팅 → 잔액 이중 차감 또는 초과 사용
- **해결**: RPC 함수에 `SELECT ... FOR UPDATE` + `SERIALIZABLE` 트랜잭션
- **Idempotency Key 추가**: 같은 요청 2번 실행해도 1번만 처리

### C2. Device Fingerprint 리셋 → 무한 100 BP
- **발견**: Security + Anti-abuse
- **문제**: localStorage 삭제 / Incognito → 새 fingerprint → 100 BP 무한 수급
- **해결**: 서버 측 Device Registry (hardware_hash + IP로 기존 토큰 반환)
- **보완**: IP당 신규 디바이스 생성 Rate Limit (1시간 1개)

### C3. E2EE 철학과 포인트 시스템의 모순
- **발견**: Crypto
- **문제**: 기존 채팅 "서버는 모른다" vs 포인트 "서버가 모든 거래 안다"
- **해결**: 포지셔닝 변경 — "채팅은 E2EE, 베팅은 공개 예측 게임"으로 분리
- **질문 암호화 삭제**: 공개 투표인데 암호화 불필요 + 모더레이션 불가

### C4. Cron 중복 실행 → 이중 정산
- **발견**: QA + Infra
- **문제**: Vercel Cron 재시도 시 같은 질문 2번 정산 → payout 2배
- **해결**: Redis Idempotency Key (TTL 120초) 또는 pg_cron 단독 사용

### C5. 정산 후 payout > 풀 (돈이 어디서 생김?)
- **발견**: QA
- **문제**: 소수점 반올림 누적 → 분배액 합계가 풀을 초과
- **해결**: 마지막 수혜자가 나머지(remainder) 수령 + SUM 검증 assertion

---

## High Issues (8건) — 출시 전 필수

### H1. DB 인덱스 부재
- **발견**: Performance
- **문제**: 배당률 계산 SUM() 쿼리 → 인덱스 없으면 600ms
- **해결**: 4개 인덱스 즉시 생성 (prediction_bets에 compound index)

### H2. Lock Contention (동시 1000명 베팅)
- **발견**: Performance
- **문제**: FOR UPDATE 직렬화 → 응답 시간 선형 증가 → timeout
- **해결**: 배당률 캐싱 (Vercel KV, 5초 TTL) + Optimistic Locking

### H3. betAmount 입력 검증 부재
- **발견**: Security
- **문제**: -1, 0, MAX_INT 전송 → 잔액 조작 가능
- **해결**: Server Action + DB CHECK 제약 양쪽 검증

### H4. Cron Endpoint 인증 미흡
- **발견**: Security
- **문제**: 누구나 `/api/cron/predictions` 호출 → 강제 정산
- **해결**: `Authorization: Bearer ${CRON_SECRET}` 필수 검증

### H5. SSOT 위반: 잔액이 5곳에 존재
- **발견**: Architect
- **문제**: DB, localStorage, Riverpod, React state, 낙관적 값
- **해결**: DB가 유일한 진실, 클라이언트는 캐시일 뿐, Realtime 동기화

### H6. 베팅 후 네트워크 끊김 → 포인트 손실
- **발견**: QA
- **문제**: 서버는 차감 성공, 클라이언트는 응답 못 받음
- **해결**: Idempotency Key + localStorage 폴백 + 온라인 복귀 시 재시도

### H7. 질문 생성자가 결과 안 알려주면 영구 pending
- **발견**: QA
- **문제**: 생성자가 결과 확정 안 하면 베팅자들 정산 불가
- **해결**: 타임아웃 (reveals_at + 24h) → 커뮤니티 다수결 또는 전액 환불

### H8. Supabase Free 플랜 한계
- **발견**: Infra
- **문제**: 300MB 스토리지 + 200 Realtime 연결 → 3주 내 초과
- **해결**: Supabase Pro 전환 필수 ($35-40/월)

---

## Medium Issues (10건) — Phase 2 해결

| # | 발견 | 문제 | 해결책 |
|---|------|------|--------|
| M1 | Crypto | 베팅 메타데이터로 사용자 추적 가능 | 시간 난독화 + K-익명성 |
| M2 | Crypto | 리더보드 = 익명성 파괴 | "상위 10%" 표시로 변경 |
| M3 | Crypto | 서버가 배당률 조작 가능 | Provably Fair 시스템 |
| M4 | Security | 투표 기록 30일 보관 = GDPR 위반 가능 | 정산 직후 즉시 삭제 또는 익명화 |
| M5 | Security | Rake 분배 반올림 오차 | remainder를 마지막 수혜자에게 |
| M6 | Performance | Realtime 채널 1M DAU 시 한계 | polling 전환 또는 자체 서버 |
| M7 | Performance | 프론트 100개 카드 렌더링 10fps | Virtual Scroll + React.memo |
| M8 | Architect | placeBet에 8개 책임 혼재 | validation/execution/broadcast 분리 |
| M9 | Architect | 웹-모바일 배당률 계산 이중 구현 | 공유 상수 + 서버 계산 신뢰 |
| M10 | Infra | 모니터링 체계 부재 | Sentry + 일일 무결성 검사 Cron |

---

## 법적 리스크

### 도박법
- **판정**: 3요소 중 2개(금전적 가치, 대가 수수) 해당 없음 → **대체로 안전**
- **단, 한국**: 법원 판례 분분 → **법무팀 자문 필수**
- **필수 조치**: ToS에 "BP는 금전 가치 없음, 교환/구매/이체 불가" 명시

### GDPR
- **device_fingerprint = 개인정보 가능성** → 정산 후 즉시 삭제 또는 익명화

---

## 비용 예상

| DAU | Supabase | Vercel | Upstash | 합계 |
|-----|----------|--------|---------|------|
| 10K | $35 | $0-20 | $24 | **~$60/월** |
| 100K | $135 | $50-100 | $80 | **~$365/월** |
| 1M | $1,347 | $500+ | $800 | **~$3,150/월** |

---

## 출시 전 체크리스트

### Week 1: Critical 해결
- [ ] C1: RPC 함수 `SELECT ... FOR UPDATE` + Idempotency Key
- [ ] C2: Server-side Device Registry 구현
- [ ] C3: 질문 암호화 삭제, "공개 베팅" 포지셔닝
- [ ] C4: Cron Idempotency (Redis 또는 pg_cron 단독)
- [ ] C5: Payout 합계 검증 assertion

### Week 2: High 해결
- [ ] H1: DB 인덱스 4개 생성
- [ ] H2: 배당률 캐싱 (Vercel KV)
- [ ] H3: betAmount 서버 검증
- [ ] H4: Cron Authorization 헤더
- [ ] H5: SSOT 전략 문서화 (DB = 진실)
- [ ] H6: Idempotency + 네트워크 복구
- [ ] H7: 질문 타임아웃 자동 환불
- [ ] H8: Supabase Pro 전환

### Week 3: 부하 테스트 + 배포
- [ ] k6로 1000명 동시 베팅 테스트
- [ ] Feature Flag로 1% 카나리 배포
- [ ] 모니터링 대시보드 + Slack 알림
- [ ] 일일 무결성 검사 Cron

---

*이 리포트는 6명의 시니어 엔지니어가 BLIP 코드베이스를 분석하여 작성한 보안/퍼포먼스 리뷰입니다.*
