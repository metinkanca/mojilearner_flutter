// Bow tie for the cat: one pixel = one 3-unit cell of cat2's grid, flat colours, no
// shading, TWO-cell border (see collar.px.js).
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/bowtie.px.js
// Export: python art_src/gen_cat_hats.py [--ship] bowtie
//
// Owner, 2026-10-28 (after a reference sheet of pixel bow ties): the round bows were
// "too circular". This is the butterfly one with tails (variant G, picked over E
// after E shipped): two tall wings that taper in straight lines to a small square
// knot, and two short ribbon tails hanging from it. Owner, on E: "remove the line in the middle,
// connect the top and bottom parts instead of having gaps on the sides, and make it
// smaller in scale, without changing the model": no fold line, a solid outer edge
// (no notch), and the same shape redrawn 20 cells wide and 9 tall instead of 26 by
// 11 (about three quarters).
// Fill col c is x = 92 + 3c, fill row r is y = 163 + 3r; the box is x86..158 (20
// cells of fill + the border; 11 rows tall with the tails), so the knot (cols 8..11, x116..128) is on the face
// centre, x122.
pal({
  k: "#1f2223",   // pet ink
  r: "#e3664f",   // bow
  d: "#b8453a",   // knot
})

// Left wing, outer edge first: [first col, last col, first row, last row].
const WING = [[0, 1, 0, 8], [2, 3, 1, 7], [4, 5, 2, 6], [6, 7, 3, 5]]
const wings = []
for (const [c0, c1, r0, r1] of WING) {
  wings.push(rect(c0, r0, c1 - c0 + 1, r1 - r0 + 1, "r"))
  wings.push(rect(19 - c1, r0, c1 - c0 + 1, r1 - r0 + 1, "r"))
}

sprite("_bw_fill", { w: 20, h: 11 },
  ...wings,
  rect(8, 2, 4, 5, "d"),     // the knot
  rect(9, 3, 2, 3, "r"),     // its lighter centre
  rect(6, 7, 3, 4, "r"),     // the tails, splayed, with darker tips
  rect(11, 7, 3, 4, "r"),
  rect(6, 10, 3, 1, "d"),
  rect(11, 10, 3, 1, "d"))

sprite("_bw_1", { base: "_bw_fill", outline8: "k" })
sprite("bowtie", { base: "_bw_1", outline8: "k" })
