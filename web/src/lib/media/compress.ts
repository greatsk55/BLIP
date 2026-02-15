const MAX_DIMENSION = 2048;
const JPEG_QUALITY = 0.8;
const THUMBNAIL_MAX_DIMENSION = 320;
const THUMBNAIL_QUALITY = 0.6;

interface CompressResult {
  blob: Blob;
  width: number;
  height: number;
}

/**
 * 이미지를 리사이즈 + JPEG 압축
 * GIF는 애니메이션 유지를 위해 압축하지 않음
 */
export async function compressImage(
  file: File,
  maxDimension = MAX_DIMENSION,
  quality = JPEG_QUALITY
): Promise<CompressResult> {
  // GIF는 원본 유지 (애니메이션)
  if (file.type === 'image/gif') {
    const { width, height } = await getImageDimensions(file);
    return { blob: file, width, height };
  }

  const bitmap = await createImageBitmap(file);
  const { width, height } = fitDimensions(
    bitmap.width,
    bitmap.height,
    maxDimension
  );

  const canvas = new OffscreenCanvas(width, height);
  const ctx = canvas.getContext('2d');
  if (!ctx) throw new Error('Canvas 2D context unavailable');

  ctx.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  const blob = await canvas.convertToBlob({
    type: 'image/jpeg',
    quality,
  });

  return { blob, width, height };
}

/**
 * 이미지 섬네일 생성 (미리보기 + 메시지 버블용)
 */
export async function createImageThumbnail(file: File): Promise<CompressResult> {
  return compressImage(file, THUMBNAIL_MAX_DIMENSION, THUMBNAIL_QUALITY);
}

/**
 * 종횡비 유지하면서 최대 크기에 맞추기
 */
function fitDimensions(
  origWidth: number,
  origHeight: number,
  maxDimension: number
): { width: number; height: number } {
  if (origWidth <= maxDimension && origHeight <= maxDimension) {
    return { width: origWidth, height: origHeight };
  }

  const ratio = Math.min(maxDimension / origWidth, maxDimension / origHeight);
  return {
    width: Math.round(origWidth * ratio),
    height: Math.round(origHeight * ratio),
  };
}

/**
 * 이미지 파일에서 원본 크기 가져오기
 */
function getImageDimensions(
  file: File
): Promise<{ width: number; height: number }> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve({ width: img.naturalWidth, height: img.naturalHeight });
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Failed to load image'));
    };
    img.src = url;
  });
}
