'use client';

import { useState } from 'react';
import type { DecryptedPostImage } from '@/types/board';
import ImageViewer from '@/components/chat/ImageViewer';

interface PostImageGalleryProps {
  images: DecryptedPostImage[];
}

/**
 * 게시글 이미지 갤러리
 * 1장: 전체 너비 / 2장: 2열 / 3장: 1+2 / 4장: 2×2 그리드
 * 클릭 시 ImageViewer (chat 재사용) 풀스크린 표시
 */
export default function PostImageGallery({ images }: PostImageGalleryProps) {
  const [viewerSrc, setViewerSrc] = useState<string | null>(null);


  if (images.length === 0) return null;

  const gridClass = getGridClass(images.length);

  return (
    <>
      <div className={`mt-2 gap-1 ${gridClass}`}>
        {images.map((img, i) => (
          <button
            key={img.id}
            onClick={() => setViewerSrc(img.objectUrl)}
            className={`relative overflow-hidden bg-ink/5 ${getItemClass(images.length, i)}`}
          >
            <img
              src={img.objectUrl}
              alt=""
              className="w-full h-auto object-contain"
              draggable={false}
            />
          </button>
        ))}
      </div>

      <ImageViewer src={viewerSrc} onClose={() => setViewerSrc(null)} />
    </>
  );
}

function getGridClass(count: number): string {
  if (count === 1) return 'grid grid-cols-1';
  if (count === 2) return 'grid grid-cols-2';
  if (count === 3) return 'grid grid-cols-2 grid-rows-2';
  return 'grid grid-cols-2 grid-rows-2'; // 4장
}

function getItemClass(count: number, index: number): string {
  const base = 'rounded-sm';
  if (count === 1) return `${base} max-h-[300px]`;
  if (count === 3 && index === 0) return `${base} row-span-2 h-[200px]`;
  if (count === 3) return `${base} h-[98px]`;
  return `${base} h-[120px]`; // 2장 또는 4장
}
