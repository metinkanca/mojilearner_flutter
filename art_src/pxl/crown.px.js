// Crown for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's grid,
// border three cells (9 units) like the finished pets, flat colours, no
// shading.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/crown.px.js
// Export: python art_src/gen_cat_hats.py [--ship] crown
//
// The original's gold, with one detail added: a coral gem in the band.
//
// Border: three outlines through a `base` chain. This crown uses the 4-neighbour
// `outline` (a diamond), not the `outline8` the other hats use, because outline8
// squares off every tine tip; the diamond follows a point and keeps it sharp.
pal({
  k: "#1f2223",   // pet ink
  g: "#f8b230",   // gold (the original crown's)
  r: "#e3664f",   // gem
})

// 40 x 24 cells of fill, as wide as the head (the border brings it to exactly the
// head's own span, x38..176). The top edge is ONE zigzag, |\ /\ /| : a vertical
// outer wall at each end, three peaks with the middle one tallest, and V-shaped
// valleys where the slopes meet at a point, with no flat floor between the tines.
// EVERY slope is the same 45 degrees, one row per column (an earlier cut
// interpolated and got uneven stair steps). The right half is the left half
// mirrored column for column, so the two sides are identical by construction.
// The outer peaks cover the cat's ear columns, which rise only to y28.
//
// Left half, column c = 0..19:
//   c 0..8    falls  from the outer peak (row 4) to the valley (row 12)
//   c 8..19   climbs from the valley to the centre peak (row 1 at c = 19)
//
// Centring (owner, after three tries): the crown is fitted to the head and
// symmetric about the SKULL centre (x107). Centring it on the face (x122) pushed
// it past the head on one side and "didn't make sense"; narrowing it left an ear
// out; a three-quarter version broke the mirroring. See gen_cat_hats.py.
const topRow = (c) => (c <= 8 ? 4 + c : 20 - c)
const columns = []
for (let c = 0; c < 20; c++) {
  const row = topRow(c)
  columns.push(rect(c, row, 1, 24 - row, "g"))
  columns.push(rect(39 - c, row, 1, 24 - row, "g"))
}

sprite("_crown_fill", { w: 40, h: 24 },
  ...columns,
  // the gem
  rect(17, 16, 6, 5, "r"))

sprite("_crown_1", { base: "_crown_fill", outline: "k" })
sprite("_crown_2", { base: "_crown_1", outline: "k" })
sprite("crown", { base: "_crown_2", outline: "k" })
