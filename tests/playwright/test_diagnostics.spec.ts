import { test, expect } from '@playwright/test';

test('diagnose godot startup', async ({ page }) => {
  const logs: string[] = [];
  page.on('console', msg => logs.push(`[${msg.type()}] ${msg.text()} (${msg.location().url})`));
  page.on('pageerror', error => logs.push(`[PAGE ERROR] ${error.message}`));
  page.on('requestfailed', request => logs.push(`[REQUEST FAILED] ${request.url()} - ${request.failure()?.errorText}`));
  page.on('response', response => {
      if (response.status() >= 400) {
          logs.push(`[RESPONSE FAILED] ${response.url()} - ${response.status()}`);
      }
  });

  await page.goto('http://127.0.0.1:8080/index.html', { waitUntil: 'networkidle' });

  // Wait up to 10 seconds for godotEngineReady or just dump logs
  try {
    await page.waitForFunction(() => window['godotEngineReady'] === true, undefined, { timeout: 15000 });
    console.log("Godot engine ready successfully!");
  } catch (e) {
    console.log("Timed out waiting for godotEngineReady. Logs:");
  }

  for (const log of logs) {
    console.log(log);
  }
});
