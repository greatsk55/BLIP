'use client';

import { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { ArrowLeft, Flag, Pencil, Trash2 } from 'lucide-react';
import { ThemeToggle } from '@/components/ThemeToggle';
import { useTranslations } from 'next-intl';
import type { DecryptedPost, DecryptedComment, ReportReason } from '@/types/board';
import MarkdownContent from './MarkdownContent';
import PostImageGallery from './PostImageGallery';
import CommentList from './CommentList';
import CommentComposer from './CommentComposer';

/** 본문에서 참조된 이미지 인덱스 추출 */
const INLINE_IMG_RE = /!\[[^\]]*\]\(img:(\d+)\)/g;

interface PostDetailProps {
  post: DecryptedPost;
  onBack: () => void;
  onReport: () => void;
  onEdit: () => void;
  onDelete: (postId: string) => Promise<{ error?: string }>;
  onAdminDelete?: (postId: string) => Promise<{ error?: string }>;
  onDecryptImages?: (postId: string) => Promise<void>;
  // 댓글 관련
  comments: DecryptedComment[];
  commentsHasMore: boolean;
  commentsLoading: boolean;
  onLoadComments: (postId: string) => Promise<void>;
  onLoadMoreComments: (postId: string) => Promise<void>;
  onSubmitComment: (postId: string, content: string, images?: File[]) => Promise<{ error?: string }>;
  onDeleteComment: (commentId: string, postId: string, adminToken?: string) => Promise<{ error?: string }>;
  onReportComment: (commentId: string, reason: ReportReason) => Promise<{ error?: string }>;
  onDecryptCommentImages: (commentId: string, postId: string) => Promise<void>;
  onOpenCommentReport: (commentId: string) => void;
  adminToken?: string;
}

export default function PostDetail({
  post,
  onBack,
  onReport,
  onEdit,
  onDelete,
  onAdminDelete,
  onDecryptImages,
  comments,
  commentsHasMore,
  commentsLoading,
  onLoadComments,
  onLoadMoreComments,
  onSubmitComment,
  onDeleteComment,
  onReportComment,
  onDecryptCommentImages,
  onOpenCommentReport,
  adminToken,
}: PostDetailProps) {
  const t = useTranslations('Board');
  const decryptedRef = useRef(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<'own' | 'admin' | null>(null);
  const [deleting, setDeleting] = useState(false);

  const handleDelete = useCallback(async () => {
    setDeleting(true);
    if (showDeleteConfirm === 'admin' && onAdminDelete) {
      await onAdminDelete(post.id);
    } else {
      await onDelete(post.id);
    }
    setDeleting(false);
  }, [showDeleteConfirm, onAdminDelete, onDelete, post.id]);

  // 상세 뷰 진입 시 이미지 복호화
  useEffect(() => {
    if (!onDecryptImages || post.isBlinded || post.images.length > 0 || decryptedRef.current) return;
    decryptedRef.current = true;
    onDecryptImages(post.id);
  }, [onDecryptImages, post.id, post.isBlinded, post.images.length]);

  const formattedDate = formatDate(post.createdAt);

  // 본문에서 인라인 참조된 이미지 인덱스 추출
  const inlineImageIndices = useMemo(() => {
    const indices = new Set<number>();
    let match;
    while ((match = INLINE_IMG_RE.exec(post.content)) !== null) {
      indices.add(parseInt(match[1], 10));
    }
    return indices;
  }, [post.content]);

  // 인라인 참조되지 않은 이미지만 갤러리에 표시
  const galleryImages = useMemo(
    () => post.images.filter((_, i) => !inlineImageIndices.has(i)),
    [post.images, inlineImageIndices]
  );



  // 블라인드 처리된 게시글
  if (post.isBlinded) {
    return (
      <div className="flex-1 overflow-y-auto">
        {/* 헤더 */}
        <div className="sticky top-0 z-10 flex items-center gap-3 px-4 py-3 border-b border-ink/10 bg-void-black/90 backdrop-blur-sm">
          <button
            onClick={onBack}
            className="p-1 text-ghost-grey/60 hover:text-ink transition-colors"
            aria-label="Back"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <span className="font-mono text-xs text-ghost-grey/70 uppercase tracking-wider">
            {t('post.detail')}
          </span>
        </div>

        <div className="flex items-center justify-center py-20 px-4">
          <div className="border border-glitch-red/10 bg-glitch-red/[0.02] px-6 py-4 text-center">
            <span className="font-mono text-xs text-glitch-red uppercase tracking-wider">
              {t('blinded.message')}
            </span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {/* 헤더 */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-ink/10 bg-void-black/90 backdrop-blur-sm shrink-0">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-1 text-ghost-grey/60 hover:text-ink transition-colors"
            aria-label="Back"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <span className="font-mono text-xs text-ghost-grey/70 uppercase tracking-wider">
            {t('post.detail')}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <ThemeToggle />
          {post.isMine && (
            <>
              <button
                onClick={onEdit}
                className="p-2 text-ghost-grey/60 hover:text-signal-green transition-colors"
                aria-label={t('post.edit')}
              >
                <Pencil className="w-4 h-4" />
              </button>
              <button
                onClick={() => setShowDeleteConfirm('own')}
                className="p-2 text-ghost-grey/60 hover:text-glitch-red transition-colors"
                aria-label={t('post.delete')}
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </>
          )}
          {!post.isMine && (
            <>
              <button
                onClick={onReport}
                className="p-2 text-ghost-grey/60 hover:text-glitch-red transition-colors"
                aria-label={t('report.title')}
              >
                <Flag className="w-4 h-4" />
              </button>
              {onAdminDelete && (
                <button
                  onClick={() => setShowDeleteConfirm('admin')}
                  className="p-2 text-ghost-grey/60 hover:text-glitch-red transition-colors"
                  aria-label={t('post.adminDelete')}
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              )}
            </>
          )}
        </div>
      </div>

      {/* 스크롤 영역: 본문 + 댓글 목록 */}
      <div className="flex-1 overflow-y-auto">
      {/* 게시글 본문 */}
      <article className="px-4 py-6">
        {/* 작성자 + 시간 */}
        <div className="flex items-center gap-3 mb-4">
          <span
            className={`font-mono text-xs uppercase tracking-wider ${
              post.isMine ? 'text-signal-green' : 'text-ghost-grey/60'
            }`}
          >
            {post.authorName}
          </span>
          <span className="font-mono text-[10px] text-ghost-grey/60">
            {formattedDate}
          </span>
        </div>

        {/* 제목 */}
        {post.title && (
          <h1 className="font-mono text-lg font-bold text-ink mb-4 leading-tight">
            {post.title}
          </h1>
        )}

        {/* 마크다운 본문 (인라인 이미지 포함) */}
        {post.content && (
          <div className="mb-6">
            <MarkdownContent content={post.content} images={post.images} />
          </div>
        )}

        {/* 인라인 참조되지 않은 이미지만 갤러리에 표시 */}
        {galleryImages.length > 0 && (
          <div className="mb-6">
            <PostImageGallery images={galleryImages} />
          </div>
        )}
      </article>

      {/* 댓글 영역 */}
      <CommentList
        postId={post.id}
        comments={comments}
        hasMore={commentsHasMore}
        loading={commentsLoading}
        onLoadComments={onLoadComments}
        onLoadMore={onLoadMoreComments}
        onDeleteComment={onDeleteComment}
        onReportComment={onReportComment}
        onDecryptImages={onDecryptCommentImages}
        onOpenReport={onOpenCommentReport}
        adminToken={adminToken}
      />

      </div>

      {/* 댓글 입력 (하단 고정) */}
      <CommentComposer
        postId={post.id}
        onSubmit={onSubmitComment}
      />

      {/* 삭제 확인 모달 */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-void-black/80 backdrop-blur-sm px-4">
          <div className="border border-glitch-red/20 bg-void-black max-w-sm w-full p-6 text-center">
            <p className="font-mono text-xs text-glitch-red uppercase tracking-wider mb-6">
              {t('post.deleteWarning')}
            </p>
            <div className="flex gap-3">
              <button
                onClick={() => setShowDeleteConfirm(null)}
                className="flex-1 min-h-[44px] px-4 py-2 border border-ink/10 text-ghost-grey font-mono text-xs uppercase tracking-wider"
              >
                {t('report.cancel')}
              </button>
              <button
                onClick={handleDelete}
                disabled={deleting}
                className="flex-1 min-h-[44px] px-4 py-2 border border-glitch-red text-glitch-red font-mono text-xs uppercase tracking-wider hover:bg-glitch-red hover:text-white transition-all disabled:opacity-50"
              >
                {deleting ? '...' : t('post.confirmDelete')}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  const now = new Date();
  const diff = now.getTime() - date.getTime();

  const minutes = Math.floor(diff / 60_000);
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes}m ago`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;

  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d ago`;

  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
  });
}
