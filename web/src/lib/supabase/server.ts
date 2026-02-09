import { createClient } from '@supabase/supabase-js';

/**
 * Supabase 서버 클라이언트 (service_role)
 *
 * 서버 전용: Server Actions, API Routes에서만 사용
 * RLS를 우회하므로 절대 클라이언트에 노출하지 않을 것
 */
export function createServerSupabase() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !supabaseServiceKey) {
    throw new Error(
      'Missing Supabase environment variables. Check NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in .env.local'
    );
  }

  return createClient(supabaseUrl, supabaseServiceKey, {
    auth: { persistSession: false },
  });
}
