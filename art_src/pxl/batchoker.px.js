// Bat choker for the cat (Witching Hour pass): one pixel = one 3-unit cell of cat2's
// grid, flat colours, no shading, TWO-cell border like the other neck pieces (see
// collar.px.js).
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/batchoker.px.js
// Export: python art_src/gen_cat_hats.py [--ship] batchoker
//
// The original: a purple bat with an orange gem as a choker. Reworked: the sagging
// band the collar and necklace share (ends high, middle one step lower), with the
// bat as the centrepiece on the FACE centre (x122, fill cols 13..28), wings spread,
// scalloped underneath, an orange gem on its body. The bat is a lighter violet than
// the band so it reads against it.
// Fill col c is x = 59 + 3c, fill row r is y = 163 + 3r; the box is x53..161, 32 cells
// of fill so the bat can spread (the first, 12-wide bat drowned in its own border).
pal({
  k: "#1f2223",   // pet ink
  p: "#7f4f94",   // band
  v: "#a67bc2",   // bat
  o: "#f07d1e",   // gem
})

// The bat, 16 wide and 6 tall, on fill cols 13..28 (centre 21 = x122), rows 1..6:
// wing tips and two ears on top, a straight body, scalloped underneath.
const BAT = [
  [0, 3, 0], [6, 6, 0], [9, 9, 0], [12, 15, 0],
  [0, 15, 1], [0, 15, 2],
  [1, 14, 3],
  [2, 5, 4], [7, 8, 4], [10, 13, 4],
  [3, 4, 5], [7, 8, 5], [11, 12, 5],
]
const bat = BAT.map(([c0, c1, r]) => rect(13 + c0, 1 + r, c1 - c0 + 1, 1, "v"))

sprite("_bc_fill", { w: 32, h: 7 },
  rect(0, 0, 6, 2, "p"),         // the band: left end
  rect(26, 0, 6, 2, "p"),        //           right end
  rect(6, 1, 20, 2, "p"),        //           the sag
  ...bat,
  rect(20, 2, 2, 2, "o"))        // the gem

sprite("_bc_1", { base: "_bc_fill", outline8: "k" })
sprite("batchoker", { base: "_bc_1", outline8: "k" })
