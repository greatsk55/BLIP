import { describe, it, expect } from 'vitest';
import { getMediaType, validateFileSize } from './thumbnail';

describe('getMediaType', () => {
  it('image/* → "image"', () => {
    expect(getMediaType('image/png')).toBe('image');
    expect(getMediaType('image/jpeg')).toBe('image');
    expect(getMediaType('image/gif')).toBe('image');
    expect(getMediaType('image/webp')).toBe('image');
  });

  it('video/* → "video"', () => {
    expect(getMediaType('video/mp4')).toBe('video');
    expect(getMediaType('video/webm')).toBe('video');
  });

  it('application/pdf → "file"', () => {
    expect(getMediaType('application/pdf')).toBe('file');
  });

  it('application/zip → "file"', () => {
    expect(getMediaType('application/zip')).toBe('file');
  });

  it('text/plain → "file"', () => {
    expect(getMediaType('text/plain')).toBe('file');
  });

  it('빈 문자열 → "file"', () => {
    expect(getMediaType('')).toBe('file');
  });
});

describe('validateFileSize', () => {
  function makeFile(size: number, type: string): File {
    const buffer = new ArrayBuffer(0);
    return new File([buffer], 'test', { type });
  }

  it('50MB 이미지는 통과', () => {
    const file = Object.defineProperty(makeFile(0, 'image/png'), 'size', { value: 50 * 1024 * 1024 });
    expect(validateFileSize(file).valid).toBe(true);
  });

  it('51MB 이미지는 실패', () => {
    const file = Object.defineProperty(makeFile(0, 'image/png'), 'size', { value: 51 * 1024 * 1024 });
    expect(validateFileSize(file).valid).toBe(false);
  });

  it('100MB 비디오는 통과', () => {
    const file = Object.defineProperty(makeFile(0, 'video/mp4'), 'size', { value: 100 * 1024 * 1024 });
    expect(validateFileSize(file).valid).toBe(true);
  });

  it('200MB 일반 파일은 통과', () => {
    const file = Object.defineProperty(makeFile(0, 'application/pdf'), 'size', { value: 200 * 1024 * 1024 });
    expect(validateFileSize(file).valid).toBe(true);
  });

  it('201MB 일반 파일은 실패', () => {
    const file = Object.defineProperty(makeFile(0, 'application/pdf'), 'size', { value: 201 * 1024 * 1024 });
    expect(validateFileSize(file).valid).toBe(false);
  });
});
