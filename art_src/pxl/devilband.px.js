// Devil-horn headband for the cat, drawn with pxl: one pixel = one 3-unit cell of
// cat2's grid, border three cells (9 units) like the finished pets, flat colours,
// no shading. See tophat.px.js for why the border is a chain of three outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/devilband.px.js
// Export: python art_src/gen_cat_hats.py [--ship] devilband
//
// The original's pieces and colours: a purple band across the head and two orange
// horns. A headband sits ON the head, so the band stays below the ear tips and the
// horns rise from it just inside the ears (the ears keep their tips and outer
// edges in view, as under the flower crown).
//
// The band is a lighter purple than the original's #663b72, which sat too close to
// the pet ink and read as a hole. Border: the 4-neighbour `outline`, so the horn
// slopes stay sharp.
pal({
  k: "#1f2223",   // pet ink
  p: "#7f4f94",   // band
  o: "#f07d1e",   // horns
})

// 40 x 18 cells of fill, as wide as the head (the border brings it to the head's
// own span, x38..176). Fill col c is x = 47 + 3c, fill row r is y = 13 + 3r.
//   The band: rows 15..17 (y58..67), across the head's top, under the ear tips (y28).
//   Each horn is 9 wide at the foot (cols 9..17 and, mirrored, 22..30) and 16 rows
//   tall; the original's horns were big, and under a three-cell border anything
//   thinner is all outline. The outer edge leans out toward the tip like the
//   original's; the inner edge curves in. The horn's outer border starts at col 6,
//   the ears' inner edge, so each ear keeps its tip and outer side.
const LEFT  = [4, 4, 3, 3, 3, 2, 2, 2, 1, 1, 1, 0, 0, 0, 0, 0]   // first filled col of each row
const RIGHT = [6, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 9, 9, 9, 9]   // one past the last
const horns = []
LEFT.forEach((l, r) => {
  horns.push(rect(9 + l, r, RIGHT[r] - l, 1, "o"))
  horns.push(rect(39 - (9 + RIGHT[r] - 1), r, RIGHT[r] - l, 1, "o"))
})

sprite("_devil_fill", { w: 40, h: 18 },
  rect(0, 15, 40, 3, "p"),
  ...horns)

sprite("_devil_1", { base: "_devil_fill", outline: "k" })
sprite("_devil_2", { base: "_devil_1", outline: "k" })
sprite("devilband", { base: "_devil_2", outline: "k" })
