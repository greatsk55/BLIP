import { createServerSupabase } from '@/lib/supabase/server';

export async function POST(request: Request) {
  const { boardIds } = await request.json();

  if (!Array.isArray(boardIds) || boardIds.length === 0 || boardIds.length > 50) {
    return Response.json(
      { error: 'INVALID_PARAMS' },
      { status: 400 }
    );
  }

  const supabase = createServerSupabase();

  const { data: boards, error } = await supabase
    .from('boards')
    .select('id, status')
    .in('id', boardIds);

  if (error) {
    return Response.json({ error: 'SERVER_ERROR' }, { status: 500 });
  }

  const statuses: Record<string, string> = {};

  for (const board of boards ?? []) {
    statuses[board.id] = board.status;
  }

  for (const id of boardIds) {
    if (!statuses[id]) {
      statuses[id] = 'not_found';
    }
  }

  return Response.json({ statuses });
}
