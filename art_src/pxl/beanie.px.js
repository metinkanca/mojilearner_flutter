// Beanie for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// border three cells (9 units) like the finished pets, flat colours, no shading.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/beanie.px.js
// Export: python art_src/gen_cat_hats.py [--ship] beanie
//
// The original's two teals: a dark dome, a light cuff and a light pom.
//
// Border: three outlines through a `base` chain, the 4-neighbour `outline` (like
// the crown and the party hat) because this is all curve, and the square-corner
// `outline8` runs ~40% thick along a slope.
pal({
  k: "#1f2223",   // pet ink
  a: "#4e95a3",   // teal: the dome
  b: "#94d1d5",   // light teal: cuff and pom
})

// 40 x 27 cells of fill, as wide as the head (the border brings it to exactly the
// head's own span, x38..176), so it covers both ears. Full width is reached on the
// row that lands on y28, where the ears start, so no ear tip shows above it.
//
//   rows 0..6    the pom, 8 wide, a ball (4 6 8 8 8 6 4)
//   rows 7..20   the dome: widths 14 22 28 32 36 38 then 40
//   rows 21..26  the cuff, 40 wide, six rows
const dome = [14, 22, 28, 32, 36, 38].map((w, i) => rect(20 - w / 2, 7 + i, w, 1, "a"))

sprite("_beanie_fill", { w: 40, h: 27 },
  rect(18, 0, 4, 1, "b"),
  rect(17, 1, 6, 1, "b"),
  rect(16, 2, 8, 3, "b"),
  rect(17, 5, 6, 1, "b"),
  rect(18, 6, 4, 1, "b"),
  ...dome,
  rect(0, 13, 40, 8, "a"),
  rect(0, 21, 40, 6, "b"))

sprite("_beanie_1", { base: "_beanie_fill", outline: "k" })
sprite("_beanie_2", { base: "_beanie_1", outline: "k" })
sprite("beanie", { base: "_beanie_2", outline: "k" })
