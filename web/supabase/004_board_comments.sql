-- ============================================================
-- BLIP: 암호화 커뮤니티 게시판 댓글 + 댓글 이미지 + 댓글 신고
-- 선행: 002_boards.sql, 003_board_images.sql
-- ============================================================

-- ─── 댓글 테이블 ───

CREATE TABLE IF NOT EXISTS board_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES board_posts(id) ON DELETE CASCADE,
  board_id TEXT NOT NULL REFERENCES boards(id) ON DELETE CASCADE,

  -- E2EE: 작성자명 + 본문 (대칭 암호화)
  author_name_encrypted TEXT NOT NULL,
  author_name_nonce TEXT NOT NULL,
  content_encrypted TEXT NOT NULL,
  content_nonce TEXT NOT NULL,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_blinded BOOLEAN DEFAULT FALSE,
  report_count INT DEFAULT 0 CHECK (report_count >= 0)
);

-- 게시글별 댓글 조회 (오래된 순)
CREATE INDEX IF NOT EXISTS idx_board_comments_post_created
  ON board_comments (post_id, created_at ASC);

-- 게시판 삭제 시 CASCADE 최적화
CREATE INDEX IF NOT EXISTS idx_board_comments_board_id
  ON board_comments (board_id);

-- RLS: anon 전부 차단, service_role만 접근
ALTER TABLE board_comments ENABLE ROW LEVEL SECURITY;


-- ─── 게시글 댓글 수 자동 관리 ───

ALTER TABLE board_posts ADD COLUMN IF NOT EXISTS comment_count INT DEFAULT 0;

-- 댓글 INSERT → comment_count + 1
CREATE OR REPLACE FUNCTION increment_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE board_posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_increment_comment_count
  AFTER INSERT ON board_comments
  FOR EACH ROW EXECUTE FUNCTION increment_comment_count();

-- 댓글 DELETE → comment_count - 1
CREATE OR REPLACE FUNCTION decrement_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE board_posts SET comment_count = GREATEST(0, comment_count - 1) WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_decrement_comment_count
  AFTER DELETE ON board_comments
  FOR EACH ROW EXECUTE FUNCTION decrement_comment_count();


-- ─── 댓글 신고 테이블 (board_reports와 분리 — 각 테이블 책임 명확) ───

CREATE TABLE IF NOT EXISTS board_comment_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES board_comments(id) ON DELETE CASCADE,
  reporter_fingerprint TEXT NOT NULL,
  reason TEXT NOT NULL CHECK (reason IN ('spam', 'abuse', 'illegal', 'other')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(comment_id, reporter_fingerprint)   -- 중복 신고 방지
);

CREATE INDEX IF NOT EXISTS idx_board_comment_reports_comment
  ON board_comment_reports (comment_id);

ALTER TABLE board_comment_reports ENABLE ROW LEVEL SECURITY;


-- ─── 댓글 신고 카운트 증가 + 자동 블라인드 ───

CREATE OR REPLACE FUNCTION increment_comment_report_count(
  p_comment_id UUID,
  p_threshold INT DEFAULT 3
) RETURNS VOID AS $$
BEGIN
  UPDATE board_comments
  SET
    report_count = report_count + 1,
    is_blinded = CASE
      WHEN report_count + 1 >= p_threshold THEN TRUE
      ELSE is_blinded
    END
  WHERE id = p_comment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ─── board_post_images 확장 (댓글 이미지 지원) ───

-- comment_id 컬럼 추가 (기존 post_id와 OR 관계)
ALTER TABLE board_post_images
  ADD COLUMN IF NOT EXISTS comment_id UUID REFERENCES board_comments(id) ON DELETE CASCADE;

-- post_id를 nullable로 (댓글 이미지는 post_id 없음)
ALTER TABLE board_post_images ALTER COLUMN post_id DROP NOT NULL;

-- 최소 하나는 있어야 함
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'chk_image_owner'
  ) THEN
    ALTER TABLE board_post_images
      ADD CONSTRAINT chk_image_owner CHECK (post_id IS NOT NULL OR comment_id IS NOT NULL);
  END IF;
END $$;

-- 댓글 이미지 조회 최적화
CREATE INDEX IF NOT EXISTS idx_board_post_images_comment
  ON board_post_images (comment_id, display_order) WHERE comment_id IS NOT NULL;
