import { destroyRoom } from '@/lib/room/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 5회
const DESTROY_LIMIT = { windowMs: 60_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`destroy:${ip}`, DESTROY_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const { roomId, authKeyHash } = await request.json();
    if (!roomId || !authKeyHash) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }
    await destroyRoom(roomId, authKeyHash);
    return Response.json({ ok: true });
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
