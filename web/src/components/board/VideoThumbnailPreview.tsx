'use client';

import { useState, useEffect } from 'react';
import { Play } from 'lucide-react';
import { extractVideoFrameFromUrl } from '@/lib/media/thumbnail';

interface VideoThumbnailPreviewProps {
  objectUrl: string;
  className?: string;
}

/**
 * 동영상 0.5초 프레임 썸네일 + 재생 오버레이
 * PostImageGallery / MarkdownContent 공용
 */
export default function VideoThumbnailPreview({
  objectUrl,
  className = '',
}: VideoThumbnailPreviewProps) {
  const [thumbSrc, setThumbSrc] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    extractVideoFrameFromUrl(objectUrl)
      .then((src) => { if (!cancelled) setThumbSrc(src); })
      .catch(() => { /* 실패 시 플레이스홀더 유지 */ });
    return () => { cancelled = true; };
  }, [objectUrl]);

  return (
    <div className={`relative w-full h-full ${className}`}>
      {thumbSrc ? (
        <img
          src={thumbSrc}
          alt=""
          className="w-full h-full object-contain"
          draggable={false}
        />
      ) : (
        <div className="w-full h-full bg-ink/10 flex items-center justify-center">
          <div className="w-8 h-8 border-2 border-ink/20 border-t-signal-green rounded-full animate-spin" />
        </div>
      )}
      <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
        <div className="w-10 h-10 rounded-full bg-void-black/60 flex items-center justify-center">
          <Play className="w-5 h-5 text-white" />
        </div>
      </div>
    </div>
  );
}
