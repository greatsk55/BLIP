import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isStringArray, checkOrigin } from '@/lib/api-utils';

// IP당 분당 10회
const BATCH_STATUS_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`room:batch:${ip}`, BATCH_STATUS_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { roomIds } = body;
    if (!isStringArray(roomIds) || roomIds.length === 0 || roomIds.length > 50) {
      return Response.json(
        { error: 'INVALID_PARAMS' },
        { status: 400 }
      );
    }

    const supabase = createServerSupabase();

    const { data: rooms, error } = await supabase
      .from('rooms')
      .select('id, status, expires_at')
      .in('id', roomIds);

    if (error) {
      return Response.json({ error: 'SERVER_ERROR' }, { status: 500 });
    }

    const now = new Date();
    const statuses: Record<string, string> = {};

    for (const room of rooms ?? []) {
      if (new Date(room.expires_at) < now) {
        statuses[room.id] = 'expired';
      } else {
        statuses[room.id] = room.status;
      }
    }

    for (const id of roomIds) {
      if (!statuses[id]) {
        statuses[id] = 'not_found';
      }
    }

    return Response.json({ statuses });
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
