/**
 * updateGroupParticipantCount 로직 검증
 *
 * Server Action이라 직접 호출이 어려우므로,
 * Supabase client를 mock하여 올바른 쿼리가 생성되는지 검증합니다.
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Supabase 체이닝 mock
function createMockChain() {
  const calls: { method: string; args: unknown[] }[] = [];
  const chain: Record<string, (...args: unknown[]) => typeof chain> = {};
  for (const method of ['from', 'update', 'eq', 'neq', 'select', 'single']) {
    chain[method] = (...args: unknown[]) => {
      calls.push({ method, args });
      return chain;
    };
  }
  return { chain, calls };
}

// createServerSupabase mock
const mockChain = createMockChain();
vi.mock('@/lib/supabase/server', () => ({
  createServerSupabase: () => mockChain.chain,
}));

// Server Action에서 headers()를 사용하므로 mock
vi.mock('next/headers', () => ({
  headers: () => new Map([['x-forwarded-for', '127.0.0.1']]),
}));

// rate-limit mock
vi.mock('@/lib/rate-limit', () => ({
  checkRateLimit: async () => ({ allowed: true }),
  getClientIp: () => '127.0.0.1',
}));

describe('updateGroupParticipantCount', () => {
  beforeEach(() => {
    mockChain.calls.length = 0;
  });

  it('count > 0일 때 status를 active로 설정', async () => {
    // dynamic import로 server action 가져오기
    const { updateGroupParticipantCount } = await import('../actions');
    await updateGroupParticipantCount('room-123', 3, 'hash-abc');

    const updateCall = mockChain.calls.find((c) => c.method === 'update');
    expect(updateCall).toBeDefined();

    const updatePayload = updateCall!.args[0] as Record<string, unknown>;
    expect(updatePayload.status).toBe('active');
    expect(updatePayload.participant_count).toBe(3);
  });

  it('count === 0일 때 status를 waiting으로 설정 (destroyed가 아님)', async () => {
    const { updateGroupParticipantCount } = await import('../actions');
    await updateGroupParticipantCount('room-123', 0, 'hash-abc');

    const updateCall = mockChain.calls.find((c) => c.method === 'update');
    expect(updateCall).toBeDefined();

    const updatePayload = updateCall!.args[0] as Record<string, unknown>;
    expect(updatePayload.status).toBe('waiting');
    expect(updatePayload.status).not.toBe('destroyed');
    expect(updatePayload.participant_count).toBe(0);
  });

  it('음수 count도 0으로 클램핑', async () => {
    const { updateGroupParticipantCount } = await import('../actions');
    await updateGroupParticipantCount('room-123', -1, 'hash-abc');

    const updateCall = mockChain.calls.find((c) => c.method === 'update');
    const updatePayload = updateCall!.args[0] as Record<string, unknown>;
    expect(updatePayload.participant_count).toBe(0);
    expect(updatePayload.status).toBe('waiting');
  });

  it('destroyed 상태인 방은 업데이트하지 않음 (neq 가드)', async () => {
    const { updateGroupParticipantCount } = await import('../actions');
    await updateGroupParticipantCount('room-123', 2, 'hash-abc');

    const neqCall = mockChain.calls.find((c) => c.method === 'neq');
    expect(neqCall).toBeDefined();
    expect(neqCall!.args).toEqual(['status', 'destroyed']);
  });

  it('type=group 필터가 적용됨', async () => {
    const { updateGroupParticipantCount } = await import('../actions');
    await updateGroupParticipantCount('room-123', 1, 'hash-abc');

    const eqCalls = mockChain.calls.filter((c) => c.method === 'eq');
    const typeFilter = eqCalls.find((c) => c.args[0] === 'type');
    expect(typeFilter).toBeDefined();
    expect(typeFilter!.args[1]).toBe('group');
  });

  it('authKeyHash가 빈 문자열이면 early return', async () => {
    const { updateGroupParticipantCount } = await import('../actions');
    await updateGroupParticipantCount('room-123', 1, '');

    const updateCall = mockChain.calls.find((c) => c.method === 'update');
    expect(updateCall).toBeUndefined();
  });
});
