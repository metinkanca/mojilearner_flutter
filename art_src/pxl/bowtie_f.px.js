// Bow tie, variant F: sharp, for the cat: one pixel = one 3-unit cell of cat2's grid, flat
// colours, no shading, TWO-cell border (see collar.px.js). Owner (2026-10-28 e): the
// round bows were "too circular"; the reference pixel bow ties (Pinterest / Etsy
// sheet) are butterfly-shaped: tall wings with POINTED outer corners that taper in
// a straight line to a small square knot, fold lines inside, no curves. Like E but the corners are longer spikes and the taper is steeper, so it reads as a bat-wing bow.
// Fill col c is x = 83 + 3c, fill row r is y = 163 + 3r; the box is x77..167 (26
// cells of fill + the border), so the knot (cols 11..14, x116..128) is on the face
// centre, x122.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/bowtie_f.px.js
// Export: python art_src/gen_cat_hats.py [--ship] bowtie_f
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // bow
  d: "#b8453a",   // knot and folds
})

// Left wing, outer edge first: [first col, last col, first row, last row]. The two
// outermost columns are only the top and bottom rows: the pointed corners.
const WING = [[0,2,0,2,8,10],[3,4,0,10],[5,6,2,8],[7,8,3,7],[9,10,4,6]]
const rects = []
for (const [c0, c1, r0, r1, r2, r3] of WING) {
  rects.push(rect(c0, r0, c1 - c0 + 1, r1 - r0 + 1, "r"))
  rects.push(rect(25 - c1, r0, c1 - c0 + 1, r1 - r0 + 1, "r"))
  if (r2 !== undefined) {
    rects.push(rect(c0, r2, c1 - c0 + 1, r3 - r2 + 1, "r"))
    rects.push(rect(25 - c1, r2, c1 - c0 + 1, r3 - r2 + 1, "r"))
  }
}

sprite("_bwf_fill", { w: 26, h: 11 },
  ...rects,
  // the fold: a dark line running from the knot out along each wing
  rect(3, 5, 7, 1, "d"),
  rect(16, 5, 7, 1, "d"),
  // the knot
  rect(11, 3, 4, 5, "d"),
  rect(12, 4, 2, 3, "r"))

sprite("_bwf_1", { base: "_bwf_fill", outline8: "k" })
sprite("bowtie_f", { base: "_bwf_1", outline8: "k" })
