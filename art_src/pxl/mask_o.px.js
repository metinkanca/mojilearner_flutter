// Cat-eye mask with flair (owner 2026-10-28: "2nd looks nice" = mask_l, in plum, with extra things on it).
// Shape as mask_l: swept wings, lobes over the eyes, a straight bridge. Flat colours, two-cell border;
// eye holes exactly the eyes (cut by gen_cat_hats.py).
// Fill col c is x = 62 + 3c, fill row r is y = 94 + 3r; eyes are cols 7..10 / 28..31, rows 4..10.
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/mask_o.px.js
// Export: python art_src/gen_cat_hats.py mask_o
pal({
  k: "#1f2223",
  p: "#8f4a62",
  g: "#f8b230",
  c: "#fbe9b5",
  l: "#c9b8e8",
})
const HALF = [[0, 3], [0, 5], [1, 7], [2, 9], [2, 11], [2, 12], [1, 13], [1, 13], [1, 13], [1, 13], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12], [2, 12]]
const cols = []
HALF.forEach(([r0, r1], c) => {
  cols.push(rect(c, r0, 1, r1 - r0 + 1, "p"))
  cols.push(rect(38 - c, r0, 1, r1 - r0 + 1, "p"))
})
const both = (c, r, w, h, col) => [rect(c, r, w, h, col), rect(39 - c - w, r, w, h, col)]

const bot = []
HALF.forEach(([r0, r1], c) => { if (c >= 4) bot.push(...both(c, r1, 1, 1, "g")) })
const flair = [
  ...bot,
  ...both(0, 0, 2, 3, "g"),
  ...both(6, 2, 2, 1, "g"), ...both(9, 2, 1, 1, "g"),
  rect(18, 5, 3, 5, "g"), rect(17, 6, 5, 3, "g"), rect(19, 7, 1, 1, "c"),
  ...both(13, 7, 1, 1, "l"), ...both(14, 6, 1, 3, "l"),
]
sprite("_f", { w: 39, h: 15 }, ...cols, ...flair)
sprite("_1", { base: "_f", outline8: "k" })
sprite("mask_o", { base: "_1", outline8: "k" })
