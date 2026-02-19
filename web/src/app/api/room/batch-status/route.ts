import { createServerSupabase } from '@/lib/supabase/server';

export async function POST(request: Request) {
  const { roomIds } = await request.json();

  if (!Array.isArray(roomIds) || roomIds.length === 0 || roomIds.length > 50) {
    return Response.json(
      { error: 'INVALID_PARAMS' },
      { status: 400 }
    );
  }

  const supabase = createServerSupabase();

  const { data: rooms, error } = await supabase
    .from('rooms')
    .select('id, status, expires_at')
    .in('id', roomIds);

  if (error) {
    return Response.json({ error: 'SERVER_ERROR' }, { status: 500 });
  }

  const now = new Date();
  const statuses: Record<string, string> = {};

  // 존재하는 방 상태 매핑
  for (const room of rooms ?? []) {
    if (new Date(room.expires_at) < now) {
      statuses[room.id] = 'expired';
    } else {
      statuses[room.id] = room.status;
    }
  }

  // 존재하지 않는 방은 'not_found'
  for (const id of roomIds) {
    if (!statuses[id]) {
      statuses[id] = 'not_found';
    }
  }

  return Response.json({ statuses });
}
