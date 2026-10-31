// Party hat for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's
// grid, border three cells (9 units) like the finished pets, flat colours, no
// shading. See tophat.px.js for why the border is a chain of three outlines.
//
// Border: the 4-neighbour `outline`, like the crown. The square-corner `outline8`
// the other hats use adds ~40% to the border along a slope, and a cone is all slope.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/partyhat.px.js
// Export: python art_src/gen_cat_hats.py [--ship] partyhat
//
// The original's two teals, in diagonal stripes (the hat's one detail), and a
// coral pom on the tip in place of its navy dot: navy against the pet ink reads
// as part of the border, so a pom has to be a colour.
pal({
  k: "#1f2223",   // pet ink
  a: "#4e95a3",   // teal
  b: "#94d1d5",   // light teal
  r: "#e3664f",   // pom
})

// The cone is 22 rows tall and 18 wide at the foot, widening two cells every
// 2.75 rows, so the sides are an even stair. Even widths put the axis on a grid
// line (x107, the skull centre). It is as wide as the notch between the ears
// allows: the notch is ~63 units, the foot is 54 plus a 9-unit border each side
// that tucks over the ear outlines.
//
// Stripes run along the diagonals (col + row), four cells wide: under a three-cell
// border anything narrower stops reading as a stripe.
const ROWS = 22
const coneRows = []
for (let r = 0; r < ROWS; r++) {
  const w = 2 * (1 + Math.floor(r * 8 / (ROWS - 1) + 0.5))
  const left = 9 - w / 2
  for (let c = left; c < left + w; c++) {
    coneRows.push(rect(c, 5 + r, 1, 1, (Math.floor((c + r) / 4) % 2 === 0) ? "a" : "b"))
  }
}

sprite("_party_fill", { w: 18, h: 27 },
  // the pom, on the axis, with its four corners cut so it reads as a ball
  rect(7, 0, 4, 1, "r"),
  rect(6, 1, 6, 3, "r"),
  rect(7, 4, 4, 1, "r"),
  ...coneRows)

sprite("_party_1", { base: "_party_fill", outline: "k" })
sprite("_party_2", { base: "_party_1", outline: "k" })
sprite("partyhat", { base: "_party_2", outline: "k" })
