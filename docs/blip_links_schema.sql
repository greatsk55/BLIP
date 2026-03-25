-- BLIP me 링크 테이블
-- 개인 URL을 생성하여 SNS 등에 공유 → 클릭 시 즉시 1:1 방 생성
CREATE TABLE blip_links (
  id TEXT PRIMARY KEY,                    -- 짧은 링크 ID (8자, URL-safe)
  owner_token_hash TEXT NOT NULL,         -- SHA-256(ownerToken) — 소유권 증명
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,                 -- NULL = 무기한 (소유자가 직접 삭제)
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'disabled')),
  use_count INT NOT NULL DEFAULT 0        -- 총 사용 횟수 (통계)
);

-- 인덱스: owner_token_hash로 조회 (소유자의 링크 목록)
CREATE INDEX idx_blip_links_owner ON blip_links (owner_token_hash);

-- RLS: 모든 직접 접근 차단 (Server Actions의 service_role만 허용)
ALTER TABLE blip_links ENABLE ROW LEVEL SECURITY;

-- anon 사용자 접근 차단 (기존 rooms 테이블과 동일 패턴)
-- service_role은 RLS를 우회하므로 별도 정책 불필요

-- ────────────────────────────────────
-- v1.9.1: FCM 푸시 토큰 컬럼 추가
-- 기존 테이블이 이미 있으면 아래 ALTER만 실행
-- ────────────────────────────────────
-- ALTER TABLE blip_links ADD COLUMN fcm_token TEXT;
