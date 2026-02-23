'use client';

import BoardRoom from '@/components/board/BoardRoom';

interface BoardPageClientProps {
  boardId: string;
}

export default function BoardPageClient({ boardId }: BoardPageClientProps) {
  return <BoardRoom boardId={boardId} />;
}
