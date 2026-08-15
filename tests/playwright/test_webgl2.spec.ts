import { test, expect } from '@playwright/test';

test('verify load errors', async ({ page }) => {
    page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
    page.on('pageerror', error => console.log('BROWSER ERROR:', error.message));

    await page.goto('http://localhost:8080/index.html');
    await page.waitForTimeout(5000);
});
