import { joinBoardViaInviteCode } from '@/lib/board/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

const JOIN_INVITE_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ valid: false, error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:board:join-invite:${ip}`, JOIN_INVITE_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ valid: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ valid: false, error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardId, inviteCodeHash } = body;
    if (!isString(boardId) || !isString(inviteCodeHash)) {
      return Response.json({ valid: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await joinBoardViaInviteCode(boardId, inviteCodeHash);
    return Response.json(result);
  } catch {
    return Response.json({ valid: false, error: 'Internal error' }, { status: 500 });
  }
}
