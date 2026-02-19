import { createBoard } from '@/lib/board/actions';

export async function POST(request: Request) {
  const { encryptedName, encryptedNameNonce } = await request.json();
  if (!encryptedName || !encryptedNameNonce) {
    return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
  }
  const result = await createBoard(encryptedName, encryptedNameNonce);
  return Response.json(result);
}
