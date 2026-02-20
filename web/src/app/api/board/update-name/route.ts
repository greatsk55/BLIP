import { updateBoardName } from '@/lib/board/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 5회
const UPDATE_NAME_LIMIT = { windowMs: 60_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:name:${ip}`, UPDATE_NAME_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const { boardId, authKeyHash, encryptedName, encryptedNameNonce } =
      await request.json();

    if (!boardId || !authKeyHash || !encryptedName || !encryptedNameNonce) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await updateBoardName(
      boardId,
      authKeyHash,
      encryptedName,
      encryptedNameNonce
    );

    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
