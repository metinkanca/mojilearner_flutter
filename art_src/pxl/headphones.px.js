// Headphones for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's
// grid, border three cells (9 units) like the finished pets, flat colours, no
// shading. See tophat.px.js for why the border is a chain of three outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/headphones.px.js
// Export: python art_src/gen_cat_hats.py [--ship] headphones
//
// Shaped like real over-ear headphones (owner's photo): the band ARCHES over the
// head, outside the ears, and comes down the sides to big cups; the ears sit inside
// the arch. The first cut was a straight bar across the head below the ear tips,
// which read as a visor.
//
// Colours: the original's grey band and pads, and slate cups (its #242e38 cups sat
// on the pet ink and read as holes).
pal({
  k: "#1f2223",   // pet ink
  b: "#727072",   // band and pads
  c: "#3a4660",   // cups
})

// 52 x 31 cells of fill. Fill col c is x = 29 + 3c, fill row r is y = 1 + 3r (on the
// cat2 canvas). The head spans x38..176, the ear tips are at y28 (row 9).
//
//   The arch: a ring, three cells thick, between two rounded rectangles. Its legs
//   run straight down cols 0..2 and 49..51 (x29..38 and x176..185), one border's
//   width outside the head, so their border (to x47 and from x167) ends exactly
//   where the ears' fill begins: the ears show whole inside the arch. (A first arch
//   put the legs on the head's edge and their border ate most of each ear.) The top
//   bar is rows 0..2, so the band's lower border (row 5) leaves nine units of sky
//   above the ear tips (row 9). An ear tip only reads as an ear if nothing cuts it.
//   The cups: 10 wide, rows 21..30 (y64..94), clear of the eyes (the right eye is
//   x146..158 from y106 and the border ends at y103).
const W = 52
const OUT_R = 9, IN_R = 6          // corner cuts of the outer and inner rectangles
const inOuter = (c, r) => c + r >= OUT_R && (W - 1 - c) + r >= OUT_R
const inInner = (c, r) => c >= 3 && c <= W - 4 && r >= 3 &&
  (c - 3) + (r - 3) >= IN_R && (W - 4 - c) + (r - 3) >= IN_R
const band = []
for (let r = 0; r < 21; r++)
  for (let c = 0; c < W; c++)
    if (inOuter(c, r) && !inInner(c, r)) band.push(rect(c, r, 1, 1, "b"))

sprite("_phones_fill", { w: W, h: 31 },
  ...band,
  rect(0, 21, 10, 10, "c"),    // left cup
  rect(42, 21, 10, 10, "c"),   // right cup
  rect(3, 23, 4, 6, "b"),      // left pad
  rect(45, 23, 4, 6, "b"))     // right pad

sprite("_phones_1", { base: "_phones_fill", outline8: "k" })
sprite("_phones_2", { base: "_phones_1", outline8: "k" })
sprite("headphones", { base: "_phones_2", outline8: "k" })
