import { getRoomStatus } from '@/lib/room/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';

// IP당 분당 30회
const STATUS_LIMIT = { windowMs: 60_000, maxRequests: 30 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ exists: false, error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`room:status:${ip}`, STATUS_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ exists: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ exists: false, error: 'INVALID_JSON' }, { status: 400 });
    }

    const { roomId } = body;
    if (!isString(roomId)) {
      return Response.json({ exists: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await getRoomStatus(roomId);
    return Response.json(result);
  } catch {
    return Response.json({ exists: false, error: 'Internal error' }, { status: 500 });
  }
}
