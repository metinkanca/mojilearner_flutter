// Ghost bandana for the cat (Witching Hour pass): one pixel = one 3-unit cell of
// cat2's grid, flat colours, no shading, TWO-cell border like the other neck pieces
// (see collar.px.js and bandana.px.js).
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/ghostbandana.px.js
// Export: python art_src/gen_cat_hats.py [--ship] ghostbandana
//
// The original: a purple triangle with a cream ghost on it, knotted at the sides.
// Reworked in the neck pieces' style: a straight-edged triangle in a few big steps
// whose tip is on the face centre (x122, fill col 18) like the bandana, with the
// ghost on it, also on the face centre. The purple is lighter than the original's
// #663b72, which sat too close to the pet ink.
// Fill col c is x = 68 + 3c, fill row r is y = 163 + 3r; the box is x62..152.
pal({
  k: "#1f2223",   // pet ink
  p: "#7f4f94",   // cloth
  w: "#efeae1",   // ghost
})

// The ghost: 8 wide, 8 tall, on cols 14..21 (centre 18), rows 3..10, with eyes and a
// small mouth in ink.
const GHOST = [
  [2, 5, 0],   // [first col, last col, row]
  [1, 6, 1],
  [0, 7, 2], [0, 7, 3], [0, 7, 4], [0, 7, 5], [0, 7, 6],
  [0, 1, 7], [3, 4, 7], [6, 7, 7],      // three feet
]
const ghost = GHOST.map(([c0, c1, r]) => rect(14 + c0, 3 + r, c1 - c0 + 1, 1, "w"))

sprite("_gb_fill", { w: 26, h: 15 },
  rect(0, 0, 26, 2, "p"),        // the band across the neck
  rect(0, 2, 26, 3, "p"),        // the cloth, in steps toward a tip on the face centre
  rect(5, 5, 20, 3, "p"),
  rect(10, 8, 14, 3, "p"),
  rect(13, 11, 10, 2, "p"),
  rect(16, 13, 4, 2, "p"),
  ...ghost,
  rect(16, 5, 1, 2, "k"),        // eyes
  rect(19, 5, 1, 2, "k"),
  rect(17, 8, 2, 1, "k"))        // mouth

sprite("_gb_1", { base: "_gb_fill", outline8: "k" })
sprite("ghostbandana", { base: "_gb_1", outline8: "k" })
