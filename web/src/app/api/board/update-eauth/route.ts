import { updateEncryptionKeyAuthHash } from '@/lib/board/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

const UPDATE_EAUTH_LIMIT = { windowMs: 60_000, maxRequests: 10 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:board:update-eauth:${ip}`, UPDATE_EAUTH_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardId, authKeyHash, encryptionKeyAuthHash } = body;
    if (!isString(boardId) || !isString(authKeyHash) || !isString(encryptionKeyAuthHash)) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    await updateEncryptionKeyAuthHash(boardId, authKeyHash, encryptionKeyAuthHash);
    return Response.json({ success: true });
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
