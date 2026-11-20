// @vitest-environment node
import { beforeEach, describe, expect, it, vi } from 'vitest';

const mocks = vi.hoisted(() => ({
  upload: vi.fn(), getBucket: vi.fn(), createBucket: vi.fn(),
  single: vi.fn(), allowed: true,
}));
vi.mock('@/lib/supabase/server', () => ({ createServerSupabase: () => ({
  from: () => ({ select: () => ({ eq: () => ({ single: mocks.single }) }) }),
  storage: { getBucket: mocks.getBucket, createBucket: mocks.createBucket,
    from: () => ({ upload: mocks.upload }) },
}) }));
vi.mock('@/lib/rate-limit', () => ({
  checkRateLimit: async () => ({ allowed: mocks.allowed }), getClientIp: () => '192.0.2.1',
}));
import { POST } from '../route';
const request = (body: object) => new Request('https://blip.test/api/safety/report', {
  method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body),
});
const valid = { roomId: 'testroom123', authKeyHash: 'correct-hash', reason: 'harassment' };

describe('explicit safety reports', () => {
  beforeEach(() => {
    vi.resetAllMocks(); mocks.allowed = true;
    vi.stubEnv('SUPABASE_SERVICE_ROLE_KEY', 'test-only-secret');
    mocks.single.mockResolvedValue({ data: { auth_key_hash: valid.authKeyHash } });
    mocks.getBucket.mockResolvedValue({ data: { public: false } });
    mocks.upload.mockResolvedValue({ error: null });
    mocks.createBucket.mockResolvedValue({ error: null });
  });
  it('requires room authorization before storing anything', async () => {
    expect((await POST(request({ ...valid, authKeyHash: 'wrong' }))).status).toBe(401);
    expect(mocks.upload).not.toHaveBeenCalled();
  });
  it('rejects evidence supplied without explicit consent', async () => {
    expect((await POST(request({ ...valid, includeEvidence: false, messages: [] }))).status).toBe(400);
    expect(mocks.upload).not.toHaveBeenCalled();
  });
  it('accepts a report without chat content and never retains credentials or raw IP', async () => {
    expect((await POST(request(valid))).status).toBe(200);
    const saved = JSON.parse(mocks.upload.mock.calls[0][1]);
    expect(saved).not.toHaveProperty('messages');
    expect(saved).not.toHaveProperty('authKeyHash');
    expect(JSON.stringify(saved)).not.toContain('192.0.2.1');
    expect(saved.reporter).toMatch(/^[a-f0-9]{64}$/);
  });
  it('stores only selected evidence fields in a private bucket', async () => {
    mocks.getBucket.mockResolvedValueOnce({ data: null });
    expect((await POST(request({ ...valid, includeEvidence: true,
      messages: [{ content: 'QA evidence', senderName: 'QA', timestamp: 123, password: 'strip-me' }] }))).status).toBe(200);
    expect(mocks.createBucket).toHaveBeenCalledWith('abuse-reports', expect.objectContaining({ public: false }));
    expect(JSON.parse(mocks.upload.mock.calls[0][1]).messages).toEqual([{ content: 'QA evidence', senderName: 'QA', timestamp: 123 }]);
  });
  it('fails closed if the bucket is public or storage fails', async () => {
    mocks.getBucket.mockResolvedValue({ data: { public: true } });
    expect((await POST(request(valid))).status).toBe(503);
    expect(mocks.upload).not.toHaveBeenCalled();
  });
  it('limits report spam and rejects oversized evidence', async () => {
    mocks.allowed = false;
    expect((await POST(request(valid))).status).toBe(429);
    expect((await POST(request({ ...valid, includeEvidence: true,
      messages: [{ content: 'x'.repeat(5001), senderName: 'QA', timestamp: 123 }] }))).status).toBe(400);
  });
});
