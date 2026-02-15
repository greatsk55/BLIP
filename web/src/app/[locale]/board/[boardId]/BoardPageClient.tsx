'use client';

import BoardRoom from '@/components/board/BoardRoom';
import { ThemeToggle } from '@/components/ThemeToggle';

interface BoardPageClientProps {
  boardId: string;
}

export default function BoardPageClient({ boardId }: BoardPageClientProps) {
  return (
    <>
      <div className="fixed top-4 right-4 z-50 pt-[env(safe-area-inset-top)]">
        <ThemeToggle />
      </div>
      <BoardRoom boardId={boardId} isCreator={false} />
    </>
  );
}
