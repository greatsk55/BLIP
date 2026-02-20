import { NextResponse } from 'next/server';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 5회 퇴장 요청
const LEAVE_LIMIT = { windowMs: 60_000, maxRequests: 5 };

/**
 * POST /api/room/leave
 *
 * navigator.sendBeacon()용 엔드포인트
 * 페이지 이탈(탭 닫기, 새로고침, 브라우저 종료) 시
 * sendBeacon으로 호출되어 participant_count를 감소시킴
 *
 * sendBeacon은 페이지 unload 중에도 전송이 보장됨
 * (Server Action은 fetch 기반이라 unload 시 취소됨)
 */
export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`leave:${ip}`, LEAVE_LIMIT);
    if (!rateCheck.allowed) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
    }

    const { roomId, authKeyHash } = await request.json();

    if (!roomId || typeof roomId !== 'string') {
      return NextResponse.json({ error: 'Missing roomId' }, { status: 400 });
    }

    const supabase = createServerSupabase();

    const { data: room } = await supabase
      .from('rooms')
      .select('participant_count, status, auth_key_hash')
      .eq('id', roomId)
      .single();

    if (!room || room.status === 'destroyed') {
      return NextResponse.json({ ok: true });
    }

    // authKeyHash 검증 — 방 비밀번호를 모르면 조작 불가
    if (!authKeyHash || room.auth_key_hash !== authKeyHash) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const newCount = Math.max(0, (room.participant_count ?? 1) - 1);

    await supabase
      .from('rooms')
      .update({
        participant_count: newCount,
        status: newCount === 0 ? 'destroyed' : 'active',
      })
      .eq('id', roomId);

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
