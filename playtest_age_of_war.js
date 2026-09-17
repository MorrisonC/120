const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

async function run() {
  console.log("Starting Age of War Playtest...");
  const browser = await chromium.launch({
    headless: true,
    args: ['--use-gl=angle', '--use-stub-gl']
  });
  const context = await browser.newContext();
  const page = await context.newPage();

  page.on('console', msg => console.log('PAGE LOG:', msg.text()));

  await page.goto('http://localhost:8080');
  await page.waitForTimeout(2000);

  console.log("Taking initial game screenshot...");
  await page.screenshot({ path: 'shot_age_of_war_playtest.png' });

  // Check HTML elements or Canvas
  const title = await page.title();
  console.log("Page Title:", title);

  await browser.close();
  console.log("Playtest complete.");
}

run().catch(err => {
  console.error("Playtest failed:", err);
  process.exit(1);
});
