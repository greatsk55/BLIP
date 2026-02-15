-- BLIP: 게시판 이미지 첨부 테이블
-- 선행: 002_boards.sql

CREATE TABLE IF NOT EXISTS board_post_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES board_posts(id) ON DELETE CASCADE,
  board_id TEXT NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  encrypted_nonce TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes INT NOT NULL,
  width INT,
  height INT,
  display_order SMALLINT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_board_post_images_post_id
  ON board_post_images (post_id, display_order);

-- RLS: anon 전부 차단, service_role만 접근
ALTER TABLE board_post_images ENABLE ROW LEVEL SECURITY;

-- 게시글당 최대 4장 이미지 제한 (DB 트리거)
CREATE OR REPLACE FUNCTION check_max_images_per_post()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) FROM board_post_images WHERE post_id = NEW.post_id) >= 4 THEN
    RAISE EXCEPTION 'Maximum 4 images per post';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER enforce_max_images
  BEFORE INSERT ON board_post_images
  FOR EACH ROW EXECUTE FUNCTION check_max_images_per_post();

-- Supabase Storage 버킷 (private, 암호화된 바이너리만)
-- 수동 실행 또는 Supabase 대시보드에서:
-- INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- VALUES ('board-images', 'board-images', false, 10485760, ARRAY['application/octet-stream']);
