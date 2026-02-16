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
import PostDetail from './PostDetail';
import PostComposer from './PostComposer';
import ReportModal from './ReportModal';
import AdminPanel from './AdminPanel';
import type { DecryptedPost, ReportReason } from '@/types/board';

type BoardView = 'list' | 'detail' | 'compose' | 'edit';

interface BoardRoomProps {
  boardId: string;
  isCreator: boolean;
}

export default function BoardRoom({ boardId, isCreator }: BoardRoomProps) {
  const router = useRouter();
  const board = useBoard({ boardId });

  // 뷰 전환
  const [view, setView] = useState<BoardView>('list');
  const [selectedPostId, setSelectedPostId] = useState<string | null>(null);

  // posts에서 실시간 파생 (이미지 복호화 등 상태 변경 반영)
  const selectedPost = selectedPostId
    ? board.posts.find((p) => p.id === selectedPostId) ?? null
    : null;

  // 생성 모드 상태
  const [createData, setCreateData] = useState<{
    boardId: string;
    password: string;
    adminToken: string;
  } | null>(null);

  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordLoading, setPasswordLoading] = useState(false);

  // 신고 모달
  const [reportTarget, setReportTarget] = useState<string | null>(null);

  // 관리자 패널
  const [showAdminPanel, setShowAdminPanel] = useState(false);

  // ─── 뷰 전환 핸들러 ───

  const handlePostClick = useCallback((post: DecryptedPost) => {
    if (post.isBlinded) return;
    setSelectedPostId(post.id);
    setView('detail');
  }, []);

  const handleBackToList = useCallback(() => {
    setView('list');
    setSelectedPostId(null);
  }, []);

  // ─── 게시판 생성 핸들러 ───

  const handleCreate = useCallback(async (boardName: string) => {
    const result = await createBoard('', '');

    if ('error' in result) return;

    const { encryptionSeed } = await deriveKeysFromPassword(result.password, result.boardId);
    const encName = encryptSymmetric(boardName, encryptionSeed);

    setCreateData(result);
    board.saveAdminToken(result.adminToken);
  }, [board]);

  // ─── 비밀번호 입력 핸들러 ───

  const handlePasswordSubmit = useCallback(
    async (password: string) => {
      setPasswordLoading(true);
      setPasswordError(null);

      const result = await board.authenticate(password);

      if (result.error) {
        setPasswordError(result.error);
      }
      setPasswordLoading(false);
    },
    [board]
  );

  // ─── 글 작성 완료 → 리스트로 복귀 ───

  const handleSubmitPost = useCallback(
    async (title: string, content: string, images?: File[]): Promise<{ error?: string }> => {
      const result = await board.submitPost(title, content, images);
      return result;
    },
    [board]
  );

  // ─── 수정 핸들러 ───

  const handleEditPost = useCallback(
    async (title: string, content: string): Promise<{ error?: string }> => {
      if (!selectedPostId) return { error: 'NO_POST' };
      const result = await board.editPost(selectedPostId, title, content);
      if (!result.error) {
        // board.editPost가 posts 상태를 업데이트 → selectedPost 자동 반영
        setView('detail');
      }
      return result;
    },
    [board, selectedPostId]
  );

  // ─── 본인 삭제 핸들러 ───

  const handleDeletePost = useCallback(
    async (postId: string): Promise<{ error?: string }> => {
      const result = await board.deletePost(postId);
      if (!result.error) {
        handleBackToList();
      }
      return result;
    },
    [board, handleBackToList]
  );

  // ─── 관리자 삭제 핸들러 ───

  const handleAdminDelete = useCallback(
    async (postId: string): Promise<{ error?: string }> => {
      if (!board.adminToken) return { error: 'NO_ADMIN_TOKEN' };
      const result = await board.deletePost(postId, board.adminToken);
      if (!result.error) {
        handleBackToList();
      }
      return result;
    },
    [board, handleBackToList]
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
      <PasswordEntry
        onSubmit={handlePasswordSubmit}
        error={passwordError}
        loading={passwordLoading}
      />
    );
  }

  // 로딩
  if (board.status === 'loading') {
    return (
      <div className="h-dvh bg-void-black flex items-center justify-center">
        <span className="font-mono text-xs text-ghost-grey/70 uppercase tracking-wider animate-pulse">
          DECRYPTING...
        </span>
      </div>
    );
  }

  // ─── 메인 (browsing) ───

  return (
    <div className="h-dvh bg-void-black flex flex-col">
      {/* 헤더: list 뷰에서만 표시 */}
      {view === 'list' && (
        <BoardHeader
          boardName={board.boardName ?? 'PRIVATE COMMUNITY'}
          onAdmin={() => setShowAdminPanel(true)}
          hasAdminToken={!!board.adminToken}
          isPasswordSaved={board.isPasswordSaved}
          onForgetPassword={board.forgetSavedPassword}
          onSaveAdminToken={board.saveAdminToken}
        />
      )}

      {/* 뷰 전환 */}
      {view === 'list' && (
        <PostList
          posts={board.posts}
          hasMore={board.hasMore}
          onLoadMore={board.loadMore}
          onRefresh={board.refreshPosts}
          onPostClick={handlePostClick}
          onCompose={() => setView('compose')}
        />
      )}

      {view === 'detail' && selectedPost && (
        <PostDetail
          post={selectedPost}
          onBack={handleBackToList}
          onReport={() => setReportTarget(selectedPost.id)}
          onEdit={() => setView('edit')}
          onDelete={handleDeletePost}
          onAdminDelete={board.adminToken ? handleAdminDelete : undefined}
          onDecryptImages={board.decryptPostImages}
        />
      )}

      {view === 'compose' && (
        <PostComposer
          onSubmit={handleSubmitPost}
          onBack={handleBackToList}
        />
      )}

      {view === 'edit' && selectedPost && (
        <PostComposer
          editPost={selectedPost}
          onSubmit={handleEditPost}
          onBack={() => setView('detail')}
        />
      )}

      {/* 신고 모달 */}
      <ReportModal
        isOpen={!!reportTarget}
        onConfirm={handleReport}
        onCancel={() => setReportTarget(null)}
      />

      {/* 관리자 패널 */}
      {showAdminPanel && board.adminToken && (
        <AdminPanel
          boardId={boardId}
          adminToken={board.adminToken}
          onClose={() => setShowAdminPanel(false)}
          onPostDeleted={() => {
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
