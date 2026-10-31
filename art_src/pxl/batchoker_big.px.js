// Bat choker, BIG bat, for the cat (Witching Hour pass): owner (2026-10-28) liked the
// 16-wide bat (batchoker.px.js) and asked to "try bigger, just in case". One pixel =
// one 3-unit cell of cat2's grid, flat colours, no shading, TWO-cell border.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/batchoker_big.px.js
// Export: python art_src/gen_cat_hats.py [--ship] batchoker_big
//
// The bat is 22 wide and 8 tall (x89..155, centre x122 = the face centre), the width
// of the old art's wings: wing tips and two ears on top, a straight body, and two
// scallop points under each wing. The band is the collar's sag across the whole body.
// Fill col c is x = 50 + 3c, fill row r is y = 163 + 3r; the box is x44..170 (42
// cells: 38 of fill + the border), centred on the body's x107.
pal({
  k: "#1f2223",   // pet ink
  p: "#7f4f94",   // band
  v: "#a67bc2",   // bat
  o: "#f07d1e",   // gem
})

// Per column of the bat: where it starts (the top edge) and ends (the bottom edge).
// The top edge climbs to a wing tip at each end, dips, and rises again into two
// ears with the head between them; the bottom edge has two scallop points under
// each wing and one under the body.
const TOP = [0, 0, 0, 1, 1, 1, 2, 2, 1, 1, 3, 3, 1, 1, 2, 2, 1, 1, 1, 0, 0, 0]
const END = [4, 6, 7, 6, 5, 6, 7, 6, 5, 6, 7, 7, 6, 5, 6, 7, 6, 5, 6, 7, 6, 4]
const bat = TOP.map((top, c) => rect(13 + c, 1 + top, 1, END[c] - top + 1, "v"))

sprite("_bb_fill", { w: 38, h: 9 },
  rect(0, 0, 6, 2, "p"),         // the band: left end
  rect(32, 0, 6, 2, "p"),        //           right end
  rect(6, 1, 26, 2, "p"),        //           the sag
  ...bat,
  rect(23, 5, 2, 2, "o"))        // the gem

sprite("_bb_1", { base: "_bb_fill", outline8: "k" })
sprite("batchoker_big", { base: "_bb_1", outline8: "k" })
