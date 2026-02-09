-- BLIP: rooms 테이블 + RLS 정책
-- Supabase SQL Editor에서 실행

-- 방 메타데이터만 저장 (메시지 절대 저장 안 함)
CREATE TABLE IF NOT EXISTS rooms (
  id TEXT PRIMARY KEY,
  auth_key_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'waiting' CHECK (status IN ('waiting', 'active', 'destroyed')),
  participant_count INT DEFAULT 0 CHECK (participant_count >= 0 AND participant_count <= 2)
);

-- 만료된 방 자동 정리를 위한 인덱스
CREATE INDEX IF NOT EXISTS idx_rooms_expires_at ON rooms (expires_at)
  WHERE status != 'destroyed';

-- 상태별 조회 인덱스
CREATE INDEX IF NOT EXISTS idx_rooms_status ON rooms (status)
  WHERE status = 'waiting' OR status = 'active';

-- RLS 활성화
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;

-- anon 유저: rooms 테이블 직접 조회 불가
-- 모든 DB 조작은 Server Action (service_role)을 통해서만 수행
-- 클라이언트는 Supabase Realtime (Broadcast/Presence)만 사용
-- → auth_key_hash 등 민감 데이터 노출 방지

-- anon 유저: INSERT/UPDATE/DELETE/SELECT 모두 불가
-- service_role은 RLS를 우회하므로 별도 정책 불필요

-- pg_cron: 매시간 정리
-- 1. status = 'destroyed' → 모든 참여자가 퇴장한 방 (즉시 정리)
-- 2. expires_at < NOW() → 24시간 안전망 초과한 버려진 방
CREATE EXTENSION IF NOT EXISTS pg_cron;

SELECT cron.schedule(
  'cleanup-rooms',
  '0 * * * *',
  $$
    DELETE FROM rooms
    WHERE status = 'destroyed'
       OR expires_at < NOW();
  $$
);
