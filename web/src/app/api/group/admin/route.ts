import { NextResponse } from 'next/server';
import { toggleGroupLock, destroyGroupRoom, banUserFromGroup } from '@/lib/group/actions';
import { checkOrigin, parseJsonBody, isString } from '@/lib/api-utils';

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return NextResponse.json({ error: 'FORBIDDEN' }, { status: 403 });
    }

    const body = await parseJsonBody(request);
    if (!body || !isString(body.roomId) || !isString(body.adminToken) || !isString(body.action)) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }

    const { roomId, adminToken, action } = body;

    switch (action) {
      case 'lock':
        return NextResponse.json(await toggleGroupLock(roomId, adminToken, true));
      case 'unlock':
        return NextResponse.json(await toggleGroupLock(roomId, adminToken, false));
      case 'destroy':
        return NextResponse.json(await destroyGroupRoom(roomId, adminToken));
      case 'ban':
        if (!isString(body.userToken)) {
          return NextResponse.json({ error: 'Missing userToken' }, { status: 400 });
        }
        return NextResponse.json(await banUserFromGroup(roomId, adminToken, body.userToken));
      default:
        return NextResponse.json({ error: 'Unknown action' }, { status: 400 });
    }
  } catch {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
