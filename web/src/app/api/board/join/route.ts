import { joinBoard } from '@/lib/board/actions';

export async function POST(request: Request) {
  try {
    const { boardId, password } = await request.json();
    if (!boardId || !password) {
      return Response.json({ valid: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }
    const result = await joinBoard(boardId, password);
    return Response.json(result);
  } catch {
    return Response.json({ valid: false, error: 'Internal error' }, { status: 500 });
  }
}
