// Plain cat-eye mask (owner 2026-10-28: "i dont think we need arches and dips"): straight top and
// bottom edges, one band across, eye holes exactly the eyes. Flat colours, two-cell border.
// Fill col c is x = 62 + 3c, fill row r is y = 94 + 3r; eyes are cols 7..10 / 28..31, rows 4..10.
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/mask_j.px.js
// Export: python art_src/gen_cat_hats.py mask_j
pal({
  k: "#1f2223",
  p: "#c9cdd3",
})
const HALF = [[0, 4], [0, 6], [1, 8], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "p"))
  cols.push(rect(38 - c, r0, 1, r1 - r0 + 1, "p"))
})
sprite("_f", { w: 39, h: 15 }, ...cols)
sprite("_1", { base: "_f", outline8: "k" })
sprite("mask_j", { base: "_1", outline8: "k" })
