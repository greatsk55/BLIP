import { updateBoardName } from '@/lib/board/actions';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';

// IP당 분당 5회
const UPDATE_NAME_LIMIT = { windowMs: 60_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:name:${ip}`, UPDATE_NAME_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const {
      boardId, authKeyHash, encryptedName, encryptedNameNonce,
      encryptedSubtitle, encryptedSubtitleNonce,
    } = body;

    if (!isString(boardId) || !isString(authKeyHash) || !isString(encryptedName) || !isString(encryptedNameNonce)) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await updateBoardName(
      boardId,
      authKeyHash,
      encryptedName,
      encryptedNameNonce,
      encryptedSubtitle as string | undefined,
      encryptedSubtitleNonce as string | undefined
    );

    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
