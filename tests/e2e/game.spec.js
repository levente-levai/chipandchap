import { expect, test } from '@playwright/test';

test('game boots and player can move right', async ({ page }) => {
  await page.goto('/');

  await page.waitForFunction(() => window.__chipChap?.ready === true);

  const before = await page.evaluate(() => window.__chipChap.player.x);
  await page.keyboard.down('ArrowRight');
  await page.waitForTimeout(300);
  await page.keyboard.up('ArrowRight');

  const after = await page.evaluate(() => window.__chipChap.player.x);
  expect(after).toBeGreaterThan(before + 1);
});
