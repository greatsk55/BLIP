import { createBoard } from '@/lib/board/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// API 레벨 rate limit
const CREATE_API_LIMIT = { windowMs: 3_600_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:board:create:${ip}`, CREATE_API_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { encryptedName, encryptedNameNonce } = body;
    if (!isString(encryptedName) || !isString(encryptedNameNonce)) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await createBoard(encryptedName, encryptedNameNonce);
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
