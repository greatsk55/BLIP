-- 그룹채팅 지원을 위한 rooms 테이블 컬럼 추가
-- 기존 1:1 채팅에는 영향 없음 (모든 새 컬럼에 기본값 설정)

ALTER TABLE rooms ADD COLUMN IF NOT EXISTS type text NOT NULL DEFAULT 'direct';
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS max_participants integer DEFAULT 2;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS title text;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS admin_token_hash text;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS is_locked boolean NOT NULL DEFAULT false;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS banned_tokens text[] DEFAULT '{}';

-- type 컬럼 제약 조건
ALTER TABLE rooms ADD CONSTRAINT rooms_type_check CHECK (type IN ('direct', 'group'));

-- 인덱스 (그룹방 조회 최적화)
CREATE INDEX IF NOT EXISTS idx_rooms_type ON rooms (type) WHERE type = 'group';
