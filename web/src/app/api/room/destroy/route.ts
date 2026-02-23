import { destroyRoom } from '@/lib/room/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';

// IP당 분당 5회
const DESTROY_LIMIT = { windowMs: 60_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`destroy:${ip}`, DESTROY_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { roomId, authKeyHash } = body;
    if (!isString(roomId) || !isString(authKeyHash)) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    await destroyRoom(roomId, authKeyHash);
    return Response.json({ ok: true });
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
