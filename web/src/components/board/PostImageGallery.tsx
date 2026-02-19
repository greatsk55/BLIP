'use client';

import { useState } from 'react';
import { Play } from 'lucide-react';
import type { DecryptedPostImage } from '@/types/board';
import ImageViewer from '@/components/chat/ImageViewer';

interface PostImageGalleryProps {
  images: DecryptedPostImage[];
}

function isVideoMime(mimeType: string): boolean {
  return mimeType.startsWith('video/');
}

/**
 * 게시글 미디어 갤러리
 * 1장: 전체 너비 / 2장: 2열 / 3장: 1+2 / 4장: 2×2 그리드
 * 이미지 클릭 → ImageViewer 풀스크린
 * 동영상 클릭 → 인라인 재생 or 풀스크린 비디어 뷰어
 */
export default function PostImageGallery({ images }: PostImageGalleryProps) {
  const [viewerSrc, setViewerSrc] = useState<string | null>(null);
  const [viewerIsVideo, setViewerIsVideo] = useState(false);

  if (images.length === 0) return null;

  const handleMediaClick = (img: DecryptedPostImage) => {
    setViewerSrc(img.objectUrl);
    setViewerIsVideo(isVideoMime(img.mimeType));
  };

  // 1장: 원본 비율 유지, 2+장: 2열 그리드 + aspect-ratio 기반
  const isSingle = images.length === 1;

  return (
    <>
      <div className={isSingle ? 'mt-2' : 'mt-2 grid grid-cols-2 gap-1'}>
        {images.map((img) => {
          const ratio = getAspectRatio(img);
          const isVideo = isVideoMime(img.mimeType);

          return (
            <button
              key={img.id}
              onClick={() => handleMediaClick(img)}
              className={`relative overflow-hidden rounded-sm bg-ink/5 ${
                isSingle ? 'w-full max-w-md' : ''
              }`}
              style={{ aspectRatio: ratio }}
            >
              {isVideo ? (
                <div className="relative w-full h-full">
                  <video
                    src={img.objectUrl}
                    className="w-full h-full object-contain"
                    muted
                    playsInline
                    preload="metadata"
                  />
                  <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                    <div className="w-10 h-10 rounded-full bg-void-black/60 flex items-center justify-center">
                      <Play className="w-5 h-5 text-white" />
                    </div>
                  </div>
                </div>
              ) : (
                <img
                  src={img.objectUrl}
                  alt=""
                  className="w-full h-full object-contain"
                  draggable={false}
                />
              )}
            </button>
          );
        })}
      </div>

      {/* 이미지 뷰어 */}
      {viewerSrc && !viewerIsVideo && (
        <ImageViewer src={viewerSrc} onClose={() => setViewerSrc(null)} />
      )}

      {/* 동영상 풀스크린 뷰어 */}
      {viewerSrc && viewerIsVideo && (
        <div
          className="fixed inset-0 z-200 bg-void-black/95 flex items-center justify-center"
          onClick={() => setViewerSrc(null)}
        >
          <video
            src={viewerSrc}
            className="max-w-full max-h-full"
            controls
            autoPlay
            playsInline
            onClick={(e) => e.stopPropagation()}
          />
        </div>
      )}
    </>
  );
}

/** 이미지/동영상 메타데이터에서 비율 계산. 없으면 기본 4/3 */
function getAspectRatio(img: DecryptedPostImage): string {
  if (img.width && img.height && img.width > 0 && img.height > 0) {
    return `${img.width} / ${img.height}`;
  }
  return '4 / 3';
}
