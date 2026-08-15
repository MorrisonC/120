import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './',
  timeout: 60000,
  expect: {
    timeout: 5000
  },
  use: {
    headless: true, // We MUST use headless true or else playwright rendering with xvfb on this image seems completely broken for webgl.
    actionTimeout: 0,
    trace: 'on-first-retry',
    launchOptions: {
      args: [
        '--use-gl=angle',
        '--use-angle=swiftshader',
        '--enable-unsafe-swiftshader',
        '--enable-webgl',
        '--ignore-gpu-blocklist',
        '--disable-gpu-sandbox',
        '--autoplay-policy=no-user-gesture-required',
        '--window-size=1280,720'
      ]
    },
    viewport: { width: 1280, height: 720 },
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
