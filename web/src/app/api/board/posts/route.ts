import { getPosts } from '@/lib/board/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isString, checkOrigin, clampLimit } from '@/lib/api-utils';

// IP당 분당 30회
const POSTS_LIMIT = { windowMs: 60_000, maxRequests: 30 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:posts:${ip}`, POSTS_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardId, authKeyHash, cursor, limit } = body;
    if (!isString(boardId) || !isString(authKeyHash)) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    // 페이지네이션 limit 상한 적용 (최대 50)
    const safeLimit = clampLimit(limit);
    const safeCursor = typeof cursor === 'string' ? cursor : undefined;
    const result = await getPosts(boardId, authKeyHash, safeCursor, safeLimit);
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
