// Floor 6 of the boss climb map, Pyrewing's: a volcano, drawn with pxl in the
// games' house style (flat colours, one-cell ink outline, nothing shaded, at
// most two details a piece).
//
// Pyrewing is a red-orange dragon with cream horns, a gold belly and a flame on
// its tail, and its mountain is deep-purple ground, lilac stone, spires and
// lava. The floor opens at the bottom into the floor below (the same deep
// purple, the path starting under that floor's gateway) and, being the top of
// the climb, ends at the dragon's own lair rather than a way on: the gateway
// like the others', but horned, and burning inside.
//
// 130 x 281 cells (a home scene's 864 x 1872 shape). Build:
//   node <skill>/bin/pxl.js build art_src/pxl/climb6.px.js
//   python art_src/pxl/export_climb.py 6
pal({
  k: "#14120e",   // ink
  d: "#58348d",   // the mountain's ground
  s: "#b99cd8",   // lilac stone: the wall, the pads, the spires
  m: "#9a7cc8",   // amethyst: the slabs
  r: "#d0522f",   // the dragon's red: the gateway
  o: "#fb8630",   // lava, flames
  y: "#f9df62",   // the flames' hearts
  w: "#f2e3c6",   // cream: the horns
})

// ------------------------------------------------------------------ the stops
// A round lilac stone with a ring carved in it, and the small slabs between.
sprite("pad", { w: 21, h: 21, outline: "k" },
  circ(10, 10, 10, "s"),
  ring(10, 10, 7, "k"))

sprite("slab", { w: 7, h: 7, outline: "k" },
  rect(0, 0, 7, 7, "m"), px(0, 0, "_"), px(6, 0, "_"), px(0, 6, "_"), px(6, 6, "_"))

sprite("start", { w: 15, h: 15, outline: "k" },
  rect(0, 0, 15, 15, "s"), px(0, 0, "_"), px(14, 0, "_"), px(0, 14, "_"), px(14, 14, "_"))

// ------------------------------------------------------------------ the mountain
sprite("spire_a", { w: 13, h: 24, outline: "k" },
  poly([6, 0, 9, 6, 12, 23, 0, 23, 3, 6], "s"))
sprite("spire_b", { w: 9, h: 14, outline: "k" },
  poly([4, 0, 7, 4, 8, 13, 0, 13, 1, 4], "s"))

sprite("boulder", { w: 20, h: 13, outline: "k" },
  poly([0, 12, 2, 5, 6, 1, 13, 0, 17, 3, 19, 12], "s"))

// Lava, pooled in the ground.
sprite("lava_a", { w: 22, h: 6, outline: "k" },
  poly([0, 3, 3, 1, 9, 0, 15, 1, 21, 3, 18, 5, 8, 5, 3, 5], "o"))
sprite("lava_b", { w: 13, h: 5, outline: "k" },
  poly([0, 2, 3, 0, 9, 0, 12, 2, 9, 4, 3, 4], "o"))

// A small fire burning on the ground.
sprite("flame", { outline: "k" }, `
  ...o...
  ..ooo..
  .ooyoo.
  .ooyyo.
  ooyyyoo
  ooooooo`)

sprite("pebble", { w: 5, h: 3, outline: "k" },
  rect(0, 0, 5, 3, "s"), px(0, 0, "_"), px(4, 0, "_"))

// An ember: one yellow cell.
sprite("ember", { w: 1, h: 1, outline: "k" }, px(0, 0, "y"))

// ------------------------------------------------------------------ the lair
// The wall across the top and its gateway, one piece with the left half drawn
// and mirrored: courses of lilac stone with their joints, and red stones round
// the opening, straight legs up to a round head. The opening is dark.
sprite("gate", { w: 130, h: 32, mx: true, outline: "k" },
  rect(0, 5, 65, 27, "s"),
  hline(0, 14, 65, "k"), hline(0, 23, 65, "k"),
  vline(18, 5, 9, "k"), vline(42, 5, 9, "k"),
  vline(6, 15, 8, "k"), vline(30, 15, 8, "k"),
  vline(18, 24, 8, "k"), vline(42, 24, 8, "k"),
  circ(64, 18, 16, "r"), rect(48, 18, 17, 14, "r"),
  clip([0, 0, 65, 18], ring(64, 18, 16, "k")),
  vline(48, 18, 14, "k"), hline(49, 25, 5, "k"),
  circ(64, 18, 11, "k"), rect(54, 18, 11, 14, "k"))

// The dragon's horns on the gateway: cream, sweeping up and out from the
// crown of the arch. The left half is drawn and mirrored.
sprite("horns", { mx: true, outline: "k" }, `
  ww.............
  www............
  .www...........
  .wwww..........
  ..wwwww........
  ...wwwwww......
  ....wwwwwwww...
  .....wwwwwwwwww
  ......wwwwwwwww`)

// The fire burning in the opening.
sprite("fire", {}, `
  .....o.....
  ....ooo....
  ....ooo....
  ...ooooo...
  ..oooyooo..
  ..ooyyyoo..
  .ooyyyyyoo.
  .ooyyyyyoo.
  oooyyyyyooo
  ooooyyyoooo`)

// ------------------------------------------------------------------ the floor
// Where the five stops' centres are, bottom to top; the pads below are stamped
// on them, and the slabs between are laid along the lines joining them, a pad's
// edge and a slab's width from each end. The first line runs from the start.
const start = [65.5, 270.5]
const stops = [[80.5, 236.5], [46.5, 196.5], [84.5, 156.5], [46.5, 116.5], [65.5, 80.5]]
const slabs = []
const way = [start, ...stops]
for (let i = 0; i + 1 < way.length; i++) {
  const [ax, ay] = way[i], [bx, by] = way[i + 1]
  const len = Math.hypot(bx - ax, by - ay), ux = (bx - ax) / len, uy = (by - ay) / len
  const along = len > 46 ? [i === 0 ? 17 : 18.5, len - 18.5] : [len / 2]
  for (const d of along) slabs.push(stamp("slab", Math.round(ax + ux * d - 4.5), Math.round(ay + uy * d - 4.5)))
}

scene("floor6", { w: 130, h: 281, bg: "d" },
  // The mountain beyond the wall: spires and flames on its ground.
  stamp("spire_a", 10, 0), stamp("spire_b", 28, 8), stamp("flame", 40, 12),
  stamp("flame", 83, 12), stamp("spire_b", 93, 8), stamp("spire_a", 107, 0),
  stamp("gate", -1, 13),
  stamp("horns", 49, 6),
  stamp("fire", 60, 35),

  // The rest of the mountain.
  stamp("boulder", 6, 62), stamp("boulder", 104, 70),
  stamp("lava_a", 8, 92), stamp("lava_b", 100, 104),
  stamp("spire_a", 2, 136), stamp("flame", 112, 130),
  stamp("lava_b", 10, 176), stamp("spire_a", 112, 190),
  stamp("flame", 14, 216), stamp("lava_a", 98, 214),
  stamp("boulder", 6, 240), stamp("spire_b", 112, 252),
  stamp("lava_a", 8, 268), stamp("lava_b", 100, 270),
  stamp("pebble", 26, 128), stamp("pebble", 98, 176), stamp("pebble", 24, 150),
  stamp("pebble", 100, 232), stamp("pebble", 36, 262),
  stamp("ember", 20, 100), stamp("ember", 108, 100), stamp("ember", 30, 200),
  stamp("ember", 100, 150), stamp("ember", 38, 236), stamp("ember", 118, 232),

  // The way up: the start, under the gateway of the floor below, the slabs, and
  // the five stops.
  stamp("start", 57, 262),
  ...slabs,
  stamp("pad", 69, 225), stamp("pad", 35, 185),
  stamp("pad", 73, 145), stamp("pad", 35, 105),
  stamp("pad", 54, 69))
