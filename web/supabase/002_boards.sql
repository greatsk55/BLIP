-- BLIP: 암호화 커뮤니티 게시판 테이블
-- Supabase SQL Editor에서 실행
-- 선행: 001_rooms.sql

-- ─── 게시판 메타데이터 ───

CREATE TABLE IF NOT EXISTS boards (
  id TEXT PRIMARY KEY,
  auth_key_hash TEXT NOT NULL,
  admin_token_hash TEXT NOT NULL,
  encrypted_name TEXT NOT NULL,
  encrypted_name_nonce TEXT NOT NULL,
  max_participants INT DEFAULT 100,
  report_threshold INT DEFAULT 3,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'archived', 'destroyed'))
);

-- ─── 암호화된 게시글 ───

CREATE TABLE IF NOT EXISTS board_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id TEXT NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  author_name_encrypted TEXT NOT NULL,
  author_name_nonce TEXT NOT NULL,
  title_encrypted TEXT,
  title_nonce TEXT,
  content_encrypted TEXT NOT NULL,
  content_nonce TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_blinded BOOLEAN DEFAULT FALSE,
  report_count INT DEFAULT 0 CHECK (report_count >= 0)
);

CREATE INDEX IF NOT EXISTS idx_board_posts_board_created
  ON board_posts (board_id, created_at DESC);

-- ─── 신고 추적 (중복 방지) ───

CREATE TABLE IF NOT EXISTS board_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES board_posts(id) ON DELETE CASCADE,
  reporter_fingerprint TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'abuse', 'illegal', 'other')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, reporter_fingerprint)
);

CREATE INDEX IF NOT EXISTS idx_board_reports_post_id
  ON board_reports (post_id);

-- ─── RLS: anon 전부 차단 (rooms 패턴 동일) ───

ALTER TABLE boards ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE board_reports ENABLE ROW LEVEL SECURITY;

-- service_role은 RLS 우회하므로 별도 정책 불필요

-- ─── RPC: 신고 카운트 증가 + 자동 블라인드 ───

CREATE OR REPLACE FUNCTION increment_report_count(
  p_post_id UUID,
  p_threshold INT DEFAULT 3
) RETURNS VOID AS $$
BEGIN
  UPDATE board_posts
  SET
    report_count = report_count + 1,
    is_blinded = CASE
      WHEN report_count + 1 >= p_threshold THEN TRUE
      ELSE is_blinded
    END
  WHERE id = p_post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ─── pg_cron: 파쇄된 게시판 정리 ───

SELECT cron.schedule(
  'cleanup-boards',
  '0 * * * *',
  $$
    DELETE FROM boards WHERE status = 'destroyed';
  $$
);
