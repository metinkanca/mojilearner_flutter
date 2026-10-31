// Floor 3 of the boss climb map, Hoothex's: a witch's forest, drawn with pxl in
// the games' house style (flat colours, one-cell ink outline, nothing shaded,
// at most two details a piece).
//
// Hoothex is a deep-purple owl in a witch's hat, orange at the beak and the
// feet, and her grove is lilac ground with orange toadstools, purple lanterns,
// bare twisty trees and a picket fence. The floor opens at the bottom into the
// floor below (the same lilac ground, the path starting under that floor's
// gateway) and at the top through a gateway like those, onto the next zone's
// ground: Lanternmaw's sky-blue sea, whose seaweed stands over the wall.
//
// 130 x 281 cells (a home scene's 864 x 1872 shape). Build:
//   node <skill>/bin/pxl.js build art_src/pxl/climb3.px.js
//   python art_src/pxl/export_climb.py 3
pal({
  k: "#14120e",   // ink
  p: "#b99cd8",   // the grove's ground
  d: "#58348d",   // Hoothex's purple: the fence, the trees, the lanterns
  o: "#fb8630",   // orange: toadstool caps, the gateway
  w: "#f2e3c6",   // cream: stems, the stops
  y: "#f9df62",   // lantern glass
  b: "#a8dcef",   // Lanternmaw's sea, beyond the gateway
  j: "#5db89a",   // its seaweed
})

// ------------------------------------------------------------------ the stops
// A round cream stone with a ring carved in it, and the small slabs between.
sprite("pad", { w: 21, h: 21, outline: "k" },
  circ(10, 10, 10, "w"),
  ring(10, 10, 7, "k"))

sprite("slab", { w: 7, h: 7, outline: "k" },
  rect(0, 0, 7, 7, "d"), px(0, 0, "_"), px(6, 0, "_"), px(0, 6, "_"), px(6, 6, "_"))

sprite("start", { w: 15, h: 15, outline: "k" },
  rect(0, 0, 15, 15, "w"), px(0, 0, "_"), px(14, 0, "_"), px(0, 14, "_"), px(14, 14, "_"))

// ------------------------------------------------------------------ the grove
// Toadstools, big and small: an orange cap on a cream stem.
sprite("cap_big", { w: 15, h: 7, outline: "k" },
  poly([0, 6, 1, 3, 4, 0, 10, 0, 13, 3, 14, 6], "o"))
sprite("stem_big", { w: 5, h: 7, outline: "k" }, rect(0, 0, 5, 7, "w"))
sprite("cap_small", { w: 9, h: 5, outline: "k" },
  poly([0, 4, 1, 2, 3, 0, 5, 0, 7, 2, 8, 4], "o"))
sprite("stem_small", { w: 3, h: 6, outline: "k" }, rect(0, 0, 3, 6, "w"))

// A lantern on a post: purple cap and post, a yellow pane.
sprite("lantern", { outline: "k" }, `
  ..ddd..
  .ddddd.
  .dyyyd.
  .dyyyd.
  .dyyyd.
  ..ddd..
  ...d...
  ...d...
  ...d...
  ...d...
  ..ddd..`)

// A bare tree, twisting.
sprite("tree", { outline: "k" }, `
  .d.........d.
  .dd.......dd.
  ..dd..d..dd..
  ...dd.d.dd...
  ....ddddd....
  ..d..ddd..d..
  ..dd.ddd.dd..
  ...ddddddd...
  ....ddddd....
  .....ddd.....
  .....ddd.....
  .....ddd.....
  ....ddddd....
  ...ddddddd...`)

sprite("pebble", { w: 5, h: 3, outline: "k" },
  rect(0, 0, 5, 3, "w"), px(0, 0, "_"), px(4, 0, "_"))

// ------------------------------------------------------------------ the gateway
// The fence across the top and its gateway, one piece with the left half drawn
// and mirrored: boards with their joints and pointed tops, and orange stones
// round the opening, straight legs up to a round head. The opening shows the
// sea's colour, and a line of ink across its foot is the doorstep.
const boards = []
for (let k = 0; k < 5; k++) {
  boards.push(vline(9 * k + 8, 5, 27, "k"), rect(9 * k + 3, 3, 2, 2, "d"))
}
sprite("gate", { w: 130, h: 32, mx: true, outline: "k" },
  rect(0, 5, 65, 27, "d"),
  ...boards,
  hline(0, 13, 65, "k"), hline(0, 25, 65, "k"),
  circ(64, 18, 16, "o"), rect(48, 18, 17, 14, "o"),
  clip([0, 0, 65, 18], ring(64, 18, 16, "k")),
  vline(48, 18, 14, "k"), hline(49, 25, 5, "k"),
  circ(64, 18, 11, "_"), rect(54, 18, 11, 14, "_"),
  hline(54, 31, 11, "k"))

// Hoothex's hat on the gateway: a straight cone and a wide brim.
sprite("hat", { outline: "k" }, `
  .........d.........
  ........ddd........
  ........ddd........
  .......ddddd.......
  .......ddddd.......
  .......ddddd.......
  ......ddddddd......
  ......ddddddd......
  .....ddddddddd.....
  .....ddddddddd.....
  ....ddddddddddd....
  ddddddddddddddddddd
  .ddddddddddddddddd.`)

// What stands over the wall in the next zone: Lanternmaw's seaweed.
sprite("weed", { outline: "k" }, `
  .jjj...
  .jjj...
  ..jjj..
  ..jjj..
  .jjj...
  .jjj...
  ..jjj..
  ..jjj..
  .jjj...
  .jjj...`)

// ------------------------------------------------------------------ the floor
// Where the five stops' centres are, bottom to top; the pads below are stamped
// on them, and the slabs between are laid along the lines joining them, a pad's
// edge and a slab's width from each end.
const stops = [[82.5, 236.5], [48.5, 196.5], [81.5, 156.5], [48.5, 116.5], [65.5, 80.5]]
const slabs = []
for (let i = 0; i + 1 < stops.length; i++) {
  const [ax, ay] = stops[i], [bx, by] = stops[i + 1]
  const len = Math.hypot(bx - ax, by - ay), ux = (bx - ax) / len, uy = (by - ay) / len
  const along = len > 46 ? [18.5, len - 18.5] : [len / 2]
  for (const d of along) slabs.push(stamp("slab", Math.round(ax + ux * d - 4.5), Math.round(ay + uy * d - 4.5)))
}
const toadstool = (x, y) => [stamp("stem_big", x + 5, y + 6), stamp("cap_big", x, y)]
const toadlet = (x, y) => [stamp("stem_small", x + 3, y + 3), stamp("cap_small", x, y)]

scene("floor3", { w: 130, h: 281, bg: "p" },
  // The sea beyond the fence, Lanternmaw's, and its seaweed.
  rect(0, 0, 130, 46, "b"),
  stamp("weed", 12, 8), stamp("weed", 28, 12), stamp("weed", 100, 8), stamp("weed", 116, 12),
  stamp("gate", -1, 13),
  stamp("hat", 55, 1),
  // A lantern either side of the gateway, on the grove side.
  stamp("lantern", 34, 40), stamp("lantern", 89, 40),

  // The rest of the grove.
  ...toadstool(6, 66), ...toadlet(106, 70),
  stamp("tree", 6, 108), stamp("tree", 112, 118, { flip: "x" }),
  ...toadstool(106, 134), ...toadlet(8, 168),
  stamp("lantern", 6, 188), stamp("tree", 110, 190, { flip: "x" }),
  ...toadstool(8, 214), stamp("tree", 6, 252),
  ...toadlet(110, 222), stamp("lantern", 112, 246),
  stamp("pebble", 24, 96), stamp("pebble", 98, 176), stamp("pebble", 24, 150),
  stamp("pebble", 100, 262), stamp("pebble", 22, 240),

  // The way up: the start, under the gateway of the floor below, the slabs, and
  // the five stops.
  stamp("start", 57, 262),
  stamp("slab", 70, 251),
  ...slabs,
  stamp("pad", 71, 225), stamp("pad", 37, 185),
  stamp("pad", 70, 145), stamp("pad", 37, 105),
  stamp("pad", 54, 69))
