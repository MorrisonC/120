import { test, expect } from '@playwright/test';

test('verify WebGL2 capability', async ({ page }) => {
    page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
    page.on('pageerror', error => console.log('BROWSER ERROR:', error.message));

    await page.goto('http://localhost:8080/index.html');

    const result = await page.evaluate(() => {
        const canvas = document.createElement('canvas');
        const gl = canvas.getContext('webgl2');
        if (gl) {
            return { available: true, renderer: gl.getParameter(gl.RENDERER) };
        }
        return { available: false, renderer: null };
    });
    console.log('WebGL2 available:', result);
});
