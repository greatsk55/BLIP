'use client';

import { ImageIcon, Film } from 'lucide-react';
import { useTranslations } from 'next-intl';
import type { DecryptedPost } from '@/types/board';

interface PostCardProps {
  post: DecryptedPost;
  onClick: () => void;
}

export default function PostCard({ post, onClick }: PostCardProps) {
  const t = useTranslations('Board');

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

  // 본문 미리보기 (마크다운 제거, 최대 120자)
  const preview = stripMarkdown(post.content).slice(0, 120);
  const mediaInfo = getMediaInfo(post);

  return (
    <button
      type="button"
      onClick={onClick}
      className={`w-full text-left border px-4 py-3 transition-colors cursor-pointer ${
        post.isMine
          ? 'border-signal-green/10 bg-signal-green/[0.02] hover:bg-signal-green/[0.04]'
          : 'border-ink/5 bg-ink/[0.01] hover:bg-ink/[0.03]'
      }`}
    >
      {/* 1행: 작성자 + 시간 */}
      <div className="flex items-center gap-2 mb-1.5">
        <span
          className={`font-mono text-[10px] uppercase tracking-wider ${
            post.isMine ? 'text-signal-green' : 'text-ghost-grey/60'
          }`}
        >
          {post.authorName}
        </span>
        <span className="font-mono text-[9px] text-ghost-grey/60">
          {timeAgo}
        </span>
      </div>

      {/* 2행: 제목 */}
      {post.title && (
        <p className="font-mono text-sm font-bold text-ink line-clamp-1 mb-1">
          {post.title}
        </p>
      )}

      {/* 3행: 본문 미리보기 */}
      {preview && (
        <p className="font-mono text-xs text-ink/70 leading-relaxed line-clamp-2 mb-1">
          {preview}
        </p>
      )}

      {/* 3행: 미디어 인디케이터 */}
      {mediaInfo.hasMedia && (
        <div className="flex items-center gap-1 mt-1.5">
          {mediaInfo.hasVideo ? (
            <Film className="w-3 h-3 text-ghost-grey/60" />
          ) : (
            <ImageIcon className="w-3 h-3 text-ghost-grey/60" />
          )}
          <span className="font-mono text-[9px] text-ghost-grey/60 uppercase tracking-wider">
            {mediaInfo.hasVideo ? 'Video' : 'Image'}
          </span>
        </div>
      )}
    </button>
  );
}

/** 마크다운 문법 제거 → 플레인 텍스트 미리보기 */
function stripMarkdown(text: string): string {
  return text
    .replace(/!\[[^\]]*\]\(img:\d+\)/g, '') // inline image refs
    .replace(/#{1,6}\s/g, '')           // headings
    .replace(/\*\*(.+?)\*\*/g, '$1')    // bold
    .replace(/\*(.+?)\*/g, '$1')        // italic
    .replace(/`{1,3}[^`]*`{1,3}/g, '')  // code
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1') // links
    .replace(/>\s?/g, '')               // blockquote
    .replace(/[-*+]\s/g, '')            // list
    .replace(/\n+/g, ' ')              // newlines → space
    .trim();
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

/** 미디어 정보 판별: 이미지/동영상 여부 */
function getMediaInfo(post: DecryptedPost): { hasMedia: boolean; hasVideo: boolean } {
  const allMedia = [
    ...post.images,
    ...(post._encryptedImages ?? []),
  ];
  if (allMedia.length === 0) return { hasMedia: false, hasVideo: false };
  const hasVideo = allMedia.some((m) => m.mimeType.startsWith('video/'));
  return { hasMedia: true, hasVideo };
}
