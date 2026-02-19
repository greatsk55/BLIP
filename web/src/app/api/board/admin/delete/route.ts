import { adminDeletePost } from '@/lib/board/actions';

export async function POST(request: Request) {
  const { boardId, postId, adminToken } = await request.json();
  if (!boardId || !postId || !adminToken) {
    return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
  }
  const result = await adminDeletePost(boardId, postId, adminToken);
  return Response.json(result);
}
