import { createPost } from '@/lib/board/actions';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      boardId, authKeyHash,
      authorNameEncrypted, authorNameNonce,
      contentEncrypted, contentNonce,
      titleEncrypted, titleNonce,
    } = body;

    if (!boardId || !authKeyHash || !authorNameEncrypted || !contentEncrypted) {
      return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const result = await createPost(
      boardId, authKeyHash,
      authorNameEncrypted, authorNameNonce,
      contentEncrypted, contentNonce,
      titleEncrypted, titleNonce,
    );
    return Response.json(result);
  } catch {
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}
