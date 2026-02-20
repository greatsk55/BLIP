import { deleteOwnPost } from '@/lib/board/actions';

export async function POST(request: Request) {
  try {
    const { boardId, postId, authKeyHash } = await request.json();
    if (!boardId || !postId || !authKeyHash) {
      return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }
    const result = await deleteOwnPost(boardId, postId, authKeyHash);
    return Response.json(result);
  } catch {
    return Response.json({ success: false, error: 'Internal error' }, { status: 500 });
  }
}
