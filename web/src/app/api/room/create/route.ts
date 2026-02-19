import { createRoom } from '@/lib/room/actions';

export async function POST() {
  const result = await createRoom();
  return Response.json(result);
}
