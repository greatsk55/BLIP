import { regenerateBlipMeLink } from '@/lib/blipme/actions';
import { checkOrigin, parseJsonBody, isString } from '@/lib/api-utils';

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const body = await parseJsonBody(request);
    if (!body || !isString(body.oldLinkId) || !isString(body.ownerTokenHash)) {
      return Response.json({ error: 'INVALID_BODY' }, { status: 400 });
    }

    const result = await regenerateBlipMeLink(
      body.oldLinkId as string,
      body.ownerTokenHash as string,
    );
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
