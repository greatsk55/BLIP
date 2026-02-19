import { getPosts } from '@/lib/board/actions';

export async function POST(request: Request) {
  const { boardId, authKeyHash, cursor, limit } = await request.json();
  if (!boardId || !authKeyHash) {
    return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
  }
  const result = await getPosts(boardId, authKeyHash, cursor, limit);
  return Response.json(result);
}
