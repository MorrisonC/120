import { test, expect } from '@playwright/test';
import * as fs from 'fs';

test('debug godot canvas rendering', async ({ page }) => {
    page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));

    await page.goto('http://localhost:8080/index.html');
    await page.waitForTimeout(5000);

    const sendCommand = async (cmd: string) => {
        await page.evaluate(`window.testBridgeCommand = '${cmd}'`);
        await page.waitForTimeout(2000);
    };

    await sendCommand('start:');

    const pixels = await page.evaluate(() => {
        const canvas = document.getElementById("canvas") as HTMLCanvasElement;
        const gl = canvas.getContext("webgl2") || canvas.getContext("webgl");
        if (!gl) return "no context";

        const pixels = new Uint8Array(4);
        gl.readPixels(canvas.width / 2, canvas.height / 2, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
        return `Center pixel: R=${pixels[0]}, G=${pixels[1]}, B=${pixels[2]}, A=${pixels[3]}`;
    });

    console.log(pixels);
    await page.screenshot({ path: 'test_webgl3.png' });
});
