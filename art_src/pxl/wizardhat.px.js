// Wizard (witch) hat for the cat, drawn with pxl: one pixel = one 3-unit cell of
// cat2's grid, border three cells (9 units) like the finished pets, flat colours,
// no shading.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/wizardhat.px.js
// Export: python art_src/gen_cat_hats.py [--ship] wizardhat
//
// Shape from the original: a tall stepped cone on a wide flat brim, the cone
// threaded through the notch between the ears, the ear tips showing either side.
// The original's #1a3340 sat on the pet ink and read as a hole, so it is a real
// indigo here. The gold hat band is its one detail.
//
// Border: the 4-neighbour `outline` (like the crown, the party hat and the
// beanie): a cone is all slope and a brim all curve.
pal({
  k: "#1f2223",   // pet ink
  h: "#5a4aa0",   // indigo felt
  g: "#f8b230",   // hat band
})

// 56 x 40 cells of fill, axis between cols 27 and 28 (x107, the skull centre).
//
//   The cone: 36 rows (0..35), widening 2 cells every ~5 rows from a 2-wide tip to
//   14 wide at the brim, as tall as the original (its tip reached y-55; a 30-row cone
//   stopped at y-38 and read as stubby). 14 cells is the most the notch between the ears holds:
//   it is ~63 units across at y37 and a 42-unit cone brings a 9-unit border each
//   side. A fatter cone would cover the ears' inner edges.
//   The band: rows 30..33, the cone's own width.
//   The brim: rows 34..39, a lens 56 wide and six rows thick (five left only two
//   rows of colour showing inside the border; seven pushed its top edge up and
//   shrank the ear tips to nubs, so its top stays at y55 and its bottom border is
//   y82, three units below the other hats'). Its top border (y46) leaves the ear tips
//   (y28) 18 units showing above it on both sides, where the old hat had them too.
const cone = []
for (let r = 0; r < 36; r++) {
  const w = 2 * (1 + Math.floor(r * 7 / 36))
  cone.push(rect(28 - w / 2, r, w, 1, (r >= 30 && r <= 33) ? "g" : "h"))
}

sprite("_wizard_fill", { w: 56, h: 40 },
  ...cone,
  // brim, a lens
  rect(12, 34, 32, 1, "h"),
  rect(6, 35, 44, 1, "h"),
  rect(0, 36, 56, 2, "h"),
  rect(4, 38, 48, 1, "h"),
  rect(10, 39, 36, 1, "h"))

sprite("_wizard_1", { base: "_wizard_fill", outline: "k" })
sprite("_wizard_2", { base: "_wizard_1", outline: "k" })
sprite("wizardhat", { base: "_wizard_2", outline: "k" })
