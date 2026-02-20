import { verifyPassword } from '@/lib/room/actions';

export async function POST(request: Request) {
  try {
    const { roomId, password } = await request.json();
    if (!roomId || !password) {
      return Response.json({ valid: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }
    const result = await verifyPassword(roomId, password);
    return Response.json(result);
  } catch {
    return Response.json({ valid: false, error: 'Internal error' }, { status: 500 });
  }
}
