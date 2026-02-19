import { destroyRoom } from '@/lib/room/actions';

export async function POST(request: Request) {
  const { roomId } = await request.json();
  if (!roomId) {
    return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
  }
  await destroyRoom(roomId);
  return Response.json({ ok: true });
}
