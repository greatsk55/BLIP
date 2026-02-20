import { updateParticipantCount } from '@/lib/room/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 10회
const PARTICIPANT_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`participant:${ip}`, PARTICIPANT_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const { roomId, count, authKeyHash } = await request.json();
    if (!roomId || count === undefined || !authKeyHash) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }
    await updateParticipantCount(roomId, count, authKeyHash);
    return Response.json({ ok: true });
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
