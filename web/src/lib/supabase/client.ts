import { createClient } from '@supabase/supabase-js';

/**
 * Supabase 브라우저 클라이언트 (싱글톤)
 *
 * 용도:
 * - Realtime Broadcast (메시지 송수신, DB 저장 안 함)
 * - Realtime Presence (접속자 추적)
 *
 * 절대 사용하지 않을 것:
 * - Postgres Changes (DB 변경 감지)
 * - Broadcast from Database (realtime.messages 테이블에 저장됨)
 * - Broadcast Replay (저장된 메시지 재생)
 */
function createBrowserSupabase() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error(
      'Missing Supabase environment variables. Check NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_ANON_KEY in .env.local'
    );
  }

  return createClient(supabaseUrl, supabaseAnonKey, {
    realtime: {
      params: {
        eventsPerSecond: 10,
      },
    },
  });
}

export const supabase = createBrowserSupabase();
