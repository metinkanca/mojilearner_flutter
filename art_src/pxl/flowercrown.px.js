// Flower crown for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's
// grid, border three cells (9 units) like the finished pets, flat colours, no
// shading.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/flowercrown.px.js
// Export: python art_src/gen_cat_hats.py [--ship] flowercrown
//
// The original's pieces and colours: a green vine across the head with small
// flowers on it (coral, gold, cream, gold, coral), each ~14 units across. Here
// they are 5 cells (15 units): the smallest that still shows fill under a
// three-cell border. Eight sit edge to edge across the head, so the border only
// wraps the garland's outside; the vine shows in the corners between blossoms.
//
// Border: the 4-neighbour `outline`, so the blossoms stay round.
pal({
  k: "#1f2223",   // pet ink
  v: "#1e963d",   // the vine
  c: "#e16f71",   // coral petals
  w: "#efeae1",   // cream petals
  g: "#f8b230",   // gold petals / centres
})

// 40 x 8 cells of fill, as wide as the head (the border brings it to exactly the
// head's own span, x38..176): a row of 5x5 flowers (fill y37..52) over a
// three-row vine (y52..61). The top border (y28) lands on the ear tips, so both
// ears are covered.
const flower = (x, petals, heart) => [
  rect(x + 1, 0, 3, 1, petals),
  rect(x, 1, 5, 3, petals),
  rect(x + 1, 4, 3, 1, petals),
  rect(x + 2, 2, 1, 1, heart),    // centre
]

sprite("_flowers_fill", { w: 40, h: 8 },
  rect(0, 5, 40, 3, "v"),         // the vine, showing in the corners between flowers
  ...flower(0, "c", "g"),
  ...flower(5, "g", "c"),
  ...flower(10, "w", "g"),
  ...flower(15, "g", "c"),
  ...flower(20, "c", "g"),
  ...flower(25, "g", "c"),
  ...flower(30, "w", "g"),
  ...flower(35, "g", "c"))

sprite("_flowers_1", { base: "_flowers_fill", outline: "k" })
sprite("_flowers_2", { base: "_flowers_1", outline: "k" })
sprite("flowercrown", { base: "_flowers_2", outline: "k" })
