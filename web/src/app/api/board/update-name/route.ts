import { updateBoardName } from '@/lib/board/actions';

export async function POST(request: Request) {
  const { boardId, authKeyHash, encryptedName, encryptedNameNonce } =
    await request.json();

  if (!boardId || !authKeyHash || !encryptedName || !encryptedNameNonce) {
    return Response.json({ error: 'MISSING_PARAMS' }, { status: 400 });
  }

  const result = await updateBoardName(
    boardId,
    authKeyHash,
    encryptedName,
    encryptedNameNonce
  );

  return Response.json(result);
}
