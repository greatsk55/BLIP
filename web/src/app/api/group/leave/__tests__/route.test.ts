/**
 * /api/group/leave API route 테스트
 *
 * 그룹채팅 퇴장 시 status가 'waiting'으로 설정되는지 검증
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Supabase mock
let mockRoom: Record<string, unknown> | null = null;
let lastUpdate: Record<string, unknown> | null = null;

const mockSupabaseChain = {
  from: () => mockSupabaseChain,
  select: () => mockSupabaseChain,
  update: (data: Record<string, unknown>) => {
    lastUpdate = data;
    return mockSupabaseChain;
  },
  eq: () => mockSupabaseChain,
  neq: () => mockSupabaseChain,
  single: () => Promise.resolve({ data: mockRoom, error: null }),
};

vi.mock('@/lib/supabase/server', () => ({
  createServerSupabase: () => mockSupabaseChain,
}));

vi.mock('@/lib/rate-limit', () => ({
  checkRateLimit: async () => ({ allowed: true }),
  getClientIp: () => '127.0.0.1',
}));

vi.mock('@/lib/api-utils', () => ({
  parseJsonBody: async (req: Request) => req.json(),
  isString: (v: unknown) => typeof v === 'string' && v.length > 0,
}));

// route handler import
import { POST } from '../route';

function makeRequest(body: Record<string, unknown>) {
  return new Request('http://localhost/api/group/leave', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('/api/group/leave', () => {
  beforeEach(() => {
    lastUpdate = null;
    mockRoom = {
      participant_count: 3,
      status: 'active',
      auth_key_hash: 'valid-hash',
      type: 'group',
    };
  });

  it('참여자 3→2: status가 active로 유지', async () => {
    const res = await POST(makeRequest({ roomId: 'r1', authKeyHash: 'valid-hash' }));
    const json = await res.json();

    expect(json.ok).toBe(true);
    expect(lastUpdate).toBeDefined();
    expect(lastUpdate!.status).toBe('active');
    expect(lastUpdate!.participant_count).toBe(2);
  });

  it('참여자 1→0: status가 waiting (destroyed가 아님)', async () => {
    mockRoom!.participant_count = 1;

    const res = await POST(makeRequest({ roomId: 'r1', authKeyHash: 'valid-hash' }));
    const json = await res.json();

    expect(json.ok).toBe(true);
    expect(lastUpdate).toBeDefined();
    expect(lastUpdate!.status).toBe('waiting');
    expect(lastUpdate!.status).not.toBe('destroyed');
    expect(lastUpdate!.participant_count).toBe(0);
  });

  it('이미 destroyed인 방은 업데이트하지 않음', async () => {
    mockRoom!.status = 'destroyed';

    const res = await POST(makeRequest({ roomId: 'r1', authKeyHash: 'valid-hash' }));
    const json = await res.json();

    expect(json.ok).toBe(true);
    // destroyed 방은 early return하므로 update가 호출되지 않음
    expect(lastUpdate).toBeNull();
  });

  it('잘못된 authKeyHash는 401 반환', async () => {
    const res = await POST(makeRequest({ roomId: 'r1', authKeyHash: 'wrong-hash' }));
    expect(res.status).toBe(401);
  });

  it('group 타입이 아닌 방은 무시', async () => {
    mockRoom!.type = 'chat';

    const res = await POST(makeRequest({ roomId: 'r1', authKeyHash: 'valid-hash' }));
    const json = await res.json();

    expect(json.ok).toBe(true);
    expect(lastUpdate).toBeNull();
  });
});
