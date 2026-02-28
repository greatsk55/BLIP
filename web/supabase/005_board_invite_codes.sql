-- BLIP: 게시판 초대 코드 시스템
-- 선행: 002_boards.sql
-- 초대 코드와 암호화 키를 분리하여 관리자가 링크를 무효화할 수 있게 함

-- ─── boards 테이블 확장 ───
-- 모든 컬럼 NULL 허용 → 기존 보드는 레거시 모드 (password-only) 유지

ALTER TABLE boards
  ADD COLUMN IF NOT EXISTS invite_code_hash TEXT,
  ADD COLUMN IF NOT EXISTS wrapped_encryption_key TEXT,
  ADD COLUMN IF NOT EXISTS wrapped_key_nonce TEXT,
  ADD COLUMN IF NOT EXISTS invite_version INT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS encryption_key_auth_hash TEXT;

-- invite_code_hash = NULL → 레거시 모드 (password만으로 참여)
-- invite_code_hash != NULL → 초대 코드 모드 (링크로 원클릭 참여)
