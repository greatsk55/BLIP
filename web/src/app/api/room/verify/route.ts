import { verifyPassword } from '@/lib/room/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// API 레벨 rate limit (SA 레벨과 이중 방어)
const VERIFY_API_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ valid: false, error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:verify:${ip}`, VERIFY_API_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ valid: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ valid: false, error: 'INVALID_JSON' }, { status: 400 });
    }

    const { roomId, password } = body;
    if (!isString(roomId) || !isString(password)) {
      return Response.json({ valid: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await verifyPassword(roomId, password);
    return Response.json(result);
  } catch {
    return Response.json({ valid: false, error: 'Internal error' }, { status: 500 });
  }
}
