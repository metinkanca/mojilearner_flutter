// Mortarboard for the cat, drawn with pxl: one pixel = one 3-unit cell of cat2's
// grid, border three cells (9 units) like the finished pets, flat colours, no
// shading. See tophat.px.js for why the border is a chain of three outlines.
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/mortarboard.px.js
// Export: python art_src/gen_cat_hats.py [--ship] mortarboard
//
// The original's shape: a flat board with a gold button, over a skullcap band.
// Its board was #242e38 against the pet ink #1f2223, which reads as one black
// slab, so the board is a real blue here and the band a lighter one.
pal({
  k: "#1f2223",   // pet ink
  d: "#33466e",   // board: far enough off the ink to read as a colour
  s: "#6b84ad",   // skullcap band
  g: "#f8b230",   // button (the original's gold)
})

// 48 x 16 cells of fill. The board is 48 wide (cols 0..47, axis between 23 and 24),
// five rows thick, wider than the head so it overhangs. The band under it is 40
// wide, exactly the head's own span with its border (x38..176), so it covers both
// ears. A tassel was tried on the old one and cannot work: accessories draw on top
// of the pet, so nothing can hang down behind (see pet-accessories notes).
sprite("_mortar_fill", { w: 48, h: 16 },
  rect(21, 0, 6, 3, "g"),     // the button
  rect(0, 3, 48, 5, "d"),     // the board
  rect(4, 8, 40, 8, "s"))     // the band

sprite("_mortar_1", { base: "_mortar_fill", outline8: "k" })
sprite("_mortar_2", { base: "_mortar_1", outline8: "k" })
sprite("mortarboard", { base: "_mortar_2", outline8: "k" })
