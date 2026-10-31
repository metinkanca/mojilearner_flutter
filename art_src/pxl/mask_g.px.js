// Mask redesign after the owner's reference (2026-10-28): a Venetian cat-eye mask, outer wings swept
// up to points, the top edge arching over each eye and dipping at the nose, almond eye holes.
// One pixel = one 3-unit cell of cat2's grid, flat colours, two-cell border.
// Fill col c is x = 62 + 3c, fill row r is y = 94 + 3r; eyes are cols 7..10 / 28..31, rows 4..10.
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/mask_g.px.js
// Export: python art_src/gen_cat_hats.py mask_g
pal({
  k: "#1f2223",
  p: "#8f4a62",
})
const HALF = [[0, 3], [0, 5], [1, 7], [2, 9], [2, 11], [2, 12], [1, 13], [1, 13], [1, 13], [1, 13], [1, 12], [2, 12], [3, 11], [4, 10], [5, 10], [5, 9], [5, 9], [5, 9], [5, 9], [5, 9]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "p"))
  cols.push(rect(38 - c, r0, 1, r1 - r0 + 1, "p"))
})
sprite("_f", { w: 39, h: 15 },
  ...cols)
sprite("_1", { base: "_f", outline8: "k" })
sprite("mask_g", { base: "_1", outline8: "k" })
