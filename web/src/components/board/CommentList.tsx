'use client';

import { useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';
import type { DecryptedComment, ReportReason } from '@/types/board';
import CommentCard from './CommentCard';

interface CommentListProps {
  postId: string;
  comments: DecryptedComment[];
  hasMore: boolean;
  loading: boolean;
  onLoadComments: (postId: string) => Promise<void>;
  onLoadMore: (postId: string) => Promise<void>;
  onDeleteComment: (commentId: string, postId: string, adminToken?: string) => Promise<{ error?: string }>;
  onReportComment: (commentId: string, reason: ReportReason) => Promise<{ error?: string }>;
  onDecryptImages: (commentId: string, postId: string) => Promise<void>;
  onOpenReport: (commentId: string) => void;
  adminToken?: string;
}

export default function CommentList({
  postId,
  comments,
  hasMore,
  loading,
  onLoadComments,
  onLoadMore,
  onDeleteComment,
  onDecryptImages,
  onOpenReport,
  adminToken,
}: CommentListProps) {
  const t = useTranslations('Board');
  const loadedRef = useRef(false);

  // 최초 마운트 시 댓글 로드
  useEffect(() => {
    if (loadedRef.current) return;
    loadedRef.current = true;
    onLoadComments(postId);
  }, [onLoadComments, postId]);

  return (
    <div className="border-t border-ink/10">
      {/* 댓글 헤더 */}
      <div className="px-4 py-2 border-b border-ink/5">
        <span className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-wider">
          {t('comment.title')} ({comments.length}{hasMore ? '+' : ''})
        </span>
      </div>

      {/* 댓글 목록 */}
      {comments.length === 0 && !loading && (
        <div className="px-4 py-8 text-center">
          <p className="font-mono text-[10px] text-ghost-grey/40 uppercase tracking-wider">
            {t('comment.empty')}
          </p>
          <p className="font-mono text-[9px] text-ghost-grey/30 mt-1">
            {t('comment.writeFirst')}
          </p>
        </div>
      )}

      {comments.map((comment) => (
        <CommentCard
          key={comment.id}
          comment={comment}
          onReport={() => onOpenReport(comment.id)}
          onDelete={() => onDeleteComment(comment.id, postId)}
          onAdminDelete={
            adminToken
              ? () => onDeleteComment(comment.id, postId, adminToken)
              : undefined
          }
          onDecryptImages={() => onDecryptImages(comment.id, postId)}
        />
      ))}

      {/* 로딩 */}
      {loading && (
        <div className="px-4 py-3 text-center">
          <span className="font-mono text-[9px] text-ghost-grey/40 animate-pulse uppercase tracking-wider">
            LOADING...
          </span>
        </div>
      )}

      {/* 더 보기 버튼 */}
      {hasMore && !loading && (
        <button
          onClick={() => onLoadMore(postId)}
          className="w-full px-4 py-2.5 border-b border-ink/5 text-center font-mono text-[10px] text-ghost-grey/60 uppercase tracking-wider hover:text-ink hover:bg-ink/[0.02] transition-colors"
        >
          {t('comment.loadMore')}
        </button>
      )}
    </div>
  );
}
