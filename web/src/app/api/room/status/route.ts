import { getRoomStatus } from '@/lib/room/actions';

export async function POST(request: Request) {
  const { roomId } = await request.json();
  if (!roomId) {
    return Response.json({ exists: false, error: 'MISSING_PARAMS' }, { status: 400 });
  }
  const result = await getRoomStatus(roomId);
  return Response.json(result);
}
