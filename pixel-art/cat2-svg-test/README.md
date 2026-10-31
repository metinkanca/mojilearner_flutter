# Cat 02 idle study

Open **index.html** in a browser to compare the original with the animation. It
works directly from disk, with play/pause, speed, scrubbing and stage backgrounds.

- **cat2-animated.svg**: self-contained animated vector, transparent background.
- **cat2-animated.gif**: transparent 4x animated preview.
- **cat2@1x.png** / **cat2@4x.png**: exact resting pose at native/display size.
- **cat2-sheet.png** + **cat2-sheet.json**: sprite atlas and frame timings.

The 5.56-second loop combines four breathing poses with a brief blink, left-ear
twitch and existing tail poses. Every edge uses horizontal/vertical segments;
poses switch discretely, without rotation, skew, smoothing or crossfades. Paws
stay fixed. The original colors are `#959379` and `#1f2223`.

The original SVG uses a 3-unit cell grid offset by (2, 1). This preview expresses
each cell as one unit on an 85 x 90 canvas, with transparent margins. Its resting
pose reproduces all 3,728 original cells exactly. The animation has 10 distinct
poses and 21 timed holds; its first and final holds are identical.

Sources are read from `../../assets/svgs/cat2*.svg`. All experiment files stay in
this folder. The source SVGs, app code and app asset configuration are unchanged.

Rebuild from the repository root:

```powershell
python pixel-art/cat2-svg-test/build.py
```

The builder uses the existing local Pixel Art Studio and Pillow. Edit `SCORE` in
`build.py` to adjust the timing, then rebuild. `animation.json` records source
hashes, timing and geometry checks. The SVG and HTML honor reduced-motion settings;
the preview's Play button lets you explicitly start the animation.

Visual review: the contact sheet preserves the silhouette, outline weight and
paired eyes. Browser previews keep the blink horizontal and the feet stationary;
the palette has exactly two colors, with no partial alpha or isolated pixels.
Breathing moves only one native cell; the ear dip moves at most two cells.
