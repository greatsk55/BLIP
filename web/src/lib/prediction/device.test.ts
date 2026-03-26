/**
 * Device fingerprint 유닛 테스트
 */
import { describe, it, expect } from 'vitest';
import { generateDeviceFingerprint, hashFingerprint } from './device';

describe('generateDeviceFingerprint', () => {
  it('동일 입력 -> 동일 해시', async () => {
    const components = {
      hardwareConcurrency: 8,
      deviceMemory: 16,
      screenWidth: 1920,
      screenHeight: 1080,
      colorDepth: 24,
      timezone: 'Asia/Seoul',
      language: 'ko-KR',
      userAgent: 'Mozilla/5.0',
    };
    const fp1 = await generateDeviceFingerprint(components);
    const fp2 = await generateDeviceFingerprint(components);
    expect(fp1).toBe(fp2);
  });

  it('다른 입력 -> 다른 해시', async () => {
    const fp1 = await generateDeviceFingerprint({
      hardwareConcurrency: 8,
      screenWidth: 1920,
      language: 'ko-KR',
    });
    const fp2 = await generateDeviceFingerprint({
      hardwareConcurrency: 4,
      screenWidth: 1440,
      language: 'en-US',
    });
    expect(fp1).not.toBe(fp2);
  });

  it('결과는 64자 hex 문자열', async () => {
    const fp = await generateDeviceFingerprint({
      hardwareConcurrency: 8,
      timezone: 'UTC',
    });
    expect(fp).toMatch(/^[0-9a-f]{64}$/);
  });

  it('빈 컴포넌트도 유효한 해시 반환', async () => {
    const fp = await generateDeviceFingerprint({});
    expect(fp).toMatch(/^[0-9a-f]{64}$/);
  });
});

describe('hashFingerprint', () => {
  it('SHA-256 해시 반환 (64자 hex)', async () => {
    const hash = await hashFingerprint('test-input');
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
  });

  it('동일 입력 = 동일 해시', async () => {
    const h1 = await hashFingerprint('same-value');
    const h2 = await hashFingerprint('same-value');
    expect(h1).toBe(h2);
  });

  it('다른 입력 = 다른 해시', async () => {
    const h1 = await hashFingerprint('value-a');
    const h2 = await hashFingerprint('value-b');
    expect(h1).not.toBe(h2);
  });
});
