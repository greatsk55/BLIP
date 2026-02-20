import { getRoomStatus } from '@/lib/room/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 30회
const STATUS_LIMIT = { windowMs: 60_000, maxRequests: 30 };

export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`room:status:${ip}`, STATUS_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ exists: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const { roomId } = await request.json();
    if (!roomId) {
      return Response.json({ exists: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }
    const result = await getRoomStatus(roomId);
    return Response.json(result);
  } catch {
    return Response.json({ exists: false, error: 'Internal error' }, { status: 500 });
  }
}
