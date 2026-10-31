// Top hat for the cat, drawn with pxl. One pxl pixel = one 3-unit cell of the
// pet canvas: the grid the finished reworked pets are drawn on (cat, dog, bird,
// rabbit; docs/svg-style-reference.md), and the outline on all four measures 9
// units, i.e. THREE cells. pxl's `outline` is one cell, so it is applied three
// times through a `base` chain.
//
// House style: flat fills only. No sheen, shade, tint, dither or glow. Four
// colours: the pet ink for the border, felt, band, buckle.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/tophat.px.js
// Export: python art_src/gen_cat_hats.py [--ship] tophat
pal({
  k: "#1f2223",   // pet ink
  h: "#454a63",   // felt: slate-indigo, far enough off the ink to read as a colour
  r: "#e3664f",   // hat band
  g: "#f0c24c",   // buckle
})

// 52 x 37 cells of fill (the first cut was 45 x 32; ~15% bigger by cell count,
// the border stays three cells). An even width centres on a grid line, which is
// where the skull's centre falls.
sprite("_tophat_fill", { w: 52, h: 37 },
  // crown: one row cut in at the top corners, straight sides
  rect(9, 0, 34, 1, "h"),
  rect(8, 1, 36, 24, "h"),
  // band, and the buckle: NOT on the hat's centre (col 26) but on the cat's face
  // centre, 5 cells (15 units) to the right, as a 3/4-view hat would wear it
  rect(8, 25, 36, 6, "r"),
  rect(26, 25, 10, 6, "g"),
  // brim: an ellipse, six rows
  rect(2, 31, 48, 1, "h"),
  rect(0, 32, 52, 4, "h"),
  rect(2, 36, 48, 1, "h"))

// The border: three cells, one ring at a time.
sprite("_tophat_1", { base: "_tophat_fill", outline8: "k" })
sprite("_tophat_2", { base: "_tophat_1", outline8: "k" })
sprite("tophat", { base: "_tophat_2", outline8: "k" })
