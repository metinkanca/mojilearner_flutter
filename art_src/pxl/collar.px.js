// Bell collar for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// flat colours, no shading. The border is TWO cells (6 units), not the hats' three:
// at 9 units the outline swallowed these small pieces (owner: "too thick"). See
// tophat.px.js for why the border is a chain of outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/collar.px.js
// Export: python art_src/gen_cat_hats.py [--ship] collar
//
// Owner (2026-10-28): the first neck cut was "too thick and big" and had "far too
// many pixels": the cats have very few corners, long straight edges. So this is a
// small piece (26 cells of fill, narrower than the body), built from a handful of
// rectangles with one or two big steps, and the square-cornered `outline8`.
// Fill col c is x = 68 + 3c, fill row r is y = 163 + 3r (the box is x62..152, or x77..167 for the bow tie).
// The original: a coral band with a gold bell. Here a flat two-row band and a
// small bell with its corners cut.
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // band
  g: "#f8b230",   // bell
})

// Owner (2026-10-28 b): the necklace's sag is the look - ends high, the middle one
// step lower - so the collar, medal ribbon, scarves share it; and "just the
// important parts" (bell, gem, medal, knot, bandana tip, scarf tail) sit on the
// FACE centre, x122 = fill col 17.5, five cells right of the body's x107, while
// the rest of the piece stays centred on the body: a perspective match.
sprite("_c_fill", { w: 26, h: 9 },
  rect(0, 0, 6, 2, "r"),        // the left end
  rect(22, 0, 4, 2, "r"),       // the right end
  rect(6, 1, 16, 2, "r"),       // the sag
  // the bell, on the face centre (cols 15..20)
  rect(16, 3, 4, 1, "g"),
  rect(15, 4, 6, 4, "g"),
  rect(16, 8, 4, 1, "g"))
sprite("_c_1", { base: "_c_fill", outline8: "k" })
sprite("collar", { base: "_c_1", outline8: "k" })
