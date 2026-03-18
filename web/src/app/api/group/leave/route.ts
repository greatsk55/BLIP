import { NextResponse } from 'next/server';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isString } from '@/lib/api-utils';

const LEAVE_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`leave-group:${ip}`, LEAVE_LIMIT);
    if (!rateCheck.allowed) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return NextResponse.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { roomId, authKeyHash } = body;
    if (!isString(roomId)) {
      return NextResponse.json({ error: 'Missing roomId' }, { status: 400 });
    }

    const supabase = createServerSupabase();

    const { data: room } = await supabase
      .from('rooms')
      .select('participant_count, status, auth_key_hash, type')
      .eq('id', roomId)
      .single();

    if (!room || room.status === 'destroyed' || room.type !== 'group') {
      return NextResponse.json({ ok: true });
    }

    if (!isString(authKeyHash) || room.auth_key_hash !== authKeyHash) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const newCount = Math.max(0, (room.participant_count ?? 1) - 1);

    await supabase
      .from('rooms')
      .update({
        participant_count: newCount,
        status: newCount === 0 ? 'waiting' : 'active',
      })
      .eq('id', roomId)
      .neq('status', 'destroyed');

    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
