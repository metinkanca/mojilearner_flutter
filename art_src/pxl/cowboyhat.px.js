// Cowboy hat for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's
// grid, border three cells (9 units) like the finished pets, flat colours, no
// shading. See tophat.px.js for why the border is a chain of three outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/cowboyhat.px.js
// Export: python art_src/gen_cat_hats.py cowboyhat
//
// Same two browns as the original: leather and a darker band.
pal({
  k: "#1f2223",   // pet ink
  h: "#7b4b36",   // leather
  b: "#492b21",   // band
})

// 56 x 26 cells of fill. The crown is 28 wide (cols 14..41, centre line 28) with
// a pinched dent in the top. The brim is ONE continuous band: flat under the
// crown (rows 21..25), then sweeping up to each end in clean three-column steps
// that rise two rows each, six rows thick. (The first cut stuck two blobs on a
// flat brim and read as ears; the second climbed a row per column and read as a
// thin V. Chunky steps are what pixel art needs for a curve.) The flat part runs
// a step past the crown on each side, so the sweep starts later.
//
// The climb also does a job: the cat's ear columns (x44..65 and x140..161, tips
// at y28) sit just outside the crown, and the band is already high enough there
// that its border, with the crown's, covers the ear tips, so no ear shows between
// brim and crown.
const STEPS = [[8, 3, 19], [5, 3, 17], [2, 3, 15], [0, 2, 13]]   // [col, width, top row]
const wings = STEPS.flatMap(([c, w, top]) => [
  rect(c, top, w, 6, "h"),
  rect(56 - c - w, top, w, 6, "h"),
])

sprite("_cowboy_fill", { w: 56, h: 26 },
  // crown: two humps with the dent between them, then straight sides
  rect(14, 0, 10, 4, "h"),
  rect(32, 0, 10, 4, "h"),
  rect(14, 4, 28, 17, "h"),
  // band, with leather above and below it so it never touches the border
  rect(14, 15, 28, 4, "b"),
  // brim: flat under the crown and out to where the rise starts
  rect(11, 21, 34, 5, "h"),
  ...wings)

sprite("_cowboy_1", { base: "_cowboy_fill", outline8: "k" })
sprite("_cowboy_2", { base: "_cowboy_1", outline8: "k" })
sprite("cowboyhat", { base: "_cowboy_2", outline8: "k" })
