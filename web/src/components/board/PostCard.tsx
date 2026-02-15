'use client';

import { useState, useEffect, useRef } from 'react';
import { Flag } from 'lucide-react';
import { useTranslations } from 'next-intl';
import type { DecryptedPost } from '@/types/board';
import MarkdownContent from './MarkdownContent';
import PostImageGallery from './PostImageGallery';

interface PostCardProps {
  post: DecryptedPost;
  onReport: () => void;
  onDecryptImages?: (postId: string) => Promise<void>;
}

export default function PostCard({ post, onReport, onDecryptImages }: PostCardProps) {
  const t = useTranslations('Board');
  const [showMenu, setShowMenu] = useState(false);
  const cardRef = useRef<HTMLDivElement>(null);
  const decryptedRef = useRef(false);

  // IntersectionObserver: 뷰포트 진입 시 이미지 복호화 트리거
  useEffect(() => {
    if (!onDecryptImages || post.isBlinded || post.images.length > 0 || decryptedRef.current) return;

    const el = cardRef.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting && !decryptedRef.current) {
          decryptedRef.current = true;
          onDecryptImages(post.id);
        }
      },
      { threshold: 0.1 }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [onDecryptImages, post.id, post.isBlinded, post.images.length]);

  // 시간 포맷
  const timeAgo = formatTimeAgo(post.createdAt);

  // 블라인드 처리된 게시글
  if (post.isBlinded) {
    return (
      <div className="border border-glitch-red/10 bg-glitch-red/[0.02] px-4 py-3 opacity-50">
        <span className="font-mono text-[10px] text-glitch-red uppercase tracking-wider">
          {t('blinded.message')}
        </span>
      </div>
    );
  }

  return (
    <div
      ref={cardRef}
      className={`border px-4 py-3 ${
        post.isMine
          ? 'border-signal-green/10 bg-signal-green/[0.02]'
          : 'border-ink/5 bg-ink/[0.01]'
      }`}
    >
      {/* 헤더: 작성자 + 시간 + 메뉴 */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span
            className={`font-mono text-[10px] uppercase tracking-wider ${
              post.isMine ? 'text-signal-green' : 'text-ghost-grey/60'
            }`}
          >
            {post.authorName}
          </span>
          <span className="font-mono text-[9px] text-ghost-grey/30">
            {timeAgo}
          </span>
        </div>

        {!post.isMine && (
          <button
            onClick={() => setShowMenu(!showMenu)}
            className="p-1 text-ghost-grey/20 hover:text-glitch-red transition-colors"
            aria-label={t('report.title')}
          >
            <Flag className="w-3 h-3" />
          </button>
        )}
      </div>

      {/* 본문: 마크다운 렌더링 */}
      {post.content && <MarkdownContent content={post.content} />}

      {/* 이미지 갤러리 */}
      {post.images.length > 0 && <PostImageGallery images={post.images} />}

      {/* 신고 버튼 (토글) */}
      {showMenu && !post.isMine && (
        <div className="mt-2 pt-2 border-t border-ink/5">
          <button
            onClick={() => {
              onReport();
              setShowMenu(false);
            }}
            className="font-mono text-[10px] text-glitch-red/60 hover:text-glitch-red uppercase tracking-wider transition-colors"
          >
            {t('report.submit')}
          </button>
        </div>
      )}
    </div>
  );
}

function formatTimeAgo(dateString: string): string {
  const now = Date.now();
  const date = new Date(dateString).getTime();
  const diff = now - date;

  const minutes = Math.floor(diff / 60_000);
  if (minutes < 1) return 'now';
  if (minutes < 60) return `${minutes}m`;

  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h`;

  const days = Math.floor(hours / 24);
  return `${days}d`;
}
