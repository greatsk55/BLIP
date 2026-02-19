import { destroyBoard } from '@/lib/board/actions';

export async function POST(request: Request) {
  const { boardId, adminToken } = await request.json();
  if (!boardId || !adminToken) {
    return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
  }
  const result = await destroyBoard(boardId, adminToken);
  return Response.json(result);
}
