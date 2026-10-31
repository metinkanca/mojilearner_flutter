// Bandana for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// flat colours, no shading. The border is TWO cells (6 units), not the hats' three:
// at 9 units the outline swallowed these small pieces (owner: "too thick"). See
// tophat.px.js for why the border is a chain of outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/bandana.px.js
// Export: python art_src/gen_cat_hats.py [--ship] bandana
//
// Owner (2026-10-28): the first neck cut was "too thick and big" and had "far too
// many pixels": the cats have very few corners, long straight edges. So this is a
// small piece (26 cells of fill, narrower than the body), built from a handful of
// rectangles with one or two big steps, and the square-cornered `outline8`.
// Fill col c is x = 68 + 3c, fill row r is y = 163 + 3r (the box is x62..152, or x77..167 for the bow tie).
// The original: a dark band with a coral triangle. The triangle keeps #e3664f (the
// Cloud Bandana swaps that fill for cream, accessories.dart AccessoryRecolor). The
// band is a mid blue; the original's #1a3340 sat on the ink and read as a hole.
// The triangle is three steps, four cells in on each side per step.
pal({
  k: "#1f2223",   // pet ink
  b: "#3d6f8f",   // band
  r: "#e3664f",   // the cloth
})

// Owner (2026-10-28 b): the necklace's sag is the look - ends high, the middle one
// step lower - so the collar, medal ribbon, scarves share it; and "just the
// important parts" (bell, gem, medal, knot, bandana tip, scarf tail) sit on the
// FACE centre, x122 = fill col 17.5, five cells right of the body's x107, while
// the rest of the piece stays centred on the body: a perspective match.
// The triangle's tip is on the face centre (cols 16..19), so its steps are
// uneven: six cells in on the left per step, two on the right.
sprite("_bd_fill", { w: 26, h: 10 },
  rect(0, 0, 26, 2, "b"),
  rect(0, 2, 26, 2, "r"),
  rect(6, 4, 18, 2, "r"),
  rect(12, 6, 10, 2, "r"),
  rect(16, 8, 4, 2, "r"))
sprite("_bd_1", { base: "_bd_fill", outline8: "k" })
sprite("bandana", { base: "_bd_1", outline8: "k" })
