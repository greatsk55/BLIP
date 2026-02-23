'use client';

import { useState, useCallback, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { useBoard } from '@/hooks/useBoard';
import { getCreatedInfo } from '@/app/[locale]/board/BoardCreateClient';
import PasswordEntry from '@/components/chat/PasswordEntry';
import RoomDestroyedOverlay from '@/components/chat/RoomDestroyedOverlay';
import CopyButton from '@/components/shared/CopyButton';
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
}

export default function BoardRoom({ boardId }: BoardRoomProps) {
  const t = useTranslations('Board');
  const router = useRouter();
  const board = useBoard({ boardId });

  // 뷰 전환
  const [view, setView] = useState<BoardView>('list');
  const [selectedPostId, setSelectedPostId] = useState<string | null>(null);

  // posts에서 실시간 파생 (이미지 복호화 등 상태 변경 반영)
  const selectedPost = selectedPostId
    ? board.posts.find((p) => p.id === selectedPostId) ?? null
    : null;

  const [passwordError, setPasswordError] = useState<string | null>(null);
  const [passwordLoading, setPasswordLoading] = useState(false);

  // 생성 직후 안내 모달
  const [createdInfo, setCreatedInfo] = useState<{ password: string; adminToken: string } | null>(null);

  useEffect(() => {
    const info = getCreatedInfo(boardId);
    if (info) {
      setCreatedInfo(info);
    }
  }, [boardId]);

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
          boardSubtitle={board.boardSubtitle}
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
          currentSubtitle={board.boardSubtitle}
          onUpdateSubtitle={board.updateSubtitle}
          onClose={() => setShowAdminPanel(false)}
          onPostDeleted={() => {
            board.refreshPosts();
          }}
          onBoardDestroyed={() => {
            router.push('/');
          }}
        />
      )}

      {/* 생성 직후 비밀번호/토큰 안내 모달 */}
      <AnimatePresence>
        {createdInfo && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 px-6"
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="w-full max-w-sm bg-void-black border border-signal-green/20 p-6"
            >
              <p className="font-mono text-xs text-signal-green uppercase tracking-[0.3em] mb-6 text-center">
                {t('create.title')}
              </p>

              {/* 비밀번호 */}
              <div className="mb-4">
                <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-2">
                  {t('create.password')}
                </p>
                <div className="flex items-center gap-2 bg-ink/[0.03] border border-signal-green/20 px-4 py-3">
                  <span className="font-mono text-lg text-ink tracking-[0.3em] flex-1">
                    {createdInfo.password}
                  </span>
                  <CopyButton text={createdInfo.password} />
                </div>
              </div>

              {/* 관리자 토큰 */}
              <div className="mb-4">
                <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-2">
                  {t('create.adminToken')}
                </p>
                <div className="flex items-center gap-2 bg-ink/[0.03] border border-glitch-red/20 px-3 py-3">
                  <span className="font-mono text-[10px] text-ghost-grey break-all flex-1">
                    {createdInfo.adminToken}
                  </span>
                  <CopyButton text={createdInfo.adminToken} />
                </div>
                <p className="font-mono text-[9px] text-glitch-red/50 uppercase tracking-wider mt-1">
                  {t('create.adminTokenWarning')}
                </p>
              </div>

              {/* 공유 링크 */}
              <div className="mb-6">
                <p className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-widest mb-2">
                  {t('create.shareLink')}
                </p>
                <div className="flex items-center gap-2 bg-ink/[0.03] border border-ink/10 px-3 py-3">
                  <span className="font-mono text-[11px] text-ghost-grey break-all flex-1">
                    {typeof window !== 'undefined' ? `${window.location.origin}/board/${boardId}` : ''}
                  </span>
                  <CopyButton
                    text={typeof window !== 'undefined' ? `${window.location.origin}/board/${boardId}` : ''}
                  />
                </div>
              </div>

              <button
                onClick={() => setCreatedInfo(null)}
                className="w-full min-h-[44px] px-6 py-3 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-xs uppercase tracking-wider"
              >
                {t('create.confirmInfo')}
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
