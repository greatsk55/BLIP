import { test, expect } from '@playwright/test';

test('메인 페이지 로드', async ({ page }) => {
  await page.goto('/en');
  await expect(page).toHaveTitle(/BLIP/i);
});

test('"그룹 채팅 만들기" 링크 존재', async ({ page }) => {
  await page.goto('/en');
  // Hero 또는 네비게이션에 그룹 채팅 관련 링크가 있는지 확인
  const groupLink = page.locator('a[href*="group"]').first();
  await expect(groupLink).toBeVisible({ timeout: 10_000 });
});
