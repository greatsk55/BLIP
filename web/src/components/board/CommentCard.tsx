'use client';

import { useState, useEffect, useRef } from 'react';
import { Flag, Trash2, ImageIcon } from 'lucide-react';
import type { DecryptedComment } from '@/types/board';

interface CommentCardProps {
  comment: DecryptedComment;
  onReport: () => void;
  onDelete: () => Promise<{ error?: string }>;
  onAdminDelete?: () => Promise<{ error?: string }>;
  onDecryptImages?: () => Promise<void>;
}

export default function CommentCard({
  comment,
  onReport,
  onDelete,
  onAdminDelete,
  onDecryptImages,
}: CommentCardProps) {
  const [deleting, setDeleting] = useState(false);
  const decryptedRef = useRef(false);

  // 이미지 lazy decryption
  useEffect(() => {
    if (
      !onDecryptImages ||
      comment.isBlinded ||
      comment.images.length > 0 ||
      !comment._encryptedImages?.length ||
      decryptedRef.current
    ) return;
    decryptedRef.current = true;
    onDecryptImages();
  }, [onDecryptImages, comment.isBlinded, comment.images.length, comment._encryptedImages?.length]);

  const handleDelete = async (admin?: boolean) => {
    setDeleting(true);
    if (admin && onAdminDelete) {
      await onAdminDelete();
    } else {
      await onDelete();
    }
    setDeleting(false);
  };

  if (comment.isBlinded) {
    return (
      <div className="px-4 py-2 border-b border-ink/5 opacity-50">
        <span className="font-mono text-[9px] text-glitch-red uppercase tracking-wider">
          BLINDED
        </span>
      </div>
    );
  }

  return (
    <div
      className={`px-4 py-3 border-b border-ink/5 ${
        comment.isMine ? 'bg-signal-green/[0.02]' : ''
      }`}
    >
      {/* 작성자 + 시간 + 액션 */}
      <div className="flex items-center gap-2 mb-1">
        <span
          className={`font-mono text-[10px] uppercase tracking-wider ${
            comment.isMine ? 'text-signal-green' : 'text-ghost-grey/60'
          }`}
        >
          {comment.authorName}
        </span>
        <span className="font-mono text-[9px] text-ghost-grey/40">
          {formatTimeAgo(comment.createdAt)}
        </span>
        <div className="flex-1" />

        {comment.isMine ? (
          <button
            onClick={() => handleDelete()}
            disabled={deleting}
            className="p-1 text-ghost-grey/40 hover:text-glitch-red transition-colors disabled:opacity-50"
          >
            <Trash2 className="w-3 h-3" />
          </button>
        ) : (
          <>
            <button
              onClick={onReport}
              className="p-1 text-ghost-grey/40 hover:text-glitch-red transition-colors"
            >
              <Flag className="w-3 h-3" />
            </button>
            {onAdminDelete && (
              <button
                onClick={() => handleDelete(true)}
                disabled={deleting}
                className="p-1 text-ghost-grey/40 hover:text-glitch-red transition-colors disabled:opacity-50"
              >
                <Trash2 className="w-3 h-3" />
              </button>
            )}
          </>
        )}
      </div>

      {/* 본문 */}
      <p className="font-mono text-xs text-ink/80 leading-relaxed whitespace-pre-wrap break-words">
        {comment.content}
      </p>

      {/* 이미지 */}
      {comment.images.length > 0 && (
        <div className="flex gap-2 mt-2">
          {comment.images.map((img) => (
            <a
              key={img.id}
              href={img.objectUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="block w-20 h-20 border border-ink/10 overflow-hidden"
            >
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={img.objectUrl}
                alt=""
                className="w-full h-full object-cover"
              />
            </a>
          ))}
        </div>
      )}

      {/* 미복호화 이미지 인디케이터 */}
      {comment.images.length === 0 && (comment._encryptedImages?.length ?? 0) > 0 && (
        <div className="flex items-center gap-1 mt-1.5">
          <ImageIcon className="w-3 h-3 text-ghost-grey/40 animate-pulse" />
          <span className="font-mono text-[9px] text-ghost-grey/40">
            Decrypting...
          </span>
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
