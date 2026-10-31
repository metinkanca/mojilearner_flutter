// Redesign preview (owner 2026-10-28: the first masks/mustaches "still don't work visually").
// One pixel = one 3-unit cell of cat2's grid, flat colours, no shading, two-cell border.
// The eye windows are exactly the eyes (cols 7..10 and 28..31, rows 4..10), cut by gen_cat_hats.py.
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/mask_b.px.js
// Export: python art_src/gen_cat_hats.py mask_b
// Fill col c is x = 62 + 3c, fill row r is y = 94 + 3r.
pal({
  k: "#1f2223",
  p: "#8f4a62",
  g: "#f8b230",
})
const HALF = [[0, 5], [0, 7], [1, 9], [1, 11], [1, 12], [1, 13], [1, 13], [1, 13], [1, 13], [1, 13], [1, 13], [1, 13], [1, 13], [4, 10], [4, 10], [4, 10], [4, 10], [4, 10], [4, 10], [4, 10]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "p"))
  cols.push(rect(38 - c, r0, 1, r1 - r0 + 1, "p"))
})
sprite("_f", { w: 39, h: 14 },
  ...cols,
  rect(4, 13, 9, 1, "g"),
  rect(26, 13, 9, 1, "g"))
sprite("_1", { base: "_f", outline8: "k" })
sprite("mask_b", { base: "_1", outline8: "k" })
