// Optional local browser check: node verify-preview.cjs <path-to-playwright>
const { chromium } = require(process.argv[2] || 'playwright');
const { pathToFileURL } = require('url');
const fs = require('fs');
const path = require('path');

(async () => {
  const dir = __dirname;
  const report = JSON.parse(fs.readFileSync(path.join(dir, 'animation.json')));
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 1120, height: 970 }, deviceScaleFactor: 1 });
    const errors = [];
    page.on('pageerror', e => errors.push(String(e)));
    await page.goto(pathToFileURL(path.join(dir, 'index.html')).href);
    await page.getByRole('button', { name: 'Pause animation' }).click();
    let samples = 0;
    for (let loop = 0; loop < 3; loop++) {
      for (const entry of report.timeline) {
        const t = loop * report.durationMs + entry.startMs + entry.durationMs / 2;
        const visible = await page.evaluate(t => {
          const svg = document.querySelector('#cat-animation');
          for (const a of svg.getAnimations({ subtree: true })) { a.pause(); a.currentTime = t; }
          return [...svg.querySelectorAll('.pose')]
            .filter(g => getComputedStyle(g).visibility === 'visible').map(g => g.id);
        }, t);
        if (visible.length !== 1 || visible[0] !== `pose-${entry.pose}`) throw Error(`Visibility ${t}: ${visible}`);
        samples++;
      }
    }
    await page.locator('#scrubber').fill('0');
    await page.screenshot({ path: path.join(dir, 'preview-page.png'), fullPage: true });
    await page.locator('#scrubber').fill('385');
    await page.locator('#cat-animation').screenshot({ path: path.join(dir, 'walk-pose-check.png') });
    await page.getByRole('button', { name: 'Play animation' }).click();
    await page.waitForTimeout(150);
    if (Number(await page.locator('#scrubber').inputValue()) <= 385) throw Error('Playback did not advance');
    await page.getByRole('button', { name: 'Pause animation' }).click();
    await page.locator('#speed').selectOption('0.5');
    const rates = await page.evaluate(() => document.querySelector('#cat-animation')
      .getAnimations({ subtree: true }).map(a => a.playbackRate));
    if (rates.some(r => r !== 0.5)) throw Error('Speed not applied');
    await page.getByRole('button', { name: 'Restart', exact: true }).click();
    if (await page.locator('#scrubber').inputValue() !== '0') throw Error('Restart failed');
    await page.getByRole('button', { name: 'Dark', exact: true }).click();
    await page.getByRole('button', { name: 'Checker', exact: true }).click();
    await page.setViewportSize({ width: 390, height: 844 });
    await page.screenshot({ path: path.join(dir, 'preview-mobile.png'), fullPage: true });
    if (await page.evaluate(() => document.documentElement.scrollWidth > innerWidth)) throw Error('Mobile horizontal overflow');
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.reload();
    if (await page.getByRole('button', { name: 'Play animation' }).count() !== 1) throw Error('Reduced motion did not pause');
    const reduced = await page.evaluate(() => [...document.querySelectorAll('#cat-animation .pose')]
      .filter(g => getComputedStyle(g).visibility === 'visible').map(g => g.id));
    if (reduced.join() !== 'pose-0') throw Error('Reduced motion wrong resting pose');
    await page.getByRole('button', { name: 'Play animation' }).click();
    await page.waitForTimeout(100);
    if (Number(await page.locator('#scrubber').inputValue()) === 0) throw Error('Reduced motion opt-in failed');
    for (const width of [320, 761, 1120]) {
      await page.setViewportSize({ width, height: 970 });
      await page.waitForTimeout(80);
      const sizes = await page.locator('.stage > svg').evaluateAll(svgs => svgs.map(svg => ({
        width: svg.getBoundingClientRect().width, height: svg.getBoundingClientRect().height
      })));
      if (sizes.some(s => s.width % 120 !== 0 || s.height % 92 !== 0)) throw Error(`Noninteger scale at ${width}: ${JSON.stringify(sizes)}`);
    }
    await page.emulateMedia({ reducedMotion: 'no-preference' });
    await page.goto(pathToFileURL(path.join(dir, 'cat2-walk.svg')).href);
    const standalone = await page.evaluate(() => {
      const svg = document.documentElement;
      const animations = svg.getAnimations({ subtree: true });
      for (const animation of animations) { animation.pause(); animation.currentTime = 385; }
      return { count: animations.length, visible: [...svg.querySelectorAll('.pose')]
        .filter(g => getComputedStyle(g).visibility === 'visible').map(g => g.id) };
    });
    if (standalone.count !== report.uniquePoses || standalone.visible.join() !== 'pose-3') throw Error(`Standalone SVG: ${JSON.stringify(standalone)}`);
    if (errors.length) throw Error(errors.join('\n'));
    console.log(JSON.stringify({ samples, loops: 3, controls: 'pass', mobile: 'pass', integerScales: 'pass', standaloneSvg: 'pass', reducedMotion: 'pass', pageErrors: errors }));
  } finally {
    await browser.close();
  }
})().catch(e => { console.error(e); process.exit(1); });
