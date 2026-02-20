import { updatePost } from '@/lib/board/actions';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      boardId, postId, authKeyHash,
      authorNameEncrypted, authorNameNonce,
      contentEncrypted, contentNonce,
      titleEncrypted, titleNonce,
    } = body;

    if (!boardId || !postId || !authKeyHash || !authorNameEncrypted || !contentEncrypted) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await updatePost(
      boardId, postId, authKeyHash,
      authorNameEncrypted, authorNameNonce,
      contentEncrypted, contentNonce,
      titleEncrypted, titleNonce,
    );
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
