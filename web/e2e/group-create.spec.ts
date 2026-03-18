import { test, expect } from '@playwright/test';

test('그룹방 생성 페이지 이동', async ({ page }) => {
  await page.goto('/en/group/create');
  // 페이지가 로드되면 제목 입력 필드가 있어야 함
  const titleInput = page.locator('input[type="text"]').first();
  await expect(titleInput).toBeVisible({ timeout: 10_000 });
});

test('제목 입력 및 이용약관 체크', async ({ page }) => {
  await page.goto('/en/group/create');

  const titleInput = page.locator('input[type="text"]').first();
  await titleInput.fill('Test Group Room');

  // 이용약관 체크박스 찾기
  const checkbox = page.locator('input[type="checkbox"]').first();
  if (await checkbox.isVisible()) {
    await checkbox.check();
    await expect(checkbox).toBeChecked();
  }
});

test('생성 버튼 존재', async ({ page }) => {
  await page.goto('/en/group/create');
  const createButton = page.locator('button[type="submit"], button').filter({ hasText: /create|만들기|生成/i }).first();
  await expect(createButton).toBeVisible({ timeout: 10_000 });
});
