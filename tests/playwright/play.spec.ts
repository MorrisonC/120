import { test, expect } from '@playwright/test';

// We run physical simulations periodically using Playwright
test('Godot Web Build Physical Simulator Run', async ({ page }) => {
  const errors: string[] = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') {
      errors.push(msg.text());
    }
    console.log(`[Browser ${msg.type()}] ${msg.text()}`);
  });

  page.on('pageerror', (err) => {
    errors.push(err.message);
    console.error(`[Browser PageError] ${err.message}`);
  });

  // Navigate to the Godot web build index.html
  await page.goto('/');

  // Look for the canvas element where Godot renders
  const canvas = page.locator('#canvas');
  await expect(canvas).toBeVisible({ timeout: 15000 });

  // Wait a bit for the initial scene to load fully and render a few frames
  await page.waitForTimeout(5000);

  const fatalErrors = errors.filter(e => !e.includes('WebGL') && !e.includes('favicon'));
  expect(fatalErrors.length).toBe(0);

  // Take visual regression screenshots
  await expect(page).toHaveScreenshot('title-screen.png', {
    maxDiffPixelRatio: 0.05, // Allow 5% difference for rendering variations across CI
  });

  // Script 5-10 inputs for physical sim
  await page.keyboard.press('Space');
  await page.waitForTimeout(1000);

  await expect(page).toHaveScreenshot('mid-puzzle.png', {
    maxDiffPixelRatio: 0.05,
  });

  // Simulate more play...
});
