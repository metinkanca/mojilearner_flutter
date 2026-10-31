// Floor 4 of the boss climb map, Lanternmaw's: the sea floor, drawn with pxl in
// the games' house style (flat colours, one-cell ink outline, nothing shaded,
// at most two details a piece).
//
// Lanternmaw is a teal anglerfish whose lure is a lantern, and its water is
// sky-blue with jade and mint coral, starfish, cream stone and lamp posts. The floor
// opens at the bottom into the floor below (the same sea-blue, the path
// starting under that floor's gateway) and at the top through a gateway like
// that one, onto the next zone's ground: Sableth's cream sand, whose gold dunes
// stand over the wall.
//
// 130 x 281 cells (a home scene's 864 x 1872 shape). Build:
//   node <skill>/bin/pxl.js build art_src/pxl/climb4.px.js
//   python art_src/pxl/export_climb.py 4
pal({
  k: "#14120e",   // ink
  b: "#a8dcef",   // the sea: the ground
  w: "#f2e3c6",   // cream: stone, shells, the sand beyond the gateway
  n: "#8fe3d0",   // mint: fan coral, the gateway
  j: "#5db89a",   // jade: branching coral, kelp, the slabs
  y: "#f9df62",   // lantern glass
  t: "#3c7a85",   // deep teal: the lamp posts
  g: "#f0a93c",   // Sableth's gold, beyond the gateway
})

// ------------------------------------------------------------------ the stops
// A round cream stone with a ring carved in it, and the small slabs between.
sprite("pad", { w: 21, h: 21, outline: "k" },
  circ(10, 10, 10, "w"),
  ring(10, 10, 7, "k"))

sprite("slab", { w: 7, h: 7, outline: "k" },
  rect(0, 0, 7, 7, "j"), px(0, 0, "_"), px(6, 0, "_"), px(0, 6, "_"), px(6, 6, "_"))

sprite("start", { w: 15, h: 15, outline: "k" },
  rect(0, 0, 15, 15, "w"), px(0, 0, "_"), px(14, 0, "_"), px(0, 14, "_"), px(14, 14, "_"))

// ------------------------------------------------------------------ the sea floor
sprite("coral_a", { outline: "k" }, `
  .j.....j...
  .jj...jj.j.
  ..j...j.jj.
  ..jj.jjjj..
  ...jjjjj...
  ....jjj....
  ....jjj....
  ...jjjjj...`)

sprite("coral_b", { outline: "k" }, `
  ..n.n.n.n..
  .nnnnnnnnn.
  nnnnnnnnnnn
  nnnnnnnnnnn
  .nnnnnnnnn.
  ...nnnnn...
  ....nnn....`)

sprite("kelp", { outline: "k" }, `
  .jjj...
  .jjj...
  ..jjj..
  ..jjj..
  .jjj...
  .jjj...
  ..jjj..
  ..jjj..
  .jjj...
  .jjj...
  ..jjj..
  ..jjj..`)

sprite("starfish", { outline: "k" }, `
  ...n...
  ...n...
  nnnnnnn
  .nnnnn.
  ..nnn..
  .nn.nn.
  .n...n.`)

sprite("rock", { w: 14, h: 8, outline: "k" },
  poly([0, 7, 1, 3, 4, 0, 9, 0, 12, 3, 13, 7], "w"))

// A lamp post: a teal cap and post, a yellow pane.
sprite("lamp", { outline: "k" }, `
  ..ttt..
  .ttttt.
  .tyyyt.
  .tyyyt.
  .tyyyt.
  ..ttt..
  ...t...
  ...t...
  ...t...
  ...t...
  ..ttt..`)

sprite("pebble", { w: 5, h: 3, outline: "k" },
  rect(0, 0, 5, 3, "w"), px(0, 0, "_"), px(4, 0, "_"))

// Bubbles: rings of ink, three sizes.
sprite("bubble_s", { w: 5, h: 5 }, ring(2, 2, 2, "k"))
sprite("bubble_m", { w: 7, h: 7 }, ring(3, 3, 3, "k"))
sprite("bubble_l", { w: 9, h: 9 }, ring(4, 4, 4, "k"))

// ------------------------------------------------------------------ the gateway
// The wall across the top and its gateway, one piece with the left half drawn
// and mirrored: courses of cream stone with their joints, and mint stones round
// the opening, straight legs up to a round head. The opening shows the next
// zone's sand, and a line of ink across its foot is the doorstep.
sprite("gate", { w: 130, h: 32, mx: true, outline: "k" },
  rect(0, 5, 65, 27, "w"),
  hline(0, 14, 65, "k"), hline(0, 23, 65, "k"),
  vline(18, 5, 9, "k"), vline(42, 5, 9, "k"),
  vline(6, 15, 8, "k"), vline(30, 15, 8, "k"),
  vline(18, 24, 8, "k"), vline(42, 24, 8, "k"),
  circ(64, 18, 16, "n"), rect(48, 18, 17, 14, "n"),
  clip([0, 0, 65, 18], ring(64, 18, 16, "k")),
  vline(48, 18, 14, "k"), hline(49, 25, 5, "k"),
  circ(64, 18, 11, "_"), rect(54, 18, 11, 14, "_"),
  hline(54, 31, 11, "k"))

// What stands over the wall in the next zone: Sableth's gold dunes.
sprite("dune", { w: 25, h: 7, outline: "k" },
  poly([0, 6, 5, 3, 11, 0, 17, 2, 24, 6], "g"))

// ------------------------------------------------------------------ the floor
// Where the five stops' centres are, bottom to top; the pads below are stamped
// on them, and the slabs between are laid along the lines joining them, a pad's
// edge and a slab's width from each end.
const stops = [[50.5, 236.5], [84.5, 196.5], [46.5, 156.5], [84.5, 116.5], [65.5, 80.5]]
const slabs = []
for (let i = 0; i + 1 < stops.length; i++) {
  const [ax, ay] = stops[i], [bx, by] = stops[i + 1]
  const len = Math.hypot(bx - ax, by - ay), ux = (bx - ax) / len, uy = (by - ay) / len
  const along = len > 46 ? [18.5, len - 18.5] : [len / 2]
  for (const d of along) slabs.push(stamp("slab", Math.round(ax + ux * d - 4.5), Math.round(ay + uy * d - 4.5)))
}

scene("floor4", { w: 130, h: 281, bg: "b" },
  // The desert beyond the wall, Sableth's sand, and its dunes.
  rect(0, 0, 130, 46, "w"),
  stamp("dune", 4, 10), stamp("dune", 30, 14), stamp("dune", 76, 14), stamp("dune", 100, 10),
  stamp("gate", -1, 13),
  // Coral either side of the gateway, on the sea side.
  stamp("coral_b", 20, 46), stamp("coral_a", 34, 44),
  stamp("coral_a", 83, 44, { flip: "x" }), stamp("coral_b", 97, 46),

  // The rest of the sea floor.
  stamp("kelp", 6, 64), stamp("rock", 104, 66), stamp("bubble_m", 100, 90),
  stamp("coral_b", 6, 116), stamp("bubble_s", 28, 112),
  stamp("coral_a", 108, 140), stamp("bubble_l", 104, 160),
  stamp("starfish", 8, 172), stamp("lamp", 8, 192),
  stamp("kelp", 118, 172), stamp("coral_b", 6, 220),
  stamp("rock", 104, 230), stamp("bubble_m", 112, 214),
  stamp("coral_a", 8, 246), stamp("kelp", 112, 246), stamp("bubble_s", 24, 228),
  stamp("pebble", 26, 100), stamp("pebble", 96, 126), stamp("pebble", 100, 268),
  stamp("pebble", 22, 268),

  // The way up: the start, under the gateway of the floor below, the slabs, and
  // the five stops.
  stamp("start", 57, 262),
  stamp("slab", 57, 251),
  ...slabs,
  stamp("pad", 39, 225), stamp("pad", 73, 185),
  stamp("pad", 35, 145), stamp("pad", 73, 105),
  stamp("pad", 54, 69))
