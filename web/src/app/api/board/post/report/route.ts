import { reportPost } from '@/lib/board/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

const REPORT_LIMIT = { windowMs: 3_600_000, maxRequests: 10 };

const VALID_REASONS = new Set(['spam', 'abuse', 'illegal', 'other']);

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ success: false, error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:report:${ip}`, REPORT_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ success: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ success: false, error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardId, postId, authKeyHash, reason } = body;
    if (!isString(boardId) || !isString(postId) || !isString(authKeyHash) || !isString(reason)) {
      return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }

    if (!VALID_REASONS.has(reason)) {
      return Response.json({ success: false, error: 'INVALID_REASON' }, { status: 400 });
    }

    const result = await reportPost(boardId, postId, authKeyHash, reason as 'spam' | 'abuse' | 'illegal' | 'other');
    return Response.json(result);
  } catch {
    return Response.json({ success: false, error: 'Internal error' }, { status: 500 });
  }
}
