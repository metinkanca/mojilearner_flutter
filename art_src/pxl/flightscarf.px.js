// Windswept scarf for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// flat colours, no shading. The border is TWO cells (6 units), not the hats' three:
// at 9 units the outline swallowed these small pieces (owner: "too thick"). See
// tophat.px.js for why the border is a chain of outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/flightscarf.px.js
// Export: python art_src/gen_cat_hats.py [--ship] flightscarf
//
// Owner (2026-10-28): the first neck cut was "too thick and big" and had "far too
// many pixels": the cats have very few corners, long straight edges. So this is a
// small piece (26 cells of fill, narrower than the body), built from a handful of
// rectangles with one or two big steps, and the square-cornered `outline8`.
// Fill col c is x = 68 + 3c, fill row r is y = 163 + 3r (this piece starts higher, see below) (the box is x62..152, or x77..167 for the bow tie).
// The original: a coral scarf with cream tips, one end streaming in the wind.
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // scarf
  w: "#efeae1",   // tips
})

// Owner (2026-10-28 c): the first windswept scarf was unreadable - a flat bar with a
// cream block on the end. A scarf in the wind reads from its tail FLYING: the wrap
// is the same sagging band as the other neck pieces, and its right end rises
// up and away in three big steps (coral, cream, coral), the way a pennant lifts,
// beside the cheek; owner (2026-10-28 d): flip it so the wind blows the OTHER way,
// so the tail now rises up the LEFT cheek (the sprite is the old one mirrored,
// box x17..149 so the wrap stays on the body's x68..146); a short striped end hangs from the left. (A forked tail was
// tried: under a two-cell border the notch closes up.) Right edge x194 (canvas:
// 202). Fill row r is y = 145 + 3r here, so the wrap is rows 6..9 (y163..).
sprite("_f_fill", { w: 40, h: 16 },
  rect(34, 6, 6, 3, "r"),       // the wrap: its end on the right
  rect(18, 7, 16, 3, "r"),      //           the sag
  rect(14, 6, 4, 3, "r"),       //           its end on the left
  rect(9, 4, 5, 3, "r"),        // the tail, rising up the LEFT: step 1
  rect(4, 2, 5, 3, "w"),        //                              step 2, cream
  rect(0, 0, 4, 3, "r"),        //                              step 3
  rect(27, 10, 5, 3, "r"),      // the hanging end, right of centre
  rect(27, 13, 5, 3, "w"))

sprite("_f_1", { base: "_f_fill", outline8: "k" })
sprite("flightscarf", { base: "_f_1", outline8: "k" })
