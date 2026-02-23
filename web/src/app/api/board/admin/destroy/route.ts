import { destroyBoard } from '@/lib/board/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

const ADMIN_DESTROY_LIMIT = { windowMs: 60_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ success: false, error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:admin:destroy:${ip}`, ADMIN_DESTROY_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ success: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ success: false, error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardId, adminToken } = body;
    if (!isString(boardId) || !isString(adminToken)) {
      return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await destroyBoard(boardId, adminToken);
    return Response.json(result);
  } catch {
    return Response.json({ success: false, error: 'Internal error' }, { status: 500 });
  }
}
