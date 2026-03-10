import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isStringArray, checkOrigin } from '@/lib/api-utils';

// IP당 분당 10회
const BATCH_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:batch:${ip}`, BATCH_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardIds } = body;

    if (!isStringArray(boardIds) || boardIds.length === 0 || boardIds.length > 50) {
      return Response.json(
        { error: 'INVALID_PARAMS' },
        { status: 400 }
      );
    }

    const supabase = createServerSupabase();

    const { data: boards, error } = await supabase
      .from('boards')
      .select('id, status')
      .in('id', boardIds);

    if (error) {
      return Response.json({ error: 'SERVER_ERROR' }, { status: 500 });
    }

    const statuses: Record<string, string> = {};

    for (const board of boards ?? []) {
      statuses[board.id] = board.status;
    }

    for (const id of boardIds) {
      if (!statuses[id]) {
        statuses[id] = 'not_found';
      }
    }

    return Response.json({ statuses });
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
