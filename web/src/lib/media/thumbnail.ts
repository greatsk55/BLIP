const VIDEO_THUMBNAIL_TIME = 0.5; // 0.5초 지점 캡처
const VIDEO_THUMBNAIL_MAX = 320;

interface VideoMetadata {
  width: number;
  height: number;
  duration: number;
}

/**
 * 동영상 첫 프레임 섬네일 + 메타데이터 추출
 */
export async function createVideoThumbnail(
  file: File
): Promise<{ thumbnail: Blob; metadata: VideoMetadata }> {
  const url = URL.createObjectURL(file);

  try {
    const { video, metadata } = await loadVideoMetadata(url);
    const thumbnail = await captureVideoFrame(video);
    return { thumbnail, metadata };
  } finally {
    URL.revokeObjectURL(url);
  }
}

/**
 * 동영상 메타데이터 로드
 */
function loadVideoMetadata(
  url: string
): Promise<{ video: HTMLVideoElement; metadata: VideoMetadata }> {
  return new Promise((resolve, reject) => {
    const video = document.createElement('video');
    video.preload = 'metadata';
    video.muted = true;
    video.playsInline = true;

    video.onloadedmetadata = () => {
      const metadata: VideoMetadata = {
        width: video.videoWidth,
        height: video.videoHeight,
        duration: video.duration,
      };

      // 프레임 캡처를 위해 특정 시점으로 이동
      video.currentTime = Math.min(VIDEO_THUMBNAIL_TIME, video.duration / 2);
    };

    video.onseeked = () => {
      resolve({
        video,
        metadata: {
          width: video.videoWidth,
          height: video.videoHeight,
          duration: video.duration,
        },
      });
    };

    video.onerror = () => reject(new Error('Failed to load video'));
    video.src = url;
  });
}

/**
 * 비디오 현재 프레임 캡처 → JPEG Blob
 */
function captureVideoFrame(video: HTMLVideoElement): Promise<Blob> {
  const ratio = Math.min(
    VIDEO_THUMBNAIL_MAX / video.videoWidth,
    VIDEO_THUMBNAIL_MAX / video.videoHeight,
    1
  );
  const width = Math.round(video.videoWidth * ratio);
  const height = Math.round(video.videoHeight * ratio);

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;

  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas 2D context unavailable');

  ctx.drawImage(video, 0, 0, width, height);

  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (blob) resolve(blob);
        else reject(new Error('Failed to capture video frame'));
      },
      'image/jpeg',
      0.6
    );
  });
}

/**
 * blob URL에서 0.5초 프레임 추출 (복호화된 동영상용)
 * board PostDetail / PostImageGallery에서 사용
 */
export function extractVideoFrameFromUrl(objectUrl: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const video = document.createElement('video');
    video.preload = 'auto';
    video.muted = true;
    video.playsInline = true;

    video.onloadedmetadata = () => {
      video.currentTime = Math.min(VIDEO_THUMBNAIL_TIME, video.duration / 2);
    };

    video.onseeked = () => {
      try {
        const ratio = Math.min(
          VIDEO_THUMBNAIL_MAX / video.videoWidth,
          VIDEO_THUMBNAIL_MAX / video.videoHeight,
          1
        );
        const w = Math.round(video.videoWidth * ratio);
        const h = Math.round(video.videoHeight * ratio);

        const canvas = document.createElement('canvas');
        canvas.width = w;
        canvas.height = h;

        const ctx = canvas.getContext('2d');
        if (!ctx) { reject(new Error('No 2D context')); return; }

        ctx.drawImage(video, 0, 0, w, h);
        resolve(canvas.toDataURL('image/jpeg', 0.6));
      } catch (e) {
        reject(e);
      }
    };

    video.onerror = () => reject(new Error('Failed to load video for thumbnail'));
    video.src = objectUrl;
  });
}

/**
 * MIME 타입으로 미디어 종류 판별
 */
export function getMediaType(mimeType: string): 'image' | 'video' | null {
  if (mimeType.startsWith('image/')) return 'image';
  if (mimeType.startsWith('video/')) return 'video';
  return null;
}

/**
 * 파일 크기 검증
 */
export function validateFileSize(
  file: File
): { valid: boolean; maxSize: number } {
  const limits: Record<string, number> = {
    image: 50 * 1024 * 1024,  // 50MB
    video: 100 * 1024 * 1024, // 100MB
  };

  const type = getMediaType(file.type);
  if (!type) return { valid: false, maxSize: 0 };

  const maxSize = limits[type];
  return { valid: file.size <= maxSize, maxSize };
}
