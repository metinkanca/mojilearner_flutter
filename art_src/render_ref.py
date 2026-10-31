# -*- coding: utf-8 -*-
"""Renders `ref_airfield.svg` onto its own pixel grid, for tracing.

The reference arrived as a raster first and as vectors second, and the vectors
are what make an exact trace possible. A raster has to be *sampled*: its
lattice recovered by autocorrelation, then read back by majority vote, which
cannot hold a one-cell outline at any output size below the source. A vector
can be rendered directly onto the lattice instead.

Two details matter, and both were wrong on the first attempt:

* **Render large, then take cell centres.** Box-filtering a 4x render blends
  every edge, and the blends are what a nearest-colour trace turns into
  speckle — small features like the control tower came back as noise. Taking
  the centre pixel of each 4x4 block samples the flat colour the artist
  actually drew there. Distinct colours drop from four thousand to a tail
  under a few dozen that matter.
* **224x300 is not a guess.** Autocorrelating the colour-change signal of
  either copy peaks at multiples of one cell; against the SVG's 1529x2048
  that cell is 6.83px, which is 224x300 exactly, and it matches what the
  raster copy gave independently.

    python art_src/render_ref.py

Writes `ref_airfield_native.png`, which is committed: the trace should not
need Chrome on every machine, only on the one that regenerates it.
"""

import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SVG = os.path.join(HERE, 'ref_airfield.svg')
OUT = os.path.join(HERE, 'ref_airfield_native.png')

# The reference's own grid.
COLS, ROWS = 224, 300

# Rendered at this multiple, then sampled at cell centres.
SCALE = 4

CHROME = [
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    '/usr/bin/google-chrome',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
]


def chrome():
    for path in CHROME:
        if os.path.exists(path):
            return path
    found = shutil.which('chrome') or shutil.which('google-chrome')
    if found:
        return found
    raise SystemExit('no Chrome found; ref_airfield_native.png is committed, '
                     'so this is only needed to regenerate it')


def main():
    tmp = tempfile.mkdtemp()
    big = os.path.join(tmp, 'big.png')
    subprocess.run([
        chrome(), '--headless', '--disable-gpu', '--hide-scrollbars',
        '--screenshot=' + big,
        '--window-size=%d,%d' % (COLS * SCALE, ROWS * SCALE),
        'file:///' + SVG.replace('\\', '/'),
    ], check=True, capture_output=True)

    src = Image.open(big).convert('RGB').load()
    out = Image.new('RGB', (COLS, ROWS))
    dst = out.load()
    half = SCALE // 2
    for y in range(ROWS):
        for x in range(COLS):
            dst[x, y] = src[x * SCALE + half, y * SCALE + half]
    out.save(OUT)
    shutil.rmtree(tmp, ignore_errors=True)
    print('wrote %s (%dx%d)' % (OUT, COLS, ROWS))


if __name__ == '__main__':
    sys.exit(main())
