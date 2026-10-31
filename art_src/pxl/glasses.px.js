// Glasses for the cat: one pixel = one 3-unit cell of cat2's grid, flat colours, no
// shading. Rebuilt for the reworked cat (owner, 2026-10-28: rework the face pieces
// like the hats and neck pieces).
//
// Build:  node .claude/skills/pxl-pixel-art/bin/pxl.js build art_src/pxl/glasses.px.js
// Export: python art_src/gen_cat_hats.py [--ship] glasses
//
// Face geometry on cat2: the eyes are 4 cells wide and 7 tall, x83..95 and x146..158,
// y106..127; their midpoint, the face centre, is x120.5. The old glasses were drawn
// for the old face and sat off the eyes (the eyes showed at the lens edges). Each
// lens here is a plain rectangle whose opening is the eye plus one cell of margin all
// round (6 x 9 cells), in a two-cell (6 unit) ink frame; a bridge joins them and a
// short arm leaves each lens. The frame IS the ink, so there is no separate border.
// Fill col c is x = 62 + 3c, fill row r is y = 97 + 3r; the box is x62..179, y97..136.
pal({
  k: "#1f2223",   // pet ink: the frame
})

// A lens frame, 10 wide and 13 tall, with its opening left clear.
const lens = (c0) => [
  rect(c0, 0, 10, 2, "k"),
  rect(c0, 11, 10, 2, "k"),
  rect(c0, 2, 2, 9, "k"),
  rect(c0 + 8, 2, 2, 9, "k"),
]

sprite("glasses", { w: 39, h: 13 },
  ...lens(4),               // left lens: x74..104, opening x80..98 around the eye at x83..95
  ...lens(25),              // right lens: x137..167, opening x143..161 around the eye at x146..158
  rect(14, 5, 11, 2, "k"),  // the bridge
  rect(0, 5, 4, 2, "k"),    // the arms
  rect(35, 5, 4, 2, "k"))
