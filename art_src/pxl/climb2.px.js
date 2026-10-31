// Floor 2 of the boss climb map, Amethyst's: a violet cave, drawn with pxl in
// the games' house style (flat colours, one-cell ink outline, nothing shaded,
// at most two details a piece).
//
// Amethyst is a plum-coloured bear with amethyst crystals on its head and back,
// and its cave is violet rock, lilac stone and crystals. The floor opens at
// the bottom into the floor below (the same violet ground, the path starting
// under that floor's gateway) and at the top through a gateway like that one,
// onto the next zone's ground: Hoothex's lilac forest, whose orange
// toadstools stand over the wall.
//
// 130 x 281 cells (a home scene's 864 x 1872 shape). Build:
//   node <skill>/bin/pxl.js build art_src/pxl/climb2.px.js
//   python art_src/pxl/export_climb.py 2
pal({
  k: "#14120e",   // ink
  v: "#70549b",   // the cave's ground
  m: "#9a7cc8",   // amethyst: the rock
  z: "#d9c8f0",   // lilac: the stones and crystal faces
  p: "#b99cd8",   // Hoothex's forest ground, beyond the gateway
  o: "#fb8630",   // Hoothex's toadstool caps
  w: "#f2e3c6",   // their stems
})

// ------------------------------------------------------------------ the stops
// A round lilac stone with a ring carved in it, and the small slabs between.
sprite("pad", { w: 21, h: 21, outline: "k" },
  circ(10, 10, 10, "z"),
  ring(10, 10, 7, "k"))

sprite("slab", { w: 7, h: 7, outline: "k" },
  rect(0, 0, 7, 7, "m"), px(0, 0, "_"), px(6, 0, "_"), px(0, 6, "_"), px(6, 6, "_"))

sprite("start", { w: 15, h: 15, outline: "k" },
  rect(0, 0, 15, 15, "z"), px(0, 0, "_"), px(14, 0, "_"), px(0, 14, "_"), px(14, 14, "_"))

// ------------------------------------------------------------------ the cave
// Crystals: lilac on the lit face, amethyst on the other, split by an ink ridge.
sprite("crystal_a", { w: 9, h: 18, outline: "k" },
  poly([4, 0, 8, 5, 8, 17, 0, 17, 0, 5], "z"),
  clip([0, 0, 9, 18], poly([4, 0, 8, 5, 8, 17, 4, 17], "m")),
  vline(4, 1, 16, "k"))

sprite("crystal_b", { w: 7, h: 12, outline: "k" },
  poly([3, 0, 6, 4, 6, 11, 0, 11, 0, 4], "z"),
  clip([0, 0, 7, 12], poly([3, 0, 6, 4, 6, 11, 3, 11], "m")),
  vline(3, 1, 10, "k"))

sprite("crystal_c", { w: 11, h: 24, outline: "k" },
  poly([5, 0, 10, 6, 10, 23, 0, 23, 0, 6], "z"),
  clip([0, 0, 11, 24], poly([5, 0, 10, 6, 10, 23, 5, 23], "m")),
  vline(5, 1, 22, "k"))

sprite("boulder", { w: 20, h: 13, outline: "k" },
  poly([0, 12, 2, 5, 6, 1, 13, 0, 17, 3, 19, 12], "m"))

sprite("pebble", { w: 5, h: 3, outline: "k" },
  rect(0, 0, 5, 3, "z"), px(0, 0, "_"), px(4, 0, "_"))

// ------------------------------------------------------------------ the gateway
// The wall across the top and its gateway, one piece with the left half drawn
// and mirrored: courses of amethyst rock with their joints, and lilac stones
// round the opening, straight legs up to a round head. The opening shows the
// forest's ground, and a line of ink across its foot is the doorstep.
sprite("gate", { w: 130, h: 32, mx: true, outline: "k" },
  rect(0, 5, 65, 27, "m"),
  hline(0, 14, 65, "k"), hline(0, 23, 65, "k"),
  vline(18, 5, 9, "k"), vline(42, 5, 9, "k"),
  vline(6, 15, 8, "k"), vline(30, 15, 8, "k"),
  vline(18, 24, 8, "k"), vline(42, 24, 8, "k"),
  circ(64, 18, 16, "z"), rect(48, 18, 17, 14, "z"),
  clip([0, 0, 65, 18], ring(64, 18, 16, "k")),
  vline(48, 18, 14, "k"), hline(49, 25, 5, "k"),
  circ(64, 18, 11, "_"), rect(54, 18, 11, 14, "_"),
  hline(54, 31, 11, "k"))

// What stands over the wall in the next zone: Hoothex's toadstools.
sprite("cap_big", { w: 15, h: 7, outline: "k" },
  poly([0, 6, 1, 3, 4, 0, 10, 0, 13, 3, 14, 6], "o"))
sprite("stem_big", { w: 5, h: 7, outline: "k" }, rect(0, 0, 5, 7, "w"))
sprite("cap_small", { w: 9, h: 5, outline: "k" },
  poly([0, 4, 1, 2, 3, 0, 5, 0, 7, 2, 8, 4], "o"))
sprite("stem_small", { w: 3, h: 6, outline: "k" }, rect(0, 0, 3, 6, "w"))

// ------------------------------------------------------------------ the floor
// Where the five stops' centres are, bottom to top; the pads below are stamped
// on them, and the slabs between are laid along the lines joining them, a pad's
// edge and a slab's width from each end.
const stops = [[48.5, 236.5], [82.5, 196.5], [47.5, 156.5], [82.5, 116.5], [65.5, 80.5]]
const slabs = []
for (let i = 0; i + 1 < stops.length; i++) {
  const [ax, ay] = stops[i], [bx, by] = stops[i + 1]
  const len = Math.hypot(bx - ax, by - ay), ux = (bx - ax) / len, uy = (by - ay) / len
  const along = len > 46 ? [18.5, len - 18.5] : [len / 2]
  for (const d of along) slabs.push(stamp("slab", Math.round(ax + ux * d - 4.5), Math.round(ay + uy * d - 4.5)))
}

// A cluster of crystals standing on one line: each is [kind, offset from x].
// The first is drawn first, so the ones after stand in front of it.
const heights = { a: 20, b: 14, c: 26 }
const cluster = (x, base, kinds) =>
  kinds.map(([kind, dx]) => stamp("crystal_" + kind, x + dx, base - heights[kind]))

scene("floor2", { w: 130, h: 281, bg: "v" },
  // The forest beyond the wall, Hoothex's ground, and its toadstools.
  rect(0, 0, 130, 46, "p"),
  stamp("stem_big", 16, 12), stamp("cap_big", 11, 6),
  stamp("stem_small", 36, 14), stamp("cap_small", 33, 11),
  stamp("stem_small", 92, 14), stamp("cap_small", 89, 11),
  stamp("stem_big", 108, 12), stamp("cap_big", 103, 6),
  stamp("gate", -1, 13),
  // The crystals that frame the gateway, on the cave side.
  ...cluster(28, 55, [["a", 8], ["b", 0]]),
  ...cluster(83, 55, [["a", 0], ["b", 10]]),

  // The rest of the cave.
  stamp("boulder", 6, 70), stamp("boulder", 104, 62),
  ...cluster(4, 134, [["c", 8], ["a", 0], ["b", 18]]),
  ...cluster(94, 168, [["c", 10], ["a", 0], ["b", 22]]),
  ...cluster(4, 222, [["c", 8], ["a", 0]]),
  stamp("boulder", 104, 226),
  stamp("boulder", 6, 240),
  stamp("pebble", 24, 98), stamp("pebble", 98, 170), stamp("pebble", 24, 176),
  stamp("pebble", 100, 262), stamp("pebble", 20, 262),

  // The way up: the start, under the gateway of the floor below, the slabs, and
  // the five stops.
  stamp("start", 57, 262),
  stamp("slab", 53, 251),
  ...slabs,
  stamp("pad", 37, 225), stamp("pad", 71, 185),
  stamp("pad", 36, 145), stamp("pad", 71, 105),
  stamp("pad", 54, 69))
