import { verifyGroupPassword } from '@/lib/group/actions';
import { checkOrigin, parseJsonBody, isString } from '@/lib/api-utils';

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const body = await parseJsonBody(request);
    if (!body || !isString(body.roomId) || !isString(body.password)) {
      return Response.json({ error: 'Missing fields' }, { status: 400 });
    }

    const result = await verifyGroupPassword(body.roomId, body.password);
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
