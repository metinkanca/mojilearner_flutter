// Necklace for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// flat colours, no shading. The border is TWO cells (6 units), not the hats' three:
// at 9 units the outline swallowed these small pieces (owner: "too thick"). See
// tophat.px.js for why the border is a chain of outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/necklace.px.js
// Export: python art_src/gen_cat_hats.py [--ship] necklace
//
// Owner (2026-10-28): the first neck cut was "too thick and big" and had "far too
// many pixels": the cats have very few corners, long straight edges. So this is a
// small piece (26 cells of fill, narrower than the body), built from a handful of
// rectangles with one or two big steps, and the square-cornered `outline8`.
// Fill col c is x = 68 + 3c, fill row r is y = 163 + 3r (the box is x62..152, or x77..167 for the bow tie).
// The original: pale beads and a green gem. A three-row rope of beads (cream and
// lilac in blocks of three columns) sagging in one step, and a small gem.
pal({
  k: "#1f2223",   // pet ink
  w: "#efeae1",   // pearl
  p: "#c9b8e8",   // lilac pearl
  g: "#1e963d",   // gem
})

// Owner (2026-10-28 b): the necklace's sag is the look - ends high, the middle one
// step lower - so the collar, medal ribbon, scarves share it; and "just the
// important parts" (bell, gem, medal, knot, bandana tip, scarf tail) sit on the
// FACE centre, x122 = fill col 17.5, five cells right of the body's x107, while
// the rest of the piece stays centred on the body: a perspective match.
const beads = []
const bead = (c0, c1, r, h) => {
  for (let c = c0; c <= c1; c++) beads.push(rect(c, r, 1, h, Math.floor(c / 3) % 2 === 0 ? "w" : "p"))
}
bead(0, 5, 0, 3)      // the left end
bead(22, 25, 0, 3)    // the right end
bead(6, 21, 2, 3)     // the sag

sprite("_n_fill", { w: 26, h: 10 },
  ...beads,
  // the gem, on the face centre (cols 15..20)
  rect(16, 5, 4, 1, "g"),
  rect(15, 6, 6, 3, "g"),
  rect(16, 9, 4, 1, "g"))
sprite("_n_1", { base: "_n_fill", outline8: "k" })
sprite("necklace", { base: "_n_1", outline8: "k" })
