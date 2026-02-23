import { updateParticipantCount } from '@/lib/room/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isString, isNumber, clampInt, checkOrigin } from '@/lib/api-utils';

// IP당 분당 10회
const PARTICIPANT_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`participant:${ip}`, PARTICIPANT_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { roomId, count, authKeyHash } = body;
    if (!isString(roomId) || !isNumber(count) || !isString(authKeyHash)) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    // participant count 범위 제한 (0~2, 1:1 채팅이므로)
    const safeCount = clampInt(count, 0, 2, 0);
    await updateParticipantCount(roomId, safeCount, authKeyHash);
    return Response.json({ ok: true });
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
