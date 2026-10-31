// Sunglasses for the cat: the glasses' frame (glasses.px.js) with dark lenses. One
// pixel = one 3-unit cell of cat2's grid, flat colours, no shading. The lenses fill
// the whole opening, so the eyes are hidden behind them, as sunglasses do. The lens
// is a mid blue-grey: the old #1a3340 sat almost on the pet ink and read as a hole.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/sunglasses.px.js
// Export: python art_src/gen_cat_hats.py [--ship] sunglasses
// Fill col c is x = 62 + 3c, fill row r is y = 97 + 3r; the box is x62..179, y97..136.
pal({
  k: "#1f2223",   // pet ink: the frame
  b: "#3f6283",   // lens
})

const lens = (c0) => [
  rect(c0 + 2, 2, 6, 9, "b"),
  rect(c0, 0, 10, 2, "k"),
  rect(c0, 11, 10, 2, "k"),
  rect(c0, 2, 2, 9, "k"),
  rect(c0 + 8, 2, 2, 9, "k"),
]

sprite("sunglasses", { w: 39, h: 13 },
  ...lens(4),
  ...lens(25),
  rect(14, 5, 11, 2, "k"),
  rect(0, 5, 4, 2, "k"),
  rect(35, 5, 4, 2, "k"))
