// Medal for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// flat colours, no shading. The border is TWO cells (6 units), not the hats' three:
// at 9 units the outline swallowed these small pieces (owner: "too thick"). See
// tophat.px.js for why the border is a chain of outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/medal.px.js
// Export: python art_src/gen_cat_hats.py [--ship] medal
//
// Owner (2026-10-28): the first neck cut was "too thick and big" and had "far too
// many pixels": the cats have very few corners, long straight edges. So this is a
// small piece (26 cells of fill, narrower than the body), built from a handful of
// rectangles with one or two big steps, and the square-cornered `outline8`.
// Fill col c is x = 68 + 3c, fill row r is y = 163 + 3r (the box is x62..152, or x77..167 for the bow tie).
// The original: a teal ribbon and a gold medal. A two-row ribbon round the neck, a
// short strap down the middle, and an octagonal medal with a cream centre.
pal({
  k: "#1f2223",   // pet ink
  t: "#4e95a3",   // ribbon
  g: "#f8b230",   // medal
  w: "#efeae1",   // medal centre
})

// Owner (2026-10-28 b): the necklace's sag is the look - ends high, the middle one
// step lower - so the collar, medal ribbon, scarves share it; and "just the
// important parts" (bell, gem, medal, knot, bandana tip, scarf tail) sit on the
// FACE centre, x122 = fill col 17.5, five cells right of the body's x107, while
// the rest of the piece stays centred on the body: a perspective match.
sprite("_m_fill", { w: 26, h: 14 },
  rect(0, 0, 6, 2, "t"),        // the left end
  rect(22, 0, 4, 2, "t"),       // the right end
  rect(6, 1, 16, 2, "t"),       // the sag
  rect(16, 3, 4, 3, "t"),       // the strap, on the face centre
  rect(15, 6, 6, 1, "g"),       // the medal: cols 14..21, an octagon
  rect(14, 7, 8, 6, "g"),
  rect(15, 13, 6, 1, "g"),
  rect(16, 8, 4, 4, "w"))
sprite("_m_1", { base: "_m_fill", outline8: "k" })
sprite("medal", { base: "_m_1", outline8: "k" })
