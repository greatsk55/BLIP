import { reportPost } from '@/lib/board/actions';

export async function POST(request: Request) {
  try {
    const { boardId, postId, authKeyHash, reason } = await request.json();
    if (!boardId || !postId || !authKeyHash || !reason) {
      return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }
    const result = await reportPost(boardId, postId, authKeyHash, reason);
    return Response.json(result);
  } catch {
    return Response.json({ success: false, error: 'Internal error' }, { status: 500 });
  }
}
