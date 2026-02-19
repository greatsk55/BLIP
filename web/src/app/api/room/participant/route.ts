import { updateParticipantCount } from '@/lib/room/actions';

export async function POST(request: Request) {
  const { roomId, count } = await request.json();
  if (!roomId || count === undefined) {
    return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
  }
  await updateParticipantCount(roomId, count);
  return Response.json({ ok: true });
}
