'use client';

import { useRef, useCallback } from 'react';
import { motion } from 'framer-motion';
import { RefreshCw, PenLine } from 'lucide-react';
import { useTranslations } from 'next-intl';
import PostCard from './PostCard';
import type { DecryptedPost } from '@/types/board';

interface PostListProps {
  posts: DecryptedPost[];
  hasMore: boolean;
  onLoadMore: () => Promise<void>;
  onRefresh: () => Promise<void>;
  onPostClick: (post: DecryptedPost) => void;
  onCompose: () => void;
  onSharePost?: (postId: string) => void;
}

export default function PostList({
  posts,
  hasMore,
  onLoadMore,
  onRefresh,
  onPostClick,
  onCompose,
  onSharePost,
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
    <div className="flex-1 overflow-y-auto relative">
      <div className="px-4 py-4">
        {/* 새로고침 버튼 */}
        <div className="flex justify-center mb-4">
          <button
            onClick={onRefresh}
            className="flex items-center gap-2 px-3 py-1.5 text-ghost-grey/70 hover:text-signal-green transition-colors"
          >
            <RefreshCw className="w-3 h-3" />
            <span className="font-mono text-[10px] uppercase tracking-wider">
              {t('post.refresh')}
            </span>
          </button>
        </div>

        {/* 빈 상태 */}
        {posts.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 gap-4">
            <p className="font-mono text-xs text-ghost-grey/60 uppercase tracking-wider">
              {t('post.empty')}
            </p>
            <button
              onClick={onCompose}
              className="font-mono text-[10px] text-signal-green border border-signal-green/30 px-4 py-2 hover:bg-signal-green/10 transition-colors uppercase tracking-wider"
            >
              {t('post.writeFirst')}
            </button>
          </div>
        )}

        {/* 게시글 목록 */}
        <div className="space-y-2">
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
                onClick={() => onPostClick(post)}
                onShare={onSharePost ? () => onSharePost(post.id) : undefined}
              />
            </motion.div>
          ))}
        </div>

        {/* 로딩 더보기 */}
        {hasMore && (
          <div className="flex justify-center py-4">
            <span className="font-mono text-[10px] text-ghost-grey/60 uppercase tracking-wider animate-pulse">
              LOADING...
            </span>
          </div>
        )}
      </div>

      {/* 글쓰기 FAB */}
      {posts.length > 0 && (
        <button
          onClick={onCompose}
          className="fixed bottom-6 right-6 w-12 h-12 bg-signal-green text-void-black rounded-full flex items-center justify-center shadow-lg hover:bg-signal-green/90 active:scale-95 transition-all z-20"
          aria-label={t('post.compose')}
        >
          <PenLine className="w-5 h-5" />
        </button>
      )}
    </div>
  );
}
