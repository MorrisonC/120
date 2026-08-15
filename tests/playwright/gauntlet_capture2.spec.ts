import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

test.describe('120 Gauntlet Capture Debug', () => {
    let cycleDir = '';

    test.beforeAll(() => {
        let cycle = 1;
        while (fs.existsSync(path.join(__dirname, '..', '..', 'gauntlet_runs', `cycle_${cycle.toString().padStart(2, '0')}`))) {
            cycle++;
        }
        cycleDir = path.join(__dirname, '..', '..', 'gauntlet_runs', `cycle_${cycle.toString().padStart(2, '0')}`);
        fs.mkdirSync(cycleDir, { recursive: true });
    });

    test('capture all required states', async ({ page }) => {
        page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
        page.on('pageerror', error => console.log('BROWSER ERROR:', error.message));

        await page.goto('http://localhost:8080/index.html');

        const canvas = page.locator('#canvas');
        await expect(canvas).toBeVisible({ timeout: 15000 });

        await page.waitForTimeout(5000);
        await page.screenshot({ path: path.join(cycleDir, '01_title_screen.png') });

        // Force godot to process mouse click properly in webgl using dispatchEvent if mouse click hangs
        await page.evaluate(() => {
            const ev = new MouseEvent('click', { view: window, bubbles: true, cancelable: true });
            document.getElementById('canvas').dispatchEvent(ev);
            document.getElementById('canvas').focus();
        });

        await page.waitForTimeout(2000);

        const sendCommand = async (cmd: string) => {
            await page.evaluate(`window.testBridgeCommand = '${cmd}'`);
            await page.waitForTimeout(500);
        };

        await sendCommand('seed:1');
        await page.waitForTimeout(1000);
        await page.screenshot({ path: path.join(cycleDir, '02_world_seed_1.png') });

        await sendCommand('seed:42');
        await page.waitForTimeout(1000);
        await page.screenshot({ path: path.join(cycleDir, '03_world_seed_42.png') });
    });
});
