import { deleteOwnComment } from '@/lib/board/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

const COMMENT_DELETE_LIMIT = { windowMs: 60_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ success: false, error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:comment:delete:${ip}`, COMMENT_DELETE_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ success: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ success: false, error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardId, commentId, authKeyHash } = body;
    if (!isString(boardId) || !isString(commentId) || !isString(authKeyHash)) {
      return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await deleteOwnComment(boardId, commentId, authKeyHash);
    return Response.json(result);
  } catch {
    return Response.json({ success: false, error: 'Internal error' }, { status: 500 });
  }
}
