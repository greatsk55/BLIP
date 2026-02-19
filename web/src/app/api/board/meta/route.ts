import { getBoardMeta } from '@/lib/board/actions';

export async function POST(request: Request) {
  const { boardId, authKeyHash } = await request.json();
  if (!boardId || !authKeyHash) {
    return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
  }
  const result = await getBoardMeta(boardId, authKeyHash);
  return Response.json(result);
}
