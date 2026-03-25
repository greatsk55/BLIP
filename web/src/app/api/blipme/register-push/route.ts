import { registerBlipMePush } from '@/lib/blipme/actions';
import { checkOrigin, parseJsonBody, isString } from '@/lib/api-utils';

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const body = await parseJsonBody(request);
    if (
      !body ||
      !isString(body.linkId) ||
      !isString(body.ownerTokenHash) ||
      !isString(body.fcmToken)
    ) {
      return Response.json({ error: 'INVALID_BODY' }, { status: 400 });
    }

    const result = await registerBlipMePush(
      body.linkId as string,
      body.ownerTokenHash as string,
      body.fcmToken as string,
    );
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
