'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { useBoard } from '@/hooks/useBoard';
import { createBoard } from '@/lib/board/actions';
import { deriveKeysFromPassword, encryptSymmetric } from '@/lib/crypto';
import PasswordEntry from '@/components/chat/PasswordEntry';
import RoomDestroyedOverlay from '@/components/chat/RoomDestroyedOverlay';
import BoardCreatedView from './BoardCreatedView';
import BoardHeader from './BoardHeader';
import PostList from './PostList';
import PostComposer from './PostComposer';
import ReportModal from './ReportModal';
import AdminPanel from './AdminPanel';
import type { ReportReason } from '@/types/board';

interface BoardRoomProps {
  boardId: string;
  isCreator: boolean;
}

export default function BoardRoom({ boardId, isCreator }: BoardRoomProps) {
  const router = useRouter();
  const board = useBoard({ boardId });

  // 생성 모드 상태
  const [createData, setCreateData] = useState<{
    boardId: string;
    password: string;
    adminToken: string;
  } | null>(null);

  // 비밀번호 기억 체크박스
  const [rememberPassword, setRememberPassword] = useState(false);
  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordLoading, setPasswordLoading] = useState(false);

  // 신고 모달
  const [reportTarget, setReportTarget] = useState<string | null>(null);

  // 관리자 패널
  const [showAdminPanel, setShowAdminPanel] = useState(false);
  const [adminToken, setAdminToken] = useState<string | null>(null);

  // ─── 게시판 생성 핸들러 ───

  const handleCreate = useCallback(async (boardName: string) => {
    const result = await createBoard('', ''); // placeholder — 실제 암호화는 아래에서

    if ('error' in result) return;

    // 비밀번호에서 암호화 키 유도 후 게시판 이름 암호화
    const { encryptionSeed } = await deriveKeysFromPassword(result.password, result.boardId);
    const encName = encryptSymmetric(boardName, encryptionSeed);

    // 서버에 암호화된 이름 업데이트 — createBoard에서 직접 처리하도록 수정 필요
    // 현재는 createBoard에 encryptedName을 전달하므로 순서 조정 필요
    // → 실제로는 클라이언트에서 먼저 비밀번호를 생성할 수 없으므로
    //   createBoard가 비밀번호를 반환한 후 이름을 암호화해서 별도 업데이트하거나,
    //   클라이언트에서 비밀번호를 미리 생성하는 방식으로 변경

    setCreateData(result);
    setAdminToken(result.adminToken);
  }, []);

  // ─── 비밀번호 입력 핸들러 ───

  const handlePasswordSubmit = useCallback(
    async (password: string) => {
      setPasswordLoading(true);
      setPasswordError(null);

      const result = await board.authenticate(password, rememberPassword);

      if (result.error) {
        setPasswordError(result.error);
      }
      setPasswordLoading(false);
    },
    [board, rememberPassword]
  );

  // ─── 신고 핸들러 ───

  const handleReport = useCallback(
    async (reason: ReportReason) => {
      if (!reportTarget) return;
      await board.submitReport(reportTarget, reason);
      setReportTarget(null);
    },
    [board, reportTarget]
  );

  // ─── 렌더링 ───

  // 파쇄됨
  if (board.status === 'destroyed') {
    return <RoomDestroyedOverlay reason="destroyed" />;
  }

  // 게시판 생성 완료 화면
  if (isCreator && createData) {
    return (
      <BoardCreatedView
        boardId={createData.boardId}
        password={createData.password}
        adminToken={createData.adminToken}
        onEnter={() => {
          router.push(`/board/${createData.boardId}`);
        }}
      />
    );
  }

  // 비밀번호 입력
  if (board.status === 'password_required') {
    return (
      <div className="relative">
        <PasswordEntry
          onSubmit={handlePasswordSubmit}
          error={passwordError}
          loading={passwordLoading}
        />
        {/* 비밀번호 기억하기 체크박스 */}
        <div className="fixed bottom-20 left-0 right-0 flex justify-center px-6 pb-[env(safe-area-inset-bottom)]">
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={rememberPassword}
              onChange={(e) => setRememberPassword(e.target.checked)}
              className="w-4 h-4 accent-signal-green"
            />
            <span className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-wider">
              Remember password on this device
            </span>
          </label>
        </div>
      </div>
    );
  }

  // 로딩
  if (board.status === 'loading') {
    return (
      <div className="h-dvh bg-void-black flex items-center justify-center">
        <span className="font-mono text-xs text-ghost-grey/40 uppercase tracking-wider animate-pulse">
          DECRYPTING...
        </span>
      </div>
    );
  }

  // 게시판 메인 (browsing)
  return (
    <div className="h-dvh bg-void-black flex flex-col">
      <BoardHeader
        boardName={board.boardName ?? 'ENCRYPTED BOARD'}
        onAdmin={() => setShowAdminPanel(true)}
        hasAdminToken={!!adminToken}
        isPasswordSaved={board.isPasswordSaved}
        onForgetPassword={board.forgetSavedPassword}
      />

      <PostList
        posts={board.posts}
        hasMore={board.hasMore}
        onLoadMore={board.loadMore}
        onReport={(postId) => setReportTarget(postId)}
        onRefresh={board.refreshPosts}
        onDecryptImages={board.decryptPostImages}
      />

      <PostComposer onSubmit={board.submitPost} />

      {/* 신고 모달 */}
      <ReportModal
        isOpen={!!reportTarget}
        onConfirm={handleReport}
        onCancel={() => setReportTarget(null)}
      />

      {/* 관리자 패널 */}
      {showAdminPanel && adminToken && (
        <AdminPanel
          boardId={boardId}
          adminToken={adminToken}
          onClose={() => setShowAdminPanel(false)}
          onPostDeleted={(postId) => {
            board.refreshPosts();
          }}
          onBoardDestroyed={() => {
            router.push('/');
          }}
        />
      )}
    </div>
  );
}
