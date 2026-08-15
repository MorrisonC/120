import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

test.describe('120 Gauntlet Capture', () => {
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
        page.on('console', msg => console.log(`[Browser] ${msg.type()}: ${msg.text()}`));

        await page.goto('http://127.0.0.1:8080/index.html');

        await page.waitForFunction(() => window['godotEngineReady'] === true, undefined, { timeout: 30000 });

        const canvas = page.locator('#canvas');
        await expect(canvas).toBeVisible({ timeout: 15000 });

        const capture = async (filename: string) => {
            const el = await page.$('#canvas');
            if (el) {
                await el.screenshot({ path: path.join(cycleDir, filename), omitBackground: true });
            } else {
                await page.screenshot({ path: path.join(cycleDir, filename) });
            }
        };

        await page.waitForTimeout(3000);
        await capture('01_title_screen.png');

        const runCommand = async (cmd: string) => {
            await page.evaluate(`
              window.testBridgeAck = false;
              window.testBridgeCommand = "${cmd}";
            `);
            await page.waitForFunction('window.testBridgeAck === true', undefined, { timeout: 15000 });
            await page.waitForTimeout(500); // Give it just a bit more time to finish rendering the result
        };

        await runCommand("start");
        await page.waitForTimeout(2000);
        await runCommand("seed:1");
        await page.waitForTimeout(2000);
        await capture('02_world_seed_1.png');

        await runCommand("seed:42");
        await page.waitForTimeout(2000);
        await capture('03_world_seed_42.png');

        await runCommand("seed:1");
        await page.waitForTimeout(2000);

        await canvas.focus();
        await page.keyboard.down('D');
        await page.waitForTimeout(500);
        await page.keyboard.up('D');
        await page.waitForTimeout(500);
        await capture('04_player_movement.png');

        await runCommand("teleport:B");
        await page.waitForTimeout(2000);
        await capture('05_enemy_encounter.png');

        await runCommand("give_item:Machete");
        await runCommand("give_item:Boots");
        await page.waitForTimeout(1000);
        await capture('06_inventory_partial.png');

        await runCommand("give_item:Grapple");
        await runCommand("give_item:Valve");
        await runCommand("give_item:Mirror");
        await page.waitForTimeout(1000);
        await capture('07_inventory_full.png');

        await runCommand("teleport:C");
        await page.waitForTimeout(1000);
        await runCommand("teleport:F");
        await page.waitForTimeout(1000);
        await capture('08_minimap_updated.png');

        await runCommand("time_warn");
        await page.waitForTimeout(1000);
        await capture('09_hud_time_warning.png');

        await runCommand("time_kill");
        await page.waitForTimeout(2000);
        await capture('10_summary_timeout.png');

        await runCommand("dismiss_summary");
        await page.waitForTimeout(1000);
        await runCommand("touch_enemy");
        await page.waitForTimeout(2000);
        await capture('11_summary_enemy_death.png');

        await runCommand("dismiss_summary");
        await page.waitForTimeout(1000);
        await capture('12_respawned_state.png');
    });
});
