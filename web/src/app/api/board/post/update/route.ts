import { updatePost } from '@/lib/board/actions';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

const POST_UPDATE_LIMIT = { windowMs: 60_000, maxRequests: 5 };

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`api:post:update:${ip}`, POST_UPDATE_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ error: 'INVALID_JSON' }, { status: 400 });
    }

    const {
      boardId, postId, authKeyHash,
      authorNameEncrypted, authorNameNonce,
      contentEncrypted, contentNonce,
      titleEncrypted, titleNonce,
    } = body;

    if (!isString(boardId) || !isString(postId) || !isString(authKeyHash) || !isString(authorNameEncrypted) || !isString(contentEncrypted)) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await updatePost(
      boardId, postId, authKeyHash,
      authorNameEncrypted, authorNameNonce as string,
      contentEncrypted, contentNonce as string,
      titleEncrypted as string | undefined, titleNonce as string | undefined,
    );
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
