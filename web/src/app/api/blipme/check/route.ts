import { checkBlipMeLink } from '@/lib/blipme/actions';
import { parseJsonBody, isString } from '@/lib/api-utils';

export async function POST(request: Request) {
  try {
    const body = await parseJsonBody(request);
    if (!body || !isString(body.linkId)) {
      return Response.json({ error: 'INVALID_BODY' }, { status: 400 });
    }

    const result = await checkBlipMeLink(body.linkId as string);
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
