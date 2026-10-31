// Scarf for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// flat colours, no shading. The border is TWO cells (6 units), not the hats' three:
// at 9 units the outline swallowed these small pieces (owner: "too thick"). See
// tophat.px.js for why the border is a chain of outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/scarf.px.js
// Export: python art_src/gen_cat_hats.py [--ship] scarf
//
// Owner (2026-10-28): the first neck cut was "too thick and big" and had "far too
// many pixels": the cats have very few corners, long straight edges. So this is a
// small piece (26 cells of fill, narrower than the body), built from a handful of
// rectangles with one or two big steps, and the square-cornered `outline8`.
// Fill col c is x = 68 + 3c, fill row r is y = 163 + 3r (the box is x62..152, or x77..167 for the bow tie).
// The original: a striped teal scarf with a tail in front. It keeps #4e95a3 and
// #94d1d5 (the Dusk Scarf swaps those two fills). A three-row wrap with a light
// stripe, and a tail from the right of centre, striped in bands of three rows.
pal({
  k: "#1f2223",   // pet ink
  t: "#4e95a3",   // teal
  l: "#94d1d5",   // light stripe
})

// Owner (2026-10-28 b): the necklace's sag is the look - ends high, the middle one
// step lower - so the collar, medal ribbon, scarves share it; and "just the
// important parts" (bell, gem, medal, knot, bandana tip, scarf tail) sit on the
// FACE centre, x122 = fill col 17.5, five cells right of the body's x107, while
// the rest of the piece stays centred on the body: a perspective match.
sprite("_s_fill", { w: 26, h: 14 },
  rect(0, 0, 6, 3, "t"),        // the left end
  rect(22, 0, 4, 3, "t"),       // the right end
  rect(6, 1, 16, 3, "t"),       // the sag
  rect(0, 1, 6, 1, "l"),        // stripes
  rect(22, 1, 4, 1, "l"),
  rect(6, 2, 16, 1, "l"),
  // the tail, on the face centre (cols 15..20), banded in threes
  rect(15, 4, 6, 3, "l"),
  rect(15, 7, 6, 3, "t"),
  rect(15, 10, 6, 3, "l"))
sprite("_s_1", { base: "_s_fill", outline8: "k" })
sprite("scarf", { base: "_s_1", outline8: "k" })
