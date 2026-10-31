// Flight goggles for the cat: one pixel = one 3-unit cell of cat2's grid, flat colours,
// no shading, TWO-cell border like the neck pieces (see collar.px.js).
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/goggles.px.js
// Export: python art_src/gen_cat_hats.py [--ship] goggles
//
// Two grey lenses on the eyes in navy rims, a strap running out each side. It keeps
// the old art's two fills, #1a3340 (rim and strap) and #727072 (lenses), because the
// Brass Goggles are exactly those two swapped (accessories.dart, AccessoryRecolor).
// The lenses are opaque, as the old ones were, so the eyes are hidden behind them.
// Each lens is 8 x 11 cells, centred on its eye (x89 and x152).
// Fill col c is x = 68 + 3c, fill row r is y = 100 + 3r; the box is x62..179, y94..139.
pal({
  k: "#1f2223",   // pet ink
  n: "#1a3340",   // rim and strap
  g: "#727072",   // lens
})

// One lens: a rim with its corners cut, the grey inside.
const lens = (c0) => [
  rect(c0 + 1, 0, 6, 11, "n"),
  rect(c0, 1, 8, 9, "n"),
  rect(c0 + 1, 2, 6, 7, "g"),
]

sprite("_gg_fill", { w: 35, h: 11 },
  rect(0, 4, 35, 3, "n"),          // the strap, right through
  ...lens(3),                      // left lens: x77..101
  ...lens(24))                     // right lens: x140..164

sprite("_gg_1", { base: "_gg_fill", outline8: "k" })
sprite("goggles", { base: "_gg_1", outline8: "k" })
