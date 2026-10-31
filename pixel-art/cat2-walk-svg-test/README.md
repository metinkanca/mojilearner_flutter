# Cat 02 walking study

Open **index.html** for an in-place walk with synchronized scrolling ground,
pause/play, speed, scrubbing and background controls. The preview works from disk.

- **cat2-walk.svg** — self-contained transparent animated SVG.
- **cat2-walk.gif** — transparent animation at 4x.
- **cat2-walk@1x.png** / **cat2-walk@4x.png** — first pose at native/display size.
- **cat2-walk-sheet.png** + **cat2-walk-sheet.json** — eight-frame horizontal atlas.

Eight poses at 110 ms each make a 0.88-second loop. Four alternating paws connect
to fixed upper joints through square knees. Ground-contact paws move backward
three native cells per pose, matching the preview floor. The head follows the
one-cell body bob one pose later; the tail changes every two poses.

The original cat's head and existing tail silhouettes are retained. A shorter
horizontal torso and four legs are newly drawn for the walking pose. Only the
source colors `#959379` and `#1f2223` are used. All SVG paths use `M/H/V/Z`; no
rotation, diagonal segments, curves, interpolated poses or softened pixels.

Canvas: 120 x 92 native cells. The SVG and GIF contain only the cat; scrolling
ground belongs to the preview. Reduced-motion settings show a static pose, with
an explicit Play button to opt into motion.

Rebuild from the repository root:

```powershell
python pixel-art/cat2-walk-svg-test/build.py
```

The builder uses the existing `cat2-idle/cellsvg.py` SVG grid reader and local
Pixel Art Studio. All generated files stay here. Source SVGs, the app and the
earlier idle test are unchanged; `animation.json` records source hashes.
