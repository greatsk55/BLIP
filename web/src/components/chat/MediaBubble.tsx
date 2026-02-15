'use client';

import { useState } from 'react';
import { Play } from 'lucide-react';
import type { DecryptedMessage } from '@/types/chat';
import TransferProgress from './TransferProgress';

interface MediaBubbleProps {
  message: DecryptedMessage;
  onImageClick?: (src: string) => void;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
}

function formatDuration(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, '0')}`;
}

export default function MediaBubble({ message, onImageClick }: MediaBubbleProps) {
  const [videoError, setVideoError] = useState(false);
  const isTransferring = message.transferProgress !== undefined && message.transferProgress < 1;
  const meta = message.mediaMetadata;

  return (
    <div className="relative overflow-hidden rounded-sm">
      {message.type === 'image' && message.mediaUrl && (
        <button
          onClick={() => onImageClick?.(message.mediaUrl!)}
          className="block cursor-pointer"
        >
          <img
            src={message.mediaUrl}
            alt=""
            className="max-w-[280px] sm:max-w-[320px] max-h-[400px] object-cover rounded-sm"
            loading="lazy"
            draggable={false}
          />
        </button>
      )}

      {message.type === 'video' && message.mediaUrl && !videoError && (
        <video
          src={message.mediaUrl}
          controls
          playsInline
          preload="metadata"
          className="max-w-[280px] sm:max-w-[320px] max-h-[400px] rounded-sm"
          onError={() => setVideoError(true)}
        />
      )}

      {message.type === 'video' && videoError && (
        <div className="flex items-center gap-2 px-3 py-2 text-ink/40 font-mono text-xs">
          <Play className="w-4 h-4" />
          <span>VIDEO_LOAD_FAILED</span>
        </div>
      )}

      {/* 파일 메타 정보 */}
      {meta && (
        <div className="flex items-center gap-2 mt-1 font-mono text-[10px] text-ink/20">
          {meta.size > 0 && <span>{formatFileSize(meta.size)}</span>}
          {meta.duration !== undefined && <span>{formatDuration(meta.duration)}</span>}
          {meta.width && meta.height && <span>{meta.width}x{meta.height}</span>}
        </div>
      )}

      {/* 전송 진행률 오버레이 */}
      {isTransferring && (
        <TransferProgress progress={message.transferProgress!} />
      )}
    </div>
  );
}
