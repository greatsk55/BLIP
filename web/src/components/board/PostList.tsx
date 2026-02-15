'use client';

import { useRef, useCallback } from 'react';
import { motion } from 'framer-motion';
import { RefreshCw } from 'lucide-react';
import { useTranslations } from 'next-intl';
import PostCard from './PostCard';
import type { DecryptedPost } from '@/types/board';

interface PostListProps {
  posts: DecryptedPost[];
  hasMore: boolean;
  onLoadMore: () => Promise<void>;
  onReport: (postId: string) => void;
  onRefresh: () => Promise<void>;
  onDecryptImages?: (postId: string) => Promise<void>;
}

export default function PostList({
  posts,
  hasMore,
  onLoadMore,
  onReport,
  onRefresh,
  onDecryptImages,
}: PostListProps) {
  const t = useTranslations('Board');
  const observerRef = useRef<IntersectionObserver | null>(null);

  // 무한 스크롤: 마지막 요소 감지
  const lastPostRef = useCallback(
    (node: HTMLDivElement | null) => {
      if (observerRef.current) observerRef.current.disconnect();
      if (!node || !hasMore) return;

      observerRef.current = new IntersectionObserver((entries) => {
        if (entries[0].isIntersecting) {
          onLoadMore();
        }
      });
      observerRef.current.observe(node);
    },
    [hasMore, onLoadMore]
  );

  return (
    <div className="flex-1 overflow-y-auto px-4 py-4">
      {/* 새로고침 버튼 */}
      <div className="flex justify-center mb-4">
        <button
          onClick={onRefresh}
          className="flex items-center gap-2 px-3 py-1.5 text-ghost-grey/40 hover:text-signal-green transition-colors"
        >
          <RefreshCw className="w-3 h-3" />
          <span className="font-mono text-[10px] uppercase tracking-wider">
            {t('post.refresh')}
          </span>
        </button>
      </div>

      {/* 빈 상태 */}
      {posts.length === 0 && (
        <div className="flex items-center justify-center py-20">
          <p className="font-mono text-xs text-ghost-grey/30 uppercase tracking-wider">
            {t('post.empty')}
          </p>
        </div>
      )}

      {/* 게시글 목록 */}
      <div className="space-y-3">
        {posts.map((post, index) => (
          <motion.div
            key={post.id}
            ref={index === posts.length - 1 ? lastPostRef : undefined}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: Math.min(index * 0.05, 0.3) }}
          >
            <PostCard
              post={post}
              onReport={() => onReport(post.id)}
              onDecryptImages={onDecryptImages}
            />
          </motion.div>
        ))}
      </div>

      {/* 로딩 더보기 */}
      {hasMore && (
        <div className="flex justify-center py-4">
          <span className="font-mono text-[10px] text-ghost-grey/30 uppercase tracking-wider animate-pulse">
            LOADING...
          </span>
        </div>
      )}
    </div>
  );
}
