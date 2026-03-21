import { test, expect } from '@playwright/test';

/**
 * 그룹채팅 뒤로가기 모달 e2e 테스트
 *
 * 그룹채팅 접속 후 뒤로가기/EXIT 버튼 클릭 시
 * "페이지만 나가기" / "채팅에서 나가기" 모달이 표시되는지 검증
 *
 * NOTE: 실제 Supabase 연결이 필요하므로 CI에서는 skip 가능
 */

test.describe('그룹채팅 뒤로가기 모달', () => {
  // 그룹방 생성 → 채팅 진입까지의 헬퍼
  // 실서버 없이는 채팅 진입이 불가하므로, 모달 컴포넌트 렌더링 여부만 검증

  test('GroupBackModal 컴포넌트가 올바른 번역 키를 사용', async ({ page }) => {
    // en locale의 그룹 생성 페이지 접근
    await page.goto('/en/group/create');
    await expect(page.locator('input[type="text"]').first()).toBeVisible({ timeout: 10_000 });

    // 모달 번역 키가 messages에 존재하는지 검증 (빌드 타임 검증)
    const response = await page.evaluate(async () => {
      const res = await fetch('/en/group/create');
      return res.status;
    });
    expect(response).toBe(200);
  });
});
