// Cat-eye mask, flat middle (owner 2026-10-28: no arch or dip in the MIDDLE part; the swept wings stay).
// Wings and lobes as mask_f, but the bridge between the eyes is straight, top and bottom.
// Flat colours, two-cell border; eye holes exactly the eyes (cut by gen_cat_hats.py).
// Fill col c is x = 62 + 3c, fill row r is y = 94 + 3r; eyes are cols 7..10 / 28..31, rows 4..10.
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/mask_l.px.js
// Export: python art_src/gen_cat_hats.py mask_l
pal({
  k: "#1f2223",
  p: "#c9cdd3",
})
const HALF = [[0, 3], [0, 5], [1, 7], [2, 9], [2, 11], [2, 12], [1, 13], [1, 13], [1, 13], [1, 13], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "p"))
  cols.push(rect(38 - c, r0, 1, r1 - r0 + 1, "p"))
})
sprite("_f", { w: 39, h: 15 }, ...cols)
sprite("_1", { base: "_f", outline8: "k" })
sprite("mask_l", { base: "_1", outline8: "k" })
