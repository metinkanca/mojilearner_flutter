// Floor 1 of the boss climb map, Mossback's: a mossy ruins garden, drawn with
// pxl in the games' house style (flat colours, one-cell ink outline, nothing
// shaded, at most two details a piece).
//
// Mossback is an olive tortoise whose shell is grey stone plates with dark
// seams and a crest of moss, so the floor is moss, boulders and old masonry.
// Its top is not a wall to stop at: the path climbs through a mossy stone
// gateway, and beyond it the ground is already Amethyst's cave violet, which
// carries on through the band into the next floor.
//
// Moss is always a tuft growing on top of a thing, never a patch painted on it.
//
// 130 x 281 cells (a home scene's 864 x 1872 shape). Build:
//   node <skill>/bin/pxl.js build art_src/pxl/climb1.px.js
//   python art_src/pxl/export_climb.py
pal({
  k: "#14120e",   // ink
  l: "#8cc56a",   // leaf: the ground
  j: "#5db89a",   // jade: moss, bushes
  s: "#cdc3d9",   // stone
  w: "#f2e3c6",   // cream: the gateway's stones, the stops
  c: "#c58c56",   // wood
  v: "#70549b",   // the cave's ground, Amethyst's
  m: "#9a7cc8",   // amethyst
})

// ------------------------------------------------------------------ the stops
// A round stone with a ring carved in it, and the small slabs between them.
sprite("pad", { w: 21, h: 21, outline: "k" },
  circ(10, 10, 10, "w"),
  ring(10, 10, 7, "k"))

sprite("slab", { w: 7, h: 7, outline: "k" },
  rect(0, 0, 7, 7, "s"), px(0, 0, "_"), px(6, 0, "_"), px(0, 6, "_"), px(6, 6, "_"))

sprite("start", { w: 15, h: 15, outline: "k" },
  rect(0, 0, 15, 15, "w"), px(0, 0, "_"), px(14, 0, "_"), px(0, 14, "_"), px(14, 14, "_"))

// ------------------------------------------------------------------ the garden
sprite("tuft", { outline: "k" }, `
  .j...j.
  .jj.jj.
  jjjjjjj`)

sprite("boulder", { w: 20, h: 13, outline: "k" },
  poly([0, 12, 2, 5, 6, 1, 13, 0, 17, 3, 19, 12], "s"))

sprite("log", { w: 30, h: 9, outline: "k" },
  rect(0, 0, 30, 9, "c"), hline(3, 3, 14, "k"), hline(9, 6, 14, "k"),
  rect(26, 0, 4, 9, "w"), vline(25, 0, 9, "k"))

sprite("bush", { outline: "k" }, `
  ...jj...jj...
  .jjjjjjjjjjj.
  jjjjjjjjjjjjj
  jjjjjjjjjjjjj
  .jjjjjjjjjjj.
  ..jjjjjjjjj..`)

sprite("flower", { outline: "k" }, `
  .w.
  wkw
  .w.`)

sprite("pebble", { w: 5, h: 3, outline: "k" },
  rect(0, 0, 5, 3, "s"), px(0, 0, "_"), px(4, 0, "_"))

// ------------------------------------------------------------------ the gateway
// The wall across the top and its gateway, one piece: the left half is drawn
// and mirrored, so the two sides are the same stone for stone. Courses of grey
// stone with their joints, and cream stones round the opening: straight legs
// up to a round head, no seam down the middle. The opening shows the cave's
// ground, and a line of ink across its foot is the doorstep.
sprite("gate", { w: 130, h: 32, mx: true, outline: "k" },
  rect(0, 5, 65, 27, "s"),
  hline(0, 14, 65, "k"), hline(0, 23, 65, "k"),
  vline(18, 5, 9, "k"), vline(42, 5, 9, "k"),
  vline(6, 15, 8, "k"), vline(30, 15, 8, "k"),
  vline(18, 24, 8, "k"), vline(42, 24, 8, "k"),
  // the cream stones round the opening: legs, and a head of the same width
  circ(64, 18, 16, "w"), rect(48, 18, 17, 14, "w"),
  clip([0, 0, 65, 18], ring(64, 18, 16, "k")),
  vline(48, 18, 14, "k"), hline(49, 25, 5, "k"),
  circ(64, 18, 11, "_"), rect(54, 18, 11, 14, "_"),
  hline(54, 31, 11, "k"))

// What grows over the wall from the cave side: pointed crystals, amethyst on
// one face and stone on the other, split by an ink ridge.
sprite("crystal_a", { w: 9, h: 18, outline: "k" },
  poly([4, 0, 8, 5, 8, 17, 0, 17, 0, 5], "m"),
  clip([0, 0, 9, 18], poly([4, 0, 8, 5, 8, 17, 4, 17], "s")),
  vline(4, 1, 16, "k"))

sprite("crystal_b", { w: 7, h: 12, outline: "k" },
  poly([3, 0, 6, 4, 6, 11, 0, 11, 0, 4], "m"),
  clip([0, 0, 7, 12], poly([3, 0, 6, 4, 6, 11, 3, 11], "s")),
  vline(3, 1, 10, "k"))

// ------------------------------------------------------------------ the floor
// Where the five stops' centres are, bottom to top: the pads below are stamped
// on them, and the slabs between are laid along the lines joining them, a pad's
// edge and a slab's width from each end.
const stops = [[52.5, 236.5], [80.5, 196.5], [50.5, 156.5], [79.5, 116.5], [56.5, 80.5]]
const slabs = []
for (let i = 0; i + 1 < stops.length; i++) {
  const [ax, ay] = stops[i], [bx, by] = stops[i + 1]
  const len = Math.hypot(bx - ax, by - ay), ux = (bx - ax) / len, uy = (by - ay) / len
  // two where the way is long enough for both, one in the middle where not
  const along = len > 46 ? [18.5, len - 18.5] : [len / 2]
  for (const d of along) slabs.push(stamp("slab", Math.round(ax + ux * d - 4.5), Math.round(ay + uy * d - 4.5)))
}

scene("floor1", { w: 130, h: 281, bg: "l" },
  // The cave beyond the wall, Amethyst's ground.
  rect(0, 0, 130, 46, "v"),
  stamp("crystal_b", 6, 8), stamp("crystal_a", 14, 0), stamp("crystal_b", 28, 9),
  stamp("crystal_b", 92, 9), stamp("crystal_a", 104, 1), stamp("crystal_b", 117, 8),
  stamp("gate", -1, 13),
  stamp("tuft", 38, 15), stamp("tuft", 86, 15),

  // The garden.
  stamp("boulder", 104, 66), stamp("tuft", 111, 63),
  stamp("boulder", 2, 118), stamp("tuft", 9, 115),
  stamp("log", 0, 170), stamp("tuft", 9, 167),
  stamp("bush", 104, 150), stamp("bush", 8, 208),
  stamp("flower", 6, 190), stamp("flower", 14, 196), stamp("flower", 110, 218), stamp("flower", 102, 226), stamp("flower", 24, 112),
  stamp("boulder", 106, 236), stamp("tuft", 113, 233),
  stamp("pebble", 26, 138), stamp("pebble", 96, 190), stamp("pebble", 20, 258),
  stamp("tuft", 8, 262), stamp("tuft", 100, 268), stamp("tuft", 70, 54),

  // The way up: the start, the slabs, and the five stops.
  stamp("start", 43, 262),
  stamp("slab", 48, 251),
  ...slabs,
  stamp("pad", 41, 225), stamp("pad", 69, 185),
  stamp("pad", 39, 145), stamp("pad", 68, 105),
  stamp("pad", 45, 69))
