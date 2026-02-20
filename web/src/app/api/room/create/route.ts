import { createRoom } from '@/lib/room/actions';

export async function POST() {
  try {
    const result = await createRoom();
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
