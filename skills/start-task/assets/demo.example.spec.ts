// EXAMPLE demo script (Playwright Test). Copy to the demo folder from AGENTS.md → Demo as <slug>.demo.spec.ts.
// Records a video of the AC scenarios; also an E2E test. Rules: see demo.md.
// Run: .agents/skills/start-task/assets/demo.sh <file>   → .demo/<slug>.webm, .demo/AC-<n>.png
import { test, expect, type Page } from '@playwright/test';

const SLUG = '<task-slug>';
const OUT = '.demo';
const BASE_URL = process.env.DEMO_BASE_URL ?? 'http://localhost:8001'; // this worktree's port

test.use({ launchOptions: { slowMo: 250 } }); // slow enough for a human to follow

// On-screen caption. Call again after every navigation (a new page drops it).
async function caption(page: Page, text: string) {
  await page.evaluate((t) => {
    let el = document.getElementById('__demo_caption');
    if (!el) {
      el = document.createElement('div');
      el.id = '__demo_caption';
      el.setAttribute(
        'style',
        'position:fixed;left:16px;bottom:16px;z-index:2147483647;padding:8px 12px;border-radius:6px;' +
          'background:rgba(0,0,0,.8);color:#fff;font:14px/1.4 system-ui,sans-serif;pointer-events:none',
      );
      document.body.appendChild(el);
    }
    el.textContent = t;
  }, text);
  await page.waitForTimeout(800);
}

test(`demo: ${SLUG}`, async ({ browser }) => {
  const size = { width: 1280, height: 720 };
  const context = await browser.newContext({ baseURL: BASE_URL, viewport: size, recordVideo: { dir: OUT, size } });
  const page = await context.newPage();

  try {
    // AC-1: <observable behavior from the task file>
    await page.goto('/');
    await caption(page, 'AC-1: <short description>');
    // ...steps using demo data only, e.g.:
    // await page.getByLabel('Email').fill(process.env.DEMO_USER ?? 'demo@example.com');
    // await page.getByRole('button', { name: 'Sign in' }).click();
    // await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
    // Screenshot the relevant element rather than the full page (fewer tokens for the reviewer):
    await page.locator('body').screenshot({ path: `${OUT}/AC-1.png` });

    // AC-2: ...
  } finally {
    const video = page.video();
    await context.close(); // finalizes the video
    await video?.saveAs(`${OUT}/${SLUG}.webm`);
    await video?.delete();
  }
});
